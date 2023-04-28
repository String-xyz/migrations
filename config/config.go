package config

import (
	"os"
	"reflect"
	"strings"

	"github.com/joho/godotenv"
)

type vars struct {
	DB_NAME                  string
	DB_USERNAME              string
	DB_PASSWORD              string
	DB_HOST                  string
	DB_PORT                  string
	STRING_HOTWALLET_ADDRESS string
	STRING_INTERNAL_ID       string
	STRING_WALLET_ID         string
	STRING_BANK_ID           string
	MEMBER_ROLE_MEMBER_ID    string
	MEMBER_ROLE_ADMIN_ID     string
	MEMBER_ROLE_OWNER_ID     string
}

var Var vars

func LoadEnv(path ...string) error {
	var err error
	if len(path) > 0 {
		err = godotenv.Load(path[0])
	} else {
		err = godotenv.Load(".env")
	}
	if err != nil {
		return err
	}
	missing := []string{}
	stype := reflect.ValueOf(&Var).Elem()
	for i := 0; i < stype.NumField(); i++ {
		field := stype.Field(i)
		key := stype.Type().Field(i).Name
		value := os.Getenv(key)
		if value == "" {
			missing = append(missing, key)
		}
		field.SetString(value)
	}
	if len(missing) > 0 {
		panic("Missing environment variable: " + strings.Join(missing, ", "))
	}
	return nil
}
