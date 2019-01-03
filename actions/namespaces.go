package actions

import (
	"github.com/gobuffalo/buffalo"
	"github.com/gobuffalo/pop"
	"github.com/kradalby/bork/models"
	"github.com/pkg/errors"
	"log"
)

// This file is generated by Buffalo. It offers a basic structure for
// adding, editing and deleting a page. If your model is more
// complex or you need more than the basic implementation you need to
// edit this file.

// Following naming logic is implemented in Buffalo:
// Model: Singular (Namespace)
// DB Table: Plural (namespaces)
// Resource: Plural (Namespaces)
// Path: Plural (/namespaces)
// View Template Folder: Plural (/templates/namespaces/)

// NamespacesResource is the resource for the Namespace model
type NamespacesResource struct {
	buffalo.Resource
}

// List gets all Namespaces. This function is mapped to the path
// GET /namespaces
func (v NamespacesResource) List(c buffalo.Context) error {
	// Get the DB connection from the context
	userId := c.Session().Session.Values["current_user_id"]
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	namespaces := &models.Namespaces{}

	// Paginate results. Params "page" and "per_page" control pagination.
	// Default values are "page=1" and "per_page=20".
	q := tx.Eager().PaginateFromParams(c.Params())

	// Retrieve all Namespaces from the DB
	if err := q.Where("owner_id = ?", userId).All(namespaces); err != nil {
		return errors.WithStack(err)
	}

	// Add the paginator to the context so it can be used in the template.
	c.Set("pagination", q.Paginator)

	return c.Render(200, r.JSON(namespaces))
}

// Show gets the data for one Namespace. This function is mapped to
// the path GET /namespaces/{namespace_id}
func (v NamespacesResource) Show(c buffalo.Context) error {
	userId := c.Session().Session.Values["current_user_id"]
	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	// Allocate an empty Namespace
	namespace := &models.Namespace{}

	// To find the Namespace the parameter namespace_id is used.
	if err := tx.Eager().Find(namespace, c.Param("namespace_id")); err != nil {
		return c.Error(404, err)
	}

	if namespace.Owner.ID != userId {
		return c.Error(403, errors.New("permission denied"))
	}

	return c.Render(200, r.JSON(namespace))
}

// New renders the form for creating a new Namespace.
// This function is mapped to the path GET /namespaces/new
func (v NamespacesResource) New(c buffalo.Context) error {
	return c.Render(200, r.JSON(&models.Namespace{}))
}

// Create adds a Namespace to the DB. This function is mapped to the
// path POST /namespaces
func (v NamespacesResource) Create(c buffalo.Context) error {
	userId := c.Session().Session.Values["current_user_id"]

	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	user := &models.User{}

	// To find the User the parameter user_id is used.
	if err := tx.Eager().Find(user, userId); err != nil {
		return c.Error(404, err)
	}

	// Allocate an empty Namespace
	namespace := &models.Namespace{}

	// Bind namespace to the html form elements
	if err := c.Bind(namespace); err != nil {
		return errors.WithStack(err)
	}

	namespace.Owner = *user
	namespace.OwnerID = user.ID

	// Validate the data from the html form
	_, err := tx.ValidateAndCreate(namespace)
	if err != nil {
		return errors.WithStack(err)
	}

	kubeClient, err := getKubernetesClient()
	if err != nil {
		return c.Error(500, err)
	}

	err = kubeClient.CreateNamespace(namespace.Name, namespace.Owner.ID)
	if err != nil {
		return errors.WithStack(err)
	}

	// and redirect to the namespaces index page
	return c.Render(201, r.JSON(namespace))
}

// Edit renders a edit form for a Namespace. This function is
// mapped to the path GET /namespaces/{namespace_id}/edit
func (v NamespacesResource) Edit(c buffalo.Context) error {
	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	// Allocate an empty Namespace
	namespace := &models.Namespace{}

	if err := tx.Find(namespace, c.Param("namespace_id")); err != nil {
		return c.Error(404, err)
	}

	return c.Render(200, r.JSON(namespace))
}

