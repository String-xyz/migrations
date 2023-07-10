package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	env "github.com/String-xyz/go-lib/v2/config"

	"github.com/String-xyz/migrations/config"
	_ "github.com/String-xyz/migrations/migrations"
	_ "github.com/lib/pq"
	"github.com/pressly/goose/v3"
)

var (
	flags = flag.NewFlagSet("goose", flag.ExitOnError)
	dir   = flags.String("dir", "./migrations", "directory with migration files")
)

func main() {
	flags.Parse(os.Args[1:])
	args := flags.Args()

	if len(args) < 1 {
		flags.Usage()
		return
	}

	command := args[0]

	// Load environment variables
	err := env.LoadEnv(&config.Var)
	if err != nil {
		return
	}

	dbUsername := config.Var.DB_USERNAME
	dbPassword := config.Var.DB_PASSWORD
	dbName := config.Var.DB_NAME
	dbHost := config.Var.DB_HOST
	sslMode := config.Var.SSL_MODE
	dbPort := config.Var.DB_PORT

	connectionString := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s", dbUsername, dbPassword, dbHost, dbPort, dbName, sslMode)

	db, err := goose.OpenDBWithDriver("postgres", connectionString)
	if err != nil {
		log.Fatalf("goose: failed to open DB: %v\n", err)
	}

	defer func() {
		if err := db.Close(); err != nil {
			log.Fatalf("goose: failed to close DB: %v\n", err)
		}
	}()

	arguments := []string{}
	if len(args) > 3 {
		arguments = append(arguments, args[3:]...)
	}

	if err := goose.Run(command, db, *dir, arguments...); err != nil {
		log.Fatalf("goose %v: %v", command, err)
	}
}
