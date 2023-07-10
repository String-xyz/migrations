package config

type vars struct {
	DB_NAME                  string `required:"true"`
	DB_USERNAME              string `required:"true"`
	DB_PASSWORD              string `required:"true"`
	DB_HOST                  string `required:"true"`
	DB_PORT                  string `required:"true"`
	STRING_HOTWALLET_ADDRESS string `required:"true"`
	STRING_INTERNAL_ID       string `required:"true"`
	STRING_WALLET_ID         string `required:"true"`
	STRING_BANK_ID           string `required:"true"`
	MEMBER_ROLE_MEMBER_ID    string `required:"true"`
	MEMBER_ROLE_ADMIN_ID     string `required:"true"`
	MEMBER_ROLE_OWNER_ID     string `required:"true"`
	SSL_MODE                 string `required:"true"`
}

var Var vars
