package models

import (
	"encoding/json"
	"log"
	"time"

	"github.com/gobuffalo/pop"
	"github.com/gobuffalo/uuid"
	"github.com/gobuffalo/validate"
	"github.com/gobuffalo/validate/validators"
)

type Namespace struct {
	ID        uuid.UUID `json:"id" db:"id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
	Owner     User      `json:"owner" belongs_to:"owner"`
	OwnerID   uuid.UUID `json:"owner_id" db:"owner_id"`
	CoOwners  Users     `json:"co_owners" many_to_many:"namespaces_users"`
	Name      string    `json:"name" db:"name"`
}

// String is not required by pop and may be deleted
func (n Namespace) String() string {
	jn, _ := json.Marshal(n)
	return string(jn)
}

// Namespaces is not required by pop and may be deleted
type Namespaces []Namespace

// String is not required by pop and may be deleted
func (n Namespaces) String() string {
	jn, _ := json.Marshal(n)
	return string(jn)
}

// Validate gets run every time you call a "pop.Validate*"
// (pop.ValidateAndSave, pop.ValidateAndCreate, pop.ValidateAndUpdate) method.
// This method is not required and may be deleted.
func (n *Namespace) Validate(tx *pop.Connection) (*validate.Errors, error) {
	return validate.Validate(
		&validators.StringIsPresent{Field: n.Name, Name: "Name"},
	), nil
}

// ValidateCreate gets run every time you call "pop.ValidateAndCreate" method.
// This method is not required and may be deleted.
func (n *Namespace) ValidateCreate(tx *pop.Connection) (*validate.Errors, error) {
	return validate.NewErrors(), nil
}

// ValidateUpdate gets run every time you call "pop.ValidateAndUpdate" method.
// This method is not required and may be deleted.
func (n *Namespace) ValidateUpdate(tx *pop.Connection) (*validate.Errors, error) {
	return validate.NewErrors(), nil
}

func (n *Namespace) Users() Users {
	list := make(Users, len(n.CoOwners)+1)

	list[0] = n.Owner

	for i := range n.CoOwners {
		list[i+1] = n.CoOwners[i]
	}

	return list
}

func (n *Namespace) AddCoOwner(user User) {
	if n.isOwnerOrCoOwner(user) {
		log.Printf("[TRACE] User %s (%s) is already owner or coowner of this namespace",
			user.Username,
			user.ID.String())
		return
	}

	list := make(Users, len(n.CoOwners)+1)

	for i := range n.CoOwners {
		list[i] = n.CoOwners[i]
	}

	list[len(list)-1] = user

	n.CoOwners = list
}

func (n *Namespace) isOwnerOrCoOwner(user User) bool {
	if user.ID == n.OwnerID {
		return true
	}

	for _, u := range n.CoOwners {
		if user.ID == u.ID {
			return true
		}
	}
	return false
}
