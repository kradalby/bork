package actions

import (
	"github.com/gobuffalo/buffalo"
	"github.com/gobuffalo/buffalo/middleware/csrf"

	"github.com/gobuffalo/buffalo/middleware"
	"github.com/gobuffalo/buffalo/middleware/ssl"
	"github.com/gobuffalo/envy"
	"github.com/unrolled/secure"

	"github.com/gobuffalo/x/sessions"
	"github.com/kradalby/bork/kube"
	"github.com/kradalby/bork/models"
	"github.com/rs/cors"
)

// ENV is used to help switch settings based on where the
// application is being run. Default is "development".
var ENV = envy.Get("GO_ENV", "development")
var app *buffalo.App
var kubernetesConf string

// App is where all routes and middleware for buffalo
// should be defined. This is the nerve center of your
// application.
func App(kubeconf string) *buffalo.App {
	if app == nil {

		kubernetesConf = kubeconf

		app = buffalo.New(buffalo.Options{
			Env:          ENV,
			SessionStore: sessions.Null{},
			PreWares: []buffalo.PreWare{
				cors.Default().Handler,
			},
			SessionName: "_bork_session",
		})
		// Automatically redirect to SSL
		app.Use(forceSSL())

		// Set the request content type to JSON
		app.Use(middleware.SetContentType("application/json"))
		app.Use(csrf.New)
		app.Use(middleware.PopTransaction(models.DB))

		if ENV == "development" {
			app.Use(middleware.ParameterLogger)
		}

		app.GET("/", HomeHandler)

		apiV1 := app.Group("/api/v1")

		apiV1.Resource("/users", UsersResource{})
		apiV1.Resource("/namespaces", NamespacesResource{})
		apiV1.GET("/namespaces/{namespace_id}/token", NamespaceToken)
		apiV1.GET("/namespaces/{namespace_id}/certificate", NamespaceCertificate)
		apiV1.GET("/namespaces/{namespace_id}/certificateb64", NamespaceCertificateB64)
		apiV1.GET("/namespaces/{namespace_id}/endpoint", NamespaceEndpoint)
		apiV1.GET("/namespaces/{namespace_id}/auth", NamespaceAuth)
	}

	return app
}

// forceSSL will return a middleware that will redirect an incoming request
// if it is not HTTPS. "http://example.com" => "https://example.com".
// This middleware does **not** enable SSL. for your application. To do that
// we recommend using a proxy: https://gobuffalo.io/en/docs/proxy
// for more information: https://github.com/unrolled/secure/
func forceSSL() buffalo.MiddlewareFunc {
	return ssl.ForceSSL(secure.Options{
		SSLRedirect:     ENV == "production",
		SSLProxyHeaders: map[string]string{"X-Forwarded-Proto": "https"},
	})
}

func getKubernetesClient() (*kube.Client, error) {
	if ENV == "development" {
		client, err := kube.NewOutOfClusterClient(kubernetesConf)
		if err != nil {
			return nil, err
		}

		return client, err
	}

	client, err := kube.NewInClusterClient()
	if err != nil {
		return nil, err
	}

	return client, err

}
