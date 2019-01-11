package grifts

import (
	"github.com/gobuffalo/buffalo"
	"github.com/kradalby/bork/actions"
)

func init() {
	buffalo.Grifts(actions.App(""))
}
