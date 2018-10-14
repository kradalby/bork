package kube

import (
	//"errors"
	"github.com/kradalby/bork/models"
	corev1 "k8s.io/api/core/v1"
	//kubeErrors "k8s.io/apimachinery/pkg/api/errors"
	"log"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func (c *Client) getAllNamespaces() (*corev1.NamespaceList, error) {

	ns, err := c.client.CoreV1().Namespaces().List(metav1.ListOptions{LabelSelector: "bork"})
	if err != nil {
		return &corev1.NamespaceList{}, err
	}

	return ns, nil
}

// Missing: DB objects, Dead: Kube objects, error
func (c *Client) FindOutOfSyncNamespaces() ([]models.Namespace, []corev1.Namespace, error) {
	namespacesFromCluster, err := c.getAllNamespaces()

	if err != nil {
		return []models.Namespace{}, []corev1.Namespace{}, err
	}

	namespacesFromDatabase := models.Namespaces{}

	err = models.DB.All(&namespacesFromDatabase)
	if err != nil {
		return []models.Namespace{}, []corev1.Namespace{}, err
	}

	namespacesMissingFromCluster := []models.Namespace{}
	namespacesMissingFromDatabase := []corev1.Namespace{}

	for _, ns := range namespacesFromDatabase {
		if !isNamespaceInClusterList(namespacesFromCluster.Items, ns.Name) {
			namespacesMissingFromCluster = append(namespacesMissingFromCluster, ns)
		}
	}

	for _, ns := range namespacesFromCluster.Items {
		if !isNamespaceInDatabaseList(&namespacesFromDatabase, ns.Name) {
			namespacesMissingFromDatabase = append(namespacesMissingFromDatabase, ns)
		}
	}
	// for _, namespace := range namespacesFromDatabase {
	// 	ns, err := c.getNamespaceFromCluster(namespace.Name)
	// 	if err != nil {
	// 		return &models.Namespaces{}, []*corev1.Namespace{}, err
	// 	}

	// 	if ns == nil {
	// 		namespacesMissingFromCluster = append(namespacesMissingFromCluster, namespace)
	// 	}
	// }

	// for _, namespace := range namespacesFromCluster.Items {
	// 	ns, err := getNamespaceFromDatabase(namespace.Name)
	// 	if err != nil {
	// 		return &models.Namespaces{}, []*corev1.Namespace{}, err
	// 	}

	// 	if ns == nil {
	// 		namespacesMissingFromDatabase = append(namespacesMissingFromDatabase, &namespace)
	// 	}

	// }

	return namespacesMissingFromCluster, namespacesMissingFromDatabase, nil
}

func (c *Client) DeleteOrphansInCluster(list []corev1.Namespace) error {
	for _, ns := range list {
		err := c.deleteNamespace(ns.Name)
		if err != nil {
			return err
		}
	}
	return nil
}

func (c *Client) CreateMissingFromDatabase(list []models.Namespace) error {
	for _, ns := range list {
		err := c.CreateNamespaceWithServiceAccount(ns.Name, ns.Owner.ID)
		if err != nil {
			return err
		}
	}
	return nil
}

func (c *Client) Sync(createList []models.Namespace, deleteList []corev1.Namespace) error {

	log.Println("[INFO] Missing from cluster: ")
	for _, ns := range createList {
		log.Println("[INFO] ", ns.Name)
	}

	log.Println("[INFO] Missing from database: ")
	for _, ns := range deleteList {
		log.Println("[INFO] ", ns.Name)
	}

	log.Printf("[DEBUG] Creating namespaces missing from cluster")
	err := c.CreateMissingFromDatabase(createList)
	if err != nil {
		return err
	}

	log.Printf("[DEBUG] Deleting namespaces missing from database")
	err = c.DeleteOrphansInCluster(deleteList)
	if err != nil {
		return err
	}

	return nil
}

func isNamespaceInDatabaseList(list *models.Namespaces, name string) bool {
	for _, ns := range *list {
		if ns.Name == name {
			return true
		}
	}
	return false
}

func isNamespaceInClusterList(list []corev1.Namespace, name string) bool {
	for _, ns := range list {
		if ns.Name == name {
			return true
		}
	}
	return false
}

// func getNamespaceFromDatabase(name string) (*models.Namespace, error) {
// 	ns := models.Namespaces{}
// 	err := models.DB.Where("name = '" + name + "'").All(&ns)
// 	if err != nil {
// 		return nil, err
// 	}
//
// 	if len(ns) == 0 {
// 		return nil, errors.New("Did not find any namespace with the given name")
// 	}
//
// 	if len(ns) > 1 {
// 		return nil, errors.New("Found multiple namespaces with the same name")
// 	}
//
// 	if ns[0].Name != name {
// 		return nil, errors.New("Could not find namespace")
// 	}
//
// 	return &ns[0], nil
// }
//
// func (c *Client) getNamespaceFromCluster(name string) (*corev1.Namespace, error) {
//
// 	ns, err := c.client.CoreV1().Namespaces().Get(name, metav1.GetOptions{})
//
// 	if serr, ok := err.(*kubeErrors.StatusError); ok {
// 		if serr.ErrStatus.Reason == "NotFound" {
// 			return nil, nil
// 		}
// 	}
//
// 	if err != nil {
// 		return nil, err
// 	}
//
// 	if ns.Name != name {
// 		return nil, errors.New("Could not find namespace")
// 	}
//
// 	return ns, nil
// }
