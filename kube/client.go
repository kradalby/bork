package kube

import (
	"bytes"
	b64 "encoding/base64"
	"errors"
	"log"
	"strings"
	"text/template"

	"github.com/gobuffalo/uuid"
	"github.com/kradalby/bork/models"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	kubernetesErrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	kubernetes "k8s.io/client-go/kubernetes"
	restclient "k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

var clusterRoleName string = "bork-namespaced-cr"

type Client struct {
	client *kubernetes.Clientset
	config *restclient.Config
}

func NewInClusterClient() (*Client, error) {
	// creates the in-cluster config
	config, err := restclient.InClusterConfig()
	if err != nil {
		panic(err.Error())
	}
	// creates the clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}

	client := &Client{
		client: clientset,
		config: config,
	}

	return client, nil
}

func NewOutOfClusterClient(kubeconf string) (*Client, error) {

	config, err := clientcmd.BuildConfigFromFlags("", kubeconf)
	if err != nil {
		panic(err.Error())
	}

	// create the clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}

	client := &Client{
		client: clientset,
		config: config,
	}

	return client, nil
}

func (c *Client) CreateNamespace(name string, ownerId uuid.UUID) (*uuid.UUID, error) {

	err := c.CreateNamespaceWithServiceAccount(name, ownerId)
	if err != nil {
		return nil, err
	}

	ns := &models.Namespace{
		Name:    name,
		OwnerID: ownerId,
	}

	// Save the namespace in the database
	// when all other options are successful
	_, err = models.DB.ValidateAndCreate(ns)
	if err != nil {
		log.Printf("[Error] %#v", err)
		return nil, err
	}

	return &ns.ID, nil
}

func (c *Client) CreateNamespaceWithServiceAccount(name string, owner uuid.UUID) error {

	// Create the namespace in the kubecluster
	err := c.createNamespace(name, owner)
	if err != nil {
		log.Printf("[Error] %#v", err)
		return err
	}

	err = c.createServiceAccount(name)
	if err != nil {
		log.Printf("[Error] %#v", err)
		return err
	}

	err = c.createRole(name)
	if err != nil {
		log.Printf("[Error] %#v", err)
		return err
	}

	err = c.createServiceAccountRoleBinding(name)
	if err != nil {
		log.Printf("[Error] %#v", err)
		return err
	}

	return nil
}

func (c *Client) createNamespace(namespace string, owner uuid.UUID) error {

	_, err := c.client.CoreV1().Namespaces().Create(&corev1.Namespace{
		ObjectMeta: metav1.ObjectMeta{
			Name:   namespace,
			Labels: createLabels(owner.String()),
		},
	})
	return err
}

func (c *Client) deleteNamespace(namespace string) error {
	err := c.client.CoreV1().Namespaces().Delete(namespace, &metav1.DeleteOptions{})
	return err
}

func (c *Client) createServiceAccount(namespace string) error {
	serviceAccountName := getServiceAccountName(namespace)

	serviceAccount := &corev1.ServiceAccount{
		ObjectMeta: metav1.ObjectMeta{
			Name:      serviceAccountName,
			Namespace: namespace,
			// Labels:    getLabels(),
		},
	}

	serviceAccount, err := c.client.CoreV1().ServiceAccounts(namespace).Create(serviceAccount)

	return err
}

func (c *Client) deleteServiceAccount(namespace string) error {
	err := c.client.CoreV1().ServiceAccounts(namespace).Delete(getServiceAccountName(namespace), &metav1.DeleteOptions{})
	return err
}

func (c *Client) createRole(namespace string) error {
	roleName := getRoleName(namespace)

	role := rbacv1.Role{
		ObjectMeta: metav1.ObjectMeta{
			Name:      roleName,
			Namespace: namespace,
			// Labels:    getLabels(),
		},
		Rules: []rbacv1.PolicyRule{
			rbacv1.PolicyRule{
				APIGroups: []string{"", "extensions", "apps"},
				Resources: []string{"*"},
				Verbs:     []string{"*"},
			},
			rbacv1.PolicyRule{
				APIGroups: []string{"batch"},
				Resources: []string{"jobs", "cronjobs"},
				Verbs:     []string{"*"},
			},
		},
	}

	_, err := c.client.RbacV1().Roles(namespace).Create(&role)
	return err
}

func (c *Client) deleteRole(namespace string) error {
	err := c.client.RbacV1().Roles(namespace).Delete(getRoleName(namespace), &metav1.DeleteOptions{})
	return err
}

func (c *Client) CreateIfNotExistServiceAccountClusterRoleBinding(namespace string) error {
	err := c.CreateServiceAccountClusterRoleBinding(namespace)
	if kubernetesErrors.IsAlreadyExists(err) {
		return nil
	}
	return err
}

func (c *Client) CreateServiceAccountClusterRoleBinding(namespace string) error {
	serviceAccountName := getServiceAccountName(namespace)
	roleBindingName := getClusterRoleBindingName(namespace)
	roleBinding := rbacv1.ClusterRoleBinding{
		ObjectMeta: metav1.ObjectMeta{
			Name: roleBindingName,
			// Labels: getLabels(),
		},
		Subjects: []rbacv1.Subject{{
			Name:      serviceAccountName,
			Kind:      "ServiceAccount",
			Namespace: namespace,
		}},
		RoleRef: rbacv1.RoleRef{
			Kind:     "ClusterRole",
			Name:     clusterRoleName,
			APIGroup: "rbac.authorization.k8s.io",
		}}
	_, err := c.client.RbacV1().ClusterRoleBindings().Create(&roleBinding)
	return err
}

func (c *Client) createServiceAccountRoleBinding(namespace string) error {
	serviceAccountName := getServiceAccountName(namespace)
	roleBindingName := getRoleBindingName(namespace)
	roleName := getRoleName(namespace)

	roleBinding := rbacv1.RoleBinding{
		ObjectMeta: metav1.ObjectMeta{
			Name:      roleBindingName,
			Namespace: namespace,
			// Labels:    getLabels(),
		},
		Subjects: []rbacv1.Subject{{
			Name:      serviceAccountName,
			Kind:      "ServiceAccount",
			Namespace: namespace,
		}},
		RoleRef: rbacv1.RoleRef{
			Kind:     "Role",
			Name:     roleName,
			APIGroup: "rbac.authorization.k8s.io",
		}}

	_, err := c.client.RbacV1().RoleBindings(namespace).Create(&roleBinding)

	return err
}

func (c *Client) deleteServiceAccountRoleBinding(namespace string) error {
	err := c.client.RbacV1().RoleBindings(namespace).Delete(getRoleBindingName(namespace), &metav1.DeleteOptions{})
	return err
}

func (c *Client) getServiceAccount(namespace string) (*corev1.ServiceAccount, error) {
	serviceAccountName := getServiceAccountName(namespace)
	serviceAccount, err := c.client.CoreV1().ServiceAccounts(namespace).Get(serviceAccountName, metav1.GetOptions{})
	if err != nil {
		return nil, err
	}

	return serviceAccount, nil
}

func (c *Client) getSecretName(namespace string) (string, error) {
	sa, err := c.getServiceAccount(namespace)
	if err != nil {
		log.Printf("[TRACE] Failed getting service account from namespace %s", namespace)
		return "", nil
	}

	// This should probably be changed
	for _, secret := range sa.Secrets {
		if strings.Contains(secret.Name, "token") {
			return secret.Name, nil
		}

	}
	return "", errors.New("Could not find secret name")
}

func (c *Client) getSecret(namespace string) (*corev1.Secret, error) {
	secretName, err := c.getSecretName(namespace)
	if err != nil {
		log.Printf("[TRACE] Failed getting secret name from namespace %s", namespace)
		return nil, err
	}

	secret, err := c.client.CoreV1().Secrets(namespace).Get(secretName, metav1.GetOptions{})
	if err != nil {
		log.Printf("[TRACE] Failed getting secret from namespace %s", namespace)
		return nil, err
	}

	return secret, nil
}

func (c *Client) GetCertificate(namespace string) (string, error) {
	secret, err := c.getSecret(namespace)
	if err != nil {
		return "", err
	}

	return string(secret.Data["ca.crt"]), nil
}

func (c *Client) GetCertificateB64(namespace string) (string, error) {
	cert, err := c.GetCertificate(namespace)
	if err != nil {
		return "", err
	}

	certB64 := b64.StdEncoding.EncodeToString([]byte(cert))

	return certB64, nil
}

func (c *Client) GetToken(namespace string) (string, error) {
	secret, err := c.getSecret(namespace)
	if err != nil {
		return "", err
	}

	return string(secret.Data["token"]), nil
}

func (c *Client) CreateConfiguration(namespace string) (string, error) {
	type Config struct {
		Namespace   string
		Endpoint    string
		Certificate string
		Token       string
	}

	config := `apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: {{.Certificate}}
    server: {{.Endpoint}}
  name: cluster
users:
- name: {{.Namespace}}-user
  user:
    client-key-data: {{.Certificate}}
    token: {{.Token}}
contexts:
- context:
    cluster: cluster
    namespace: {{.Namespace}}
    user: {{.Namespace}}-user
  name: {{.Namespace}}
current-context: {{.Namespace}}`

	endpoint := c.GetEndpoint()

	certificate, err := c.GetCertificateB64(namespace)
	if err != nil {
		return "", err
	}

	token, err := c.GetToken(namespace)
	if err != nil {
		return "", err
	}

	data := Config{
		Namespace:   namespace,
		Endpoint:    endpoint,
		Certificate: certificate,
		Token:       token,
	}

	tmpl := template.Must(template.New("config").Parse(config))

	var generatedTemplate bytes.Buffer
	if err := tmpl.Execute(&generatedTemplate, data); err != nil {
		return "", err
	}

	return generatedTemplate.String(), nil
}

func (c *Client) GetEndpoint() string {
	return c.config.Host
}

func getServiceAccountName(namespace string) string {
	return namespace + "-user"
}

func getRoleBindingName(namespace string) string {
	return namespace + "-user-view"
}

func getClusterRoleBindingName(namespace string) string {
	return namespace + "-user-clusterrole-binding"
}

func getRoleName(namespace string) string {
	return namespace + "-user-full-access"
}

func createLabels(owner string) map[string]string {
	return map[string]string{
		"bork":       "true",
		"bork.owner": owner,
	}
}
