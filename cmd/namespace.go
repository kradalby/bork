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
	"fmt"

	"github.com/kradalby/bork/kube"
	"github.com/kradalby/bork/models"
	"github.com/spf13/cobra"
)

var name string
var owner string

// newNamespaceCmd represents the newNamespace command
var newNamespaceCmd = &cobra.Command{
	Use:   "namespace",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		client, err := kube.NewOutOfClusterClient(kubeconf)
		if err != nil {
			fmt.Printf("[Error] %#v", err)
		}

		err = client.CreateNamespace(name, owner)
		if err != nil {
			fmt.Printf("[Error] %#v", err)
		}
	},
}

// listNamespaceCmd represents the user command
var listNamespaceCmd = &cobra.Command{
	Use:   "namespace",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {

		ns := models.Namespaces{}

		err := models.DB.All(&ns)
		if err != nil {
			fmt.Printf("[Error] %#v", err)
		}
		fmt.Println(ns)
	},
}

var syncNamespaceCmd = &cobra.Command{
	Use:   "namespace",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		client, err := kube.NewOutOfClusterClient(kubeconf)
		if err != nil {
			fmt.Printf("[Error] %#v", err)
		}

		missingFromCluster, missingFromDB, err := client.FindOutOfSyncNamespaces()
		if err != nil {
			fmt.Printf("[Error] %#v", err)
		}

		err = client.Sync(missingFromCluster, missingFromDB)
		if err != nil {
			fmt.Printf("[Error] %#v", err)
		}

	},
}

func init() {
	newCmd.AddCommand(newNamespaceCmd)
	listCmd.AddCommand(listNamespaceCmd)
	syncCmd.AddCommand(syncNamespaceCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// newNamespaceCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// newNamespaceCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
	newNamespaceCmd.Flags().StringVarP(&name, "name", "n", "", "Name of namespace")
	newNamespaceCmd.Flags().StringVarP(&owner, "owner", "o", "", "Owner UUID")

	newNamespaceCmd.MarkFlagRequired("name")
	newNamespaceCmd.MarkFlagRequired("owner")
}
