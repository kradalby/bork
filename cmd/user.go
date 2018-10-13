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

	"github.com/kradalby/bork/models"
	"github.com/spf13/cobra"
)

var admin bool
var active bool

var username string
var email string
var firstname string
var lastname string

// newUserCmd represents the user command
var newUserCmd = &cobra.Command{
	Use:   "user",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {

		user := models.User{
			Username:  username,
			FirstName: firstname,
			LastName:  lastname,
			Email:     email,
			IsAdmin:   admin,
			IsActive:  active,
		}
		fmt.Println(user)

		err := models.DB.Create(&user)
		if err != nil {
			fmt.Printf("[Error] %#v", err)
		}
	},
}

// listUserCmd represents the user command
var listUserCmd = &cobra.Command{
	Use:   "user",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {

		users := models.Users{}

		err := models.DB.All(&users)
		if err != nil {
			fmt.Printf("[Error] %#v", err)
		}
		fmt.Println(users)
	},
}

func init() {
	newCmd.AddCommand(newUserCmd)
	listCmd.AddCommand(listUserCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// newUserCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	newUserCmd.Flags().BoolVarP(&admin, "admin", "s", false, "Administrator")
	newUserCmd.Flags().BoolVarP(&active, "active", "a", true, "Activate")

	newUserCmd.Flags().StringVarP(&username, "username", "u", "", "Username")
	newUserCmd.Flags().StringVarP(&email, "email", "e", "", "Email")
	newUserCmd.Flags().StringVarP(&firstname, "firstname", "f", "", "First name")
	newUserCmd.Flags().StringVarP(&lastname, "lastname", "l", "", "Last name")

	newUserCmd.MarkFlagRequired("username")
	newUserCmd.MarkFlagRequired("email")
	newUserCmd.MarkFlagRequired("firstname")
	newUserCmd.MarkFlagRequired("lastname")
}
