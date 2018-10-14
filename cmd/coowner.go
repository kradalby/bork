// Copyright © 2018 Kristoffer Dalby <kradalby@kradalby.no>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

package cmd

import (
	"log"

	"github.com/gobuffalo/uuid"
	"github.com/kradalby/bork/models"
	"github.com/spf13/cobra"
)

var (
	user      string
	namespace string
)

// coownerCmd represents the coowner command
var newCoOwnerCmd = &cobra.Command{
	Use:   "coowner",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {

		userID, err := uuid.FromString(user)
		if err != nil {
			log.Fatalf("Could not parse UUID: %s", err)
		}

		namespaceID, err := uuid.FromString(namespace)
		if err != nil {
			log.Fatalf("Could not parse UUID: %s", err)
		}

		// Allocate an empty Namespace
		u := &models.User{}
		ns := &models.Namespace{}

		if err := models.DB.Eager().Find(u, userID); err != nil {
			log.Fatalf("Could not find namespace: %s", err)
		}

		if err := models.DB.Eager().Find(ns, namespaceID); err != nil {
			log.Fatalf("Could not find namespace: %s", err)
		}

		models.DB.RawQuery("INSERT INTO namespaces_users (namespace_id, user_id) VALUES ('?', '?')", ns.ID, u.ID)

		if err != nil {
			log.Fatalf("Could not update namespace: %s", err)
		}

		// This is not how we do it until Eager update is created

		// // Add user to coOwner list
		// ns.AddCoOwner(*u)

		// log.Printf("NS: %#v", ns)

		// _, err = models.DB.Eager().ValidateAndUpdate(ns)
		// if err != nil {
		// 	log.Fatalf("Could not update namespace: %s", err)
		// }
	},
}

func init() {
	newCmd.AddCommand(newCoOwnerCmd)

	newCoOwnerCmd.Flags().StringVarP(&user, "user", "u", "", "User UUID")
	newCoOwnerCmd.Flags().StringVarP(&namespace, "namespace", "n", "", "Namespace UUID")

	newCoOwnerCmd.MarkFlagRequired("user")
	newCoOwnerCmd.MarkFlagRequired("namespace")
	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// coownerCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// coownerCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
