package migrations

import (
	"database/sql"
	"fmt"

	env "github.com/String-xyz/go-lib/v2/config"

	"github.com/String-xyz/migrations/config"
	"github.com/google/uuid"
	"github.com/pressly/goose/v3"
)

func init() {
	goose.AddMigration(Up00004, Down00004)
}

func Up00004(tx *sql.Tx) error {
	// Load environment variables
	err := env.LoadEnv(&config.Var)
	if err != nil {
		return err
	}

	// Insert networks
	query := `
		INSERT INTO network (name, network_id, chain_id, gas_oracle, rpc_url, explorer_url) VALUES
			('DFK Subnet', 1, 53935, 'avax', 'https://dfkchain.api.onfinality.io/public', 'https://subnets.avax.network/defi-kingdoms'),
			('DFK Testnet', 1, 335, 'avax', 'https://subnets.avax.network/defi-kingdoms/dfk-chain-testnet/rpc', 'https://subnets-test.avax.network/defi-kingdoms')
		RETURNING id;
		`

	rows, err := tx.Query(query)
	if err != nil {
		return err
	}
	defer rows.Close()

	var ids []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		err := rows.Scan(&id)
		if err != nil {
			return err
		}
		ids = append(ids, id)
	}
	if err := rows.Err(); err != nil {
		return err
	}

	query2 := fmt.Sprintf(`
		INSERT INTO asset (name, description, decimals, is_crypto, network_id, value_oracle, value_oracle_2) VALUES
		('JEWEL', 'DFK Jewel', 18, true, '%s', 'defi-kingdoms', NULL)
	`, ids[0])

	_, err = tx.Exec(query2)
	if err != nil {
		return err
	}

	// Update networks with gas_token_id
	updateStmt := `
		UPDATE network
		SET gas_token_id = (SELECT id FROM asset WHERE name = $1)
		WHERE name = $2;
	`
	updates := [2][2]string{
		{"JEWEL", "DFK Subnet"},
		{"JEWEL", "DFK Testnet"},
	}

	for _, update := range updates {
		_, err := tx.Exec(updateStmt, update[0], update[1])
		if err != nil {
			return err
		}
	}

	return nil
}

func Down00004(tx *sql.Tx) error {
	// This code is executed when the migration is rolled back.
	return nil
}
