package actions

import (
	"github.com/gobuffalo/buffalo/render"
	"github.com/gobuffalo/packr"
)

var r *render.Engine

var assetsBox = packr.NewBox("../assets")

func init() {
	r = render.New(render.Options{
		// Box containing all of the templates:
		TemplatesBox: packr.NewBox("../templates"),
		AssetsBox:    assetsBox,

		// Add template helpers here:
		Helpers: render.Helpers{},
	})
}
