package actions


import (
	"github.com/gobuffalo/buffalo"
	"fmt"
	"encoding/json"
    //"github.com/davecgh/go-spew/spew"
)

func setErrorHandler(app *buffalo.App) {
	app.ErrorHandlers[400] = customErrorHandler()
	app.ErrorHandlers[403] = customErrorHandler()
	app.ErrorHandlers[404] = customErrorHandler()
	app.ErrorHandlers[500] = customErrorHandler()
	app.ErrorHandlers[501] = customErrorHandler()
}

func customErrorHandler() buffalo.ErrorHandler {
	return func(status int, err error, c buffalo.Context) error {
		c.Logger().Error(err)
		c.Response().WriteHeader(status)

        response := json.NewEncoder(c.Response()).Encode(map[string]interface{}{
				"error": fmt.Sprintf("%s", err),
				"code":  status,
	          })

        return response
    }
}