// Update changes a Namespace in the DB. This function is mapped to
// the path PUT /namespaces/{namespace_id}
func (v NamespacesResource) Update(c buffalo.Context) error {
	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	// Allocate an empty Namespace
	namespace := &models.Namespace{}

	if err := tx.Find(namespace, c.Param("namespace_id")); err != nil {
		return c.Error(404, err)
	}

	// Bind Namespace to the html form elements
	if err := c.Bind(namespace); err != nil {
		return errors.WithStack(err)
	}

	verrs, err := tx.ValidateAndUpdate(namespace)
	if err != nil {
		return errors.WithStack(err)
	}

	if verrs.HasAny() {
		// Make the errors available inside the html template
		c.Set("errors", verrs)

		// Render again the edit.html template that the user can
		// correct the input.
		return c.Render(422, r.JSON(namespace))
	}

	// If there are no errors set a success message
	c.Flash().Add("success", "Namespace was updated successfully")

	// and redirect to the namespaces index page
	return c.Render(200, r.JSON(namespace))
}

// Destroy deletes a Namespace from the DB. This function is mapped
// to the path DELETE /namespaces/{namespace_id}
func (v NamespacesResource) Destroy(c buffalo.Context) error {
	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	// Allocate an empty Namespace
	namespace := &models.Namespace{}

	// To find the Namespace the parameter namespace_id is used.
	if err := tx.Find(namespace, c.Param("namespace_id")); err != nil {
		return c.Error(404, err)
	}

	if err := tx.Destroy(namespace); err != nil {
		return errors.WithStack(err)
	}

	// If there are no errors set a flash message
	c.Flash().Add("success", "Namespace was destroyed successfully")

	// Redirect to the namespaces index page
	return c.Render(200, r.JSON(namespace))
}

// Custom extension to Resource

// Gets all Namespaces where logged in user is coowner. This function is mapped to the path
// GET /namespaces/coowner
func NamespaceCoOwner(c buffalo.Context) error {
	// Get the DB connection from the context
	// userId := c.Session().Session.Values["current_user_id"]
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	namespaces := &models.Namespaces{}

	// Paginate results. Params "page" and "per_page" control pagination.
	// Default values are "page=1" and "per_page=20".
	q := tx.Eager().PaginateFromParams(c.Params())

	query := q.RawQuery("SELECT id, created_at, updated_at, name, owner_id FROM namespaces JOIN namespaces_users ON id = namespace_id WHERE user_id = ?", c.Param("user_id"))

	// Retrieve all Namespaces from the DB
	//if err := q.LeftJoin("namespaces", "namespaces.id=namespaces_users.namespace_id").Where("user_id = ?", userId).All(namespaces); err != nil {
	if err := query.All(namespaces); err != nil {
		return errors.WithStack(err)
	}

	// Add the paginator to the context so it can be used in the template.
	c.Set("pagination", q.Paginator)

	return c.Render(200, r.JSON(namespaces))
}

func NamespaceAddCoOwner(c buffalo.Context) error {
	// Allocate an empty Namespace
	user := &models.User{}

	// Bind namespace to the html form elements
	if err := c.Bind(user); err != nil {
		return errors.WithStack(err)
	}

	log.Printf("User %#v", user)

	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	if err := tx.RawQuery("INSERT INTO namespaces_users (namespace_id, user_id) VALUES (?, ?)", c.Param("namespace_id"), user.ID).Exec(); err != nil {
		return errors.WithStack(err)
	}

	namespace := &models.Namespace{}

	// To find the Namespace the parameter namespace_id is used.
	if err := tx.Eager().Find(namespace, c.Param("namespace_id")); err != nil {
		return c.Error(404, err)
	}
	log.Printf("Namespace: %#v", namespace)

	return c.Render(200, r.JSON(namespace))
}

func NamespaceDeleteCoOwner(c buffalo.Context) error {
	// Allocate an empty Namespace
	user := &models.User{}

	// Bind namespace to the html form elements
	if err := c.Bind(user); err != nil {
		return errors.WithStack(err)
	}

	log.Printf("User %#v", user)

	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	if err := tx.RawQuery("DELETE FROM namespaces_users WHERE namespace_id = ? AND user_id = ?", c.Param("namespace_id"), user.ID).Exec(); err != nil {
		return errors.WithStack(err)
	}

	namespace := &models.Namespace{}

	// To find the Namespace the parameter namespace_id is used.
	if err := tx.Eager().Find(namespace, c.Param("namespace_id")); err != nil {
		return c.Error(404, err)
	}
	log.Printf("Namespace: %#v", namespace)

	return c.Render(200, r.JSON(namespace))
}

