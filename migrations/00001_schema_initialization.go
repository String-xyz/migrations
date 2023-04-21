package migrations

import (
	"database/sql"

	"github.com/pressly/goose/v3"
)

func init() {
	goose.AddMigration(Up00001, Down00001)
}

func Up00001(tx *sql.Tx) error {
	sqlFile := "./00001_schema_initialization.sql"
	sql, err := Asset(sqlFile)
	if err != nil {
		return err
	}
	_, err = tx.Exec(string(sql))
	return err
}

func Down00001(tx *sql.Tx) error {
	_, err := tx.Exec(`DROP TABLE IF EXISTS users;`)
	return err
}
