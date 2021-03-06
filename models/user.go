package models

import (
	"encoding/json"
	"strings"
	"time"

	"github.com/gobuffalo/envy"
	"github.com/gobuffalo/pop"
	"github.com/gobuffalo/uuid"
	"github.com/gobuffalo/validate"
	"github.com/gobuffalo/validate/validators"
)

type User struct {
	ID         uuid.UUID `json:"id" db:"id"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time `json:"updated_at" db:"updated_at"`
	Username   string    `json:"username" db:"username"`
	FirstName  string    `json:"first_name" db:"first_name"`
	LastName   string    `json:"last_name" db:"last_name"`
	Email      string    `json:"email" db:"email"`
	IsAdmin    bool      `json:"is_admin" db:"is_admin"`
	IsActive   bool      `json:"is_active" db:"is_active"`
	Provider   string    `json:"provider" db:"provider"`
	ProviderID string    `json:"provider_id" db:"provider_id"`
}

// String is not required by pop and may be deleted
func (u User) String() string {
	ju, _ := json.Marshal(u)
	return string(ju)
}

// Users is not required by pop and may be deleted
type Users []User

func (u Users) String(i int) string {
	return u[i].Username
}

func (u Users) Len() int {
	return len(u)
}

func (u Users) Filter(f func(User) bool) Users {
	vsf := make(Users, 0)
	for _, v := range u {
		if f(v) {
			vsf = append(vsf, v)
		}
	}
	return vsf
}

// String is not required by pop and may be deleted
// func (u Users) String() string {
// 	ju, _ := json.Marshal(u)
// 	return string(ju)
// }

// Validate gets run every time you call a "pop.Validate*"
// (pop.ValidateAndSave, pop.ValidateAndCreate, pop.ValidateAndUpdate) method.
// This method is not required and may be deleted.
func (u *User) Validate(tx *pop.Connection) (*validate.Errors, error) {
	return validate.Validate(
		&validators.StringIsPresent{Field: u.Provider, Name: "Provider"},
		&validators.StringIsPresent{Field: u.ProviderID, Name: "ProviderID"},
	), nil
}

// ValidateCreate gets run every time you call "pop.ValidateAndCreate" method.
// This method is not required and may be deleted.
func (u *User) ValidateCreate(tx *pop.Connection) (*validate.Errors, error) {
	return validate.NewErrors(), nil
}

// ValidateUpdate gets run every time you call "pop.ValidateAndUpdate" method.
// This method is not required and may be deleted.
func (u *User) ValidateUpdate(tx *pop.Connection) (*validate.Errors, error) {
	return validate.NewErrors(), nil
}

// TODO: lowercase, remove spaces
func (u User) NamespacePrefix() string {
	borkPrefix := envy.Get("BORK_NAMESPACE_PREFIX", "bork")

	username := strings.Split(strings.ToLower(u.Username), " ")

	prefix := append([]string{borkPrefix}, username...)

	return strings.Join(prefix, "-")
}