// Gets all Namespaces where logged in user is coowner. This function is mapped to the path
// GET /namespaces/coowner
func NamespaceAvailableUsers(c buffalo.Context) error {
	// Get the DB connection from the context
	// userId := c.Session().Session.Values["current_user_id"]
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	users := &models.Users{}

	// Retrieve all Users from the DB
	if err := tx.All(users); err != nil {
		return errors.WithStack(err)
	}

	namespace := &models.Namespace{}

	// To find the Namespace the parameter namespace_id is used.
	if err := tx.Eager().Find(namespace, c.Param("namespace_id")); err != nil {
		return c.Error(404, err)
	}

	available := users.Filter(func(u models.User) bool {
		if u == namespace.Owner {
			return false
		}

		for i := range namespace.CoOwners {
			if u == namespace.CoOwners[i] {
				return false
			}
		}
		return true
	})

	return c.Render(200, r.JSON(available))
}

func NamespaceToken(c buffalo.Context) error {
	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	// Allocate an empty Namespace
	namespace := &models.Namespace{}

	// To find the Namespace the parameter namespace_id is used.
	if err := tx.Find(namespace, c.Param("namespace_id")); err != nil {
		return c.Error(404, err)
	}

	kubeClient, err := getKubernetesClient()
	if err != nil {
		return c.Error(500, err)
	}

	token, err := kubeClient.GetToken(namespace.Name)
	if err != nil {
		return c.Error(500, err)
	}

	return c.Render(200, r.JSON(map[string]string{"token": token}))
}

func NamespaceCertificate(c buffalo.Context) error {
	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	// Allocate an empty Namespace
	namespace := &models.Namespace{}

	// To find the Namespace the parameter namespace_id is used.
	if err := tx.Find(namespace, c.Param("namespace_id")); err != nil {
		return c.Error(404, err)
	}

	kubeClient, err := getKubernetesClient()
	if err != nil {
		return c.Error(500, err)
	}

	cert, err := kubeClient.GetCertificate(namespace.Name)
	if err != nil {
		return c.Error(500, err)
	}

	return c.Render(200, r.JSON(map[string]string{"certificate": cert}))
}

func NamespaceCertificateB64(c buffalo.Context) error {
	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	// Allocate an empty Namespace
	namespace := &models.Namespace{}

	// To find the Namespace the parameter namespace_id is used.
	if err := tx.Find(namespace, c.Param("namespace_id")); err != nil {
		return c.Error(404, err)
	}

	kubeClient, err := getKubernetesClient()
	if err != nil {
		return c.Error(500, err)
	}

	cert, err := kubeClient.GetCertificateB64(namespace.Name)
	if err != nil {
		return c.Error(500, err)
	}

	return c.Render(200, r.JSON(map[string]string{"certificate_b64": cert}))
}

func NamespaceEndpoint(c buffalo.Context) error {
	kubeClient, err := getKubernetesClient()
	if err != nil {
		return c.Error(500, err)
	}

	endpoint := kubeClient.GetEndpoint()

	return c.Render(200, r.JSON(map[string]string{"endpoint": endpoint}))
}

func NamespaceAuth(c buffalo.Context) error {
	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	// Allocate an empty Namespace
	namespace := &models.Namespace{}

	// To find the Namespace the parameter namespace_id is used.
	if err := tx.Find(namespace, c.Param("namespace_id")); err != nil {
		return c.Error(404, err)
	}

	log.Println(namespace.Name)

	kubeClient, err := getKubernetesClient()
	if err != nil {
		return c.Error(500, err)
	}

	token, err := kubeClient.GetToken(namespace.Name)
	if err != nil {
		return c.Error(500, err)
	}

	cert, err := kubeClient.GetCertificate(namespace.Name)
	if err != nil {
		return c.Error(500, err)
	}

	cert64, err := kubeClient.GetCertificateB64(namespace.Name)
	if err != nil {
		return c.Error(500, err)
	}

	endpoint := kubeClient.GetEndpoint()

	return c.Render(200, r.JSON(map[string]string{
		"token":           token,
		"certificate":     cert,
		"certificate_b64": cert64,
		"endpoint":        endpoint,
	}))
}

func NamespaceConfig(c buffalo.Context) error {
	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return errors.WithStack(errors.New("no transaction found"))
	}

	// Allocate an empty Namespace
	namespace := &models.Namespace{}

	// To find the Namespace the parameter namespace_id is used.
	if err := tx.Find(namespace, c.Param("namespace_id")); err != nil {
		return c.Error(404, err)
	}

	kubeClient, err := getKubernetesClient()
	if err != nil {
		return c.Error(500, err)
	}

	endpoint, err := kubeClient.CreateConfiguration(namespace.Name)
	if err != nil {
		return c.Error(500, err)
	}

	return c.Render(200, r.JSON(map[string]string{"config": endpoint}))
}
