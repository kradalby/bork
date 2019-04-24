package actions

import (
	"regexp"

	"github.com/gobuffalo/buffalo"
	"github.com/gobuffalo/pop"
	"github.com/kradalby/bork/models"
	"github.com/pkg/errors"
)

func getLoggedInUser(c buffalo.Context) (*models.User, error) {
	userID := c.Session().Session.Values["current_user_id"]

	// Get the DB connection from the context
	tx, ok := c.Value("tx").(*pop.Connection)
	if !ok {
		return nil, errors.WithStack(errors.New("no transaction found"))
	}

	user := &models.User{}

	// To find the User the parameter user_id is used.
	if err := tx.Eager().Find(user, userID); err != nil {
		return nil, c.Error(404, err)
	}

	return user, nil
}

func isOwner(namespace *models.Namespace, user *models.User) bool {
	return namespace.OwnerID == user.ID
}

func isCoOwner(namespace *models.Namespace, user *models.User) bool {
	for _, coOwner := range namespace.CoOwners {
		if coOwner.ID == user.ID {
			return true
		}
	}
	return false
}

func ValidateNamespaceName(prefix string, name string) []string {
	errors := []string{}

	fullName := prefix + "-" + name

	if name == "" {
		errors = append(errors, "Name cannot be empty")
	}

	if len(fullName) > 253 {
		errors = append(errors, "Name cannot be longer than 253")
	}

	var HasValidCharacters = regexp.MustCompile(`^[a-z0-9\.-]+$`).MatchString

	if !HasValidCharacters(fullName) {
		errors = append(errors, "Name contains invalid characters")
		errors = append(errors, "Characters must be lowercase alphanumeric, . and -")
	}

	namespaces := &models.Namespaces{}

	if err := models.DB.Eager().Where("name = ?", fullName).All(namespaces); err != nil {
		errors = append(errors, "Database lookup error")
	}

	if len(*namespaces) != 0 {
		errors = append(errors, "Namespace already exists")
	}

	return errors
}
