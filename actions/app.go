package actions

import (
	"github.com/gobuffalo/buffalo"
	"github.com/gobuffalo/mw-csrf"

	"github.com/gobuffalo/buffalo-pop/pop/popmw"
	"github.com/gobuffalo/mw-contenttype"
	"github.com/gobuffalo/mw-forcessl"
	"github.com/gobuffalo/mw-paramlogger"

	"github.com/gobuffalo/envy"
	"github.com/unrolled/secure"

	// "github.com/gobuffalo/x/sessions"
	"github.com/kradalby/bork/kube"
	"github.com/kradalby/bork/models"
	"github.com/markbates/goth/gothic"
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
	kubernetesConf = kubeconf
	if app == nil {
		app = buffalo.New(buffalo.Options{
			Env: ENV,
			// SessionStore: sessions.Null{},
			PreWares: []buffalo.PreWare{
				cors.Default().Handler,
			},
			SessionName: "_bork_session",
		})
		// Automatically redirect to SSL
		app.Use(forceSSL())

		// Set the request content type to JSON
		app.Use(contenttype.Set("application/json"))
		app.Use(csrf.New)
		app.Use(popmw.Transaction(models.DB))

		if ENV == "development" {
			app.Use(paramlogger.ParameterLogger)
		}

		app.GET("/", HomeHandler)

		// Authorization section
		auth := app.Group("/auth")
		auth.GET("/session", Session)
		auth.GET("/logout", AuthDestroy)
		bah := buffalo.WrapHandlerFunc(gothic.BeginAuthHandler)
		auth.GET("/{provider}", bah)
		auth.GET("/{provider}/callback", AuthCallback)
		auth.DELETE("", AuthDestroy)
		auth.Middleware.Skip(Authorize, bah, AuthCallback, Session)

		// API section
		apiV1 := app.Group("/api/v1")
		apiV1.Use(Authorize)
		apiV1.Use(SetCurrentUser)

		apiV1.Resource("/users", UsersResource{})
		apiV1.Resource("/namespaces", NamespacesResource{})
		apiV1.GET("/namespaces/{namespace_id}/token", NamespaceToken)
		apiV1.GET("/namespaces/{namespace_id}/certificate", NamespaceCertificate)
		apiV1.GET("/namespaces/{namespace_id}/certificateb64", NamespaceCertificateB64)
		apiV1.GET("/namespaces/{namespace_id}/endpoint", NamespaceEndpoint)
		apiV1.GET("/namespaces/{namespace_id}/auth", NamespaceAuth)
		apiV1.GET("/namespaces/{namespace_id}/config", NamespaceConfig)
		apiV1.GET("/coowner/namespaces", NamespaceCoOwner)
	}

	return app
}

// forceSSL will return a middleware that will redirect an incoming request
// if it is not HTTPS. "http://example.com" => "https://example.com".
// This middleware does **not** enable SSL. for your application. To do that
// we recommend using a proxy: https://gobuffalo.io/en/docs/proxy
// for more information: https://github.com/unrolled/secure/
func forceSSL() buffalo.MiddlewareFunc {
	return forcessl.Middleware(secure.Options{
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
