package actions

import (
	"github.com/gobuffalo/buffalo"
	"github.com/gobuffalo/mw-csrf"

	"github.com/gobuffalo/buffalo-pop/pop/popmw"
	// "github.com/gobuffalo/mw-contenttype"
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

var DEVELOPMENT = "development"
var PRODUCTION = "production"
var ENV = envy.Get("GO_ENV", DEVELOPMENT)
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

		// Set the request content type to JSON
		// app.Use(contenttype.Set("application/json"))

		if ENV == PRODUCTION {
			app.Use(forceSSL())
			app.Use(csrf.New)
            setErrorHandler(app)
		}

		if ENV == DEVELOPMENT {
			app.Use(paramlogger.ParameterLogger)
		}

		app.Use(popmw.Transaction(models.DB))

		app.ServeFiles("/assets", assetsBox)

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


        users := apiV1.Group("/users")
		// apiV1.Resource("/users", UsersResource{})
		users.GET("/", UserList)
		users.GET("/{user_id}", UserShow)
		users.GET("/{user_id}/coowned", NamespaceCoOwner)

        namespaces := apiV1.Group("/namespaces")
		namespaces.GET("/prefix/", NamespacePrefix)
		namespaces.POST("/validate/", NamespaceValidateName)
		namespaces.Resource("/", NamespacesResource{})
		namespaces.POST("/{namespace_id}/coowners", NamespaceAddCoOwner)
		namespaces.DELETE("/{namespace_id}/coowners", NamespaceDeleteCoOwner)
		namespaces.GET("/{namespace_id}/available_users", NamespaceAvailableUsers)
		namespaces.GET("/{namespace_id}/token", NamespaceToken)
		namespaces.GET("/{namespace_id}/certificate", NamespaceCertificate)
		namespaces.GET("/{namespace_id}/certificateb64", NamespaceCertificateB64)
		namespaces.GET("/{namespace_id}/endpoint", NamespaceEndpoint)
		namespaces.GET("/{namespace_id}/auth", NamespaceAuth)
		namespaces.GET("/{namespace_id}/config", NamespaceConfig)

        admin := apiV1.Group("/admin")
        admin.GET("/dashboard", Dashboard)

		app.GET("/{path:.+}", HomeHandler)
		app.GET("/", HomeHandler)

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
	if ENV == DEVELOPMENT {
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
