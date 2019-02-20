package actions

import (
	"github.com/gobuffalo/buffalo"
	"github.com/gobuffalo/pop"
	"github.com/kradalby/bork/models"
	"github.com/pkg/errors"
)


// List gets all Users. This function is mapped to the path
// GET /admin/dashboard
func Dashboard(c buffalo.Context) error {
	user, err := getLoggedInUser(c)
	if err != nil {
		return c.Error(403, errors.New("Permission denied"))
	}

	if !user.IsAdmin {
		return c.Error(403, errors.New("Permission denied"))
	}

	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return c.Error(500, errors.New("Could not establish database connection"))
	}

	users := &models.Users{}
    namespaces := &models.Namespaces{}

	// Retrieve all Users from the DB
    if err := tx.Eager().Order("created_at desc").Limit(5).All(users); err != nil {
		return errors.WithStack(err)
	}

	// Retrieve all Namespaces from the DB
	if err := tx.Eager().Order("created_at desc").Limit(5).All(namespaces); err != nil {
		return errors.WithStack(err)
	}

    users_count, err := tx.Count(users)
    if err != nil {
		return errors.WithStack(err)
	}

    namespaces_count, err := tx.Count(namespaces)
    if err != nil {
		return errors.WithStack(err)
	}


    dashboard := map[string]interface{}{
        "users_count": users_count,
        "users_new": users,
        "namespaces_count": namespaces_count,
        "namespaces_new": *namespaces,
    }
	return c.Render(200, r.JSON(dashboard))
}
