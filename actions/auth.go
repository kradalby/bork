package actions

import (
	"fmt"
	"os"
	"strings"

	"github.com/gobuffalo/buffalo"
	"github.com/gobuffalo/envy"
	"github.com/gobuffalo/pop"
	"github.com/kradalby/bork/models"
	"github.com/markbates/goth"
	"github.com/markbates/goth/gothic"
	"github.com/markbates/goth/providers/openidConnect"
	"github.com/pkg/errors"
)

func init() {
	gothic.Store = App("").SessionStore

	// OpenID Connect is based on OpenID Connect Auto Discovery URL
	// (https://openid.net/specs/openid-connect-discovery-1_0-17.html)
	// because the OpenID Connect provider initialize it self in the New(),
	// it can return an error which should be handled or ignored
	// ignore the error for now
	// scopes := []string{"openid", "email", "profile", "offline_access"}
	// scopes := []string{"openid", "email", "groups", "profile", "offline_access"}

	scopesString := envy.Get("OPENID_CONNECT_SCOPES", "openid")
	scopes := strings.Split(scopesString, " ")

	openidConnect, err := openidConnect.New(
		os.Getenv("OPENID_CONNECT_KEY"),
		os.Getenv("OPENID_CONNECT_SECRET"),
		os.Getenv("OPENID_CONNECT_CALLBACK"),
		os.Getenv("OPENID_CONNECT_DISCOVERY_URL"),
		scopes...,
	)
	if err != nil {
		panic(fmt.Sprintf("Could not set up OpenID Connect, %#v", err))
	}

	goth.UseProviders(openidConnect)
}

func AuthCallback(c buffalo.Context) error {
	gu, err := gothic.CompleteUserAuth(c.Response(), c.Request())
	if err != nil {
		return c.Error(401, err)
	}
	tx := c.Value("tx").(*pop.Connection)
	q := tx.Where("provider = ? and provider_id = ?", gu.Provider, gu.UserID)
	exists, err := q.Exists("users")
	if err != nil {
		return errors.WithStack(err)
	}
	u := &models.User{}
	if exists {
		if err = q.First(u); err != nil {
			return errors.WithStack(err)
		}
	}
	names := strings.Split(gu.Name, " ")

	fmt.Printf("gu: %#v", gu)
	u.Username = gu.Name
	u.FirstName = names[0]
	u.LastName = names[len(names)-1]
	u.Provider = gu.Provider
	u.ProviderID = gu.UserID
	u.Email = gu.Email
	if err = tx.Save(u); err != nil {
		return errors.WithStack(err)
	}

	c.Session().Set("current_user_id", u.ID)
	if err = c.Session().Save(); err != nil {
		return errors.WithStack(err)
	}

	return c.Redirect(302, "/")
}

func AuthDestroy(c buffalo.Context) error {
	c.Session().Clear()
	return c.Redirect(302, "/")
}

func SetCurrentUser(next buffalo.Handler) buffalo.Handler {
	return func(c buffalo.Context) error {
		if uid := c.Session().Get("current_user_id"); uid != nil {
			u := &models.User{}
			tx := c.Value("tx").(*pop.Connection)
			if err := tx.Find(u, uid); err != nil {
				return errors.WithStack(err)
			}
			c.Set("current_user", u)
		}
		return next(c)
	}
}

func Session(c buffalo.Context) error {
	if uid := c.Session().Get("current_user_id"); uid != nil {
		u := &models.User{}
		tx := c.Value("tx").(*pop.Connection)
		if err := tx.Find(u, uid); err != nil {
			return errors.WithStack(err)
		}
		return c.Render(200, r.JSON(u))
	}
	return c.Render(403, r.JSON("forbidden"))
}

func Authorize(next buffalo.Handler) buffalo.Handler {
	return func(c buffalo.Context) error {
		if uid := c.Session().Get("current_user_id"); uid == nil {
			// return c.Redirect(302, "/")
			return c.Render(403, r.JSON("forbidden"))
		}
		return next(c)
	}
}
