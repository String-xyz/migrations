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
	goose.AddMigration(Up00002, Down00002)
}

func Up00002(tx *sql.Tx) error {
	// Load environment variables
	err := env.LoadEnv(&config.Var)
	if err != nil {
		return err
	}

	// Insert networks
	query := `
		INSERT INTO network (name, network_id, chain_id, gas_oracle, rpc_url, explorer_url) VALUES
			('Polygon Mainnet', 137, 137, 'poly', 'https://rpc-mainnet.matic.quiknode.pro', 'https://polygonscan.com'),
			('Mumbai Testnet', 80001, 80001, 'poly', 'https://matic-mumbai.chainstacklabs.com', 'https://mumbai.polygonscan.com'),
			('Goerli Testnet', 5, 5, 'eth', 'https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161', 'https://goerli.etherscan.io'),
			('Ethereum Mainnet', 1, 1, 'eth', 'https://rpc.ankr.com/eth', 'https://etherscan.io'),
			('Fuji Testnet', 1, 43113, 'avax', 'https://api.avax-test.network/ext/bc/C/rpc', 'https://testnet.snowtrace.io'),
			('Avalanche Mainnet', 1, 43114, 'avax', 'https://api.avax.network/ext/bc/C/rpc', 'https://snowtrace.io'),
			('Nitro Goerli Rollup Testnet', 421613, 421613, 'arb', 'https://goerli-rollup.arbitrum.io/rpc', 'https://goerli.arbiscan.io'),
			('Arbitrum Nova Mainnet', 42170, 42170, 'arb', 'https://nova.arbitrum.io/rpc', 'https://nova-explorer.arbitrum.io'),
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
		('AVAX', 'Avalanche', 18, true, '%s', 'avalanche-2', 'avalanche'),
		('ETH', 'Ethereum', 18, true, '%s', 'ethereum', 'ethereum'),
		('MATIC', 'Matic', 18, true, '%s', 'matic-network', 'matic'),
		('GOERLIETH', 'Goerli Ethereum', 18, true, '%s', 'ethereum', 'ethereum'),
		('JEWEL', 'DFK Jewel', 18, true, '%s', 'defi-kingdoms', NULL),
		('USD', 'United States Dollar', 6, false, NULL, NULL, NULL);
	`, ids[0], ids[1], ids[2], ids[3], ids[4])

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
	updates := [10][2]string{
		{"MATIC", "Polygon Mainnet"},
		{"MATIC", "Mumbai Testnet"},
		{"ETH", "Goerli Testnet"},
		{"ETH", "Ethereum Mainnet"},
		{"AVAX", "Fuji Testnet"},
		{"AVAX", "Avalanche Mainnet"},
		{"GOERLIETH", "Nitro Goerli Rollup Testnet"},
		{"ETH", "Arbitrum Nova Mainnet"},
		{"JEWEL", "DFK Subnet"},
		{"JEWEL", "DFK Testnet"},
	}

	for _, update := range updates {
		_, err := tx.Exec(updateStmt, update[0], update[1])
		if err != nil {
			return err
		}
	}

	// Insert String User
	var stringUserId string
	row := tx.QueryRow(`INSERT INTO string_user (type, status) VALUES ('internal', 'internal') RETURNING id;`)
	if err := row.Scan(&stringUserId); err != nil {
		return err
	}

	// Set String User ID to what's defined in the ENV
	internalId := config.Var.STRING_INTERNAL_ID

	_, err = tx.Exec(`UPDATE string_user SET id = $1 WHERE id = $2;`, internalId, stringUserId)
	if err != nil {
		return err
	}

	// Insert Instrument Developer Card
	var bankStringId string
	row = tx.QueryRow(`INSERT INTO instrument (type, status, network, public_key, user_id) VALUES ('bank account', 'live', 'bankprov', '420481286', $1) RETURNING id;`, internalId)
	if err := row.Scan(&bankStringId); err != nil {
		return err
	}

	bankId := config.Var.STRING_BANK_ID

	_, err = tx.Exec(`UPDATE instrument SET id = $1 WHERE id = $2;`, bankId, bankStringId)
	if err != nil {
		return err
	}

	walletAddress := config.Var.STRING_HOTWALLET_ADDRESS

	// Insert Instrument Developer Wallet
	var walletStringId string
	row = tx.QueryRow(`INSERT INTO instrument (type, status, network, public_key, user_id) VALUES ('crypto wallet', 'internal', 'EVM', $1, $2) RETURNING id;`, walletAddress, internalId)
	if err := row.Scan(&walletStringId); err != nil {
		return err
	}

	walletId := config.Var.STRING_WALLET_ID

	_, err = tx.Exec(`UPDATE instrument SET id = $1 WHERE id = $2;`, walletId, walletStringId)
	if err != nil {
		return err
	}

	// Get environment variables
	memberId := config.Var.MEMBER_ROLE_MEMBER_ID
	adminId := config.Var.MEMBER_ROLE_ADMIN_ID
	ownerId := config.Var.MEMBER_ROLE_OWNER_ID

	// Insert "Member" role
	_, err = tx.Exec(`INSERT INTO member_role (id, name) VALUES ($1, $2);`, memberId, "Member")
	if err != nil {
		panic(err)
	}

	// Insert "Admin" role
	_, err = tx.Exec(`INSERT INTO member_role (id, name) VALUES ($1, $2);`, adminId, "Admin")
	if err != nil {
		panic(err)
	}

	// Insert "Owner" role
	_, err = tx.Exec(`INSERT INTO member_role (id, name) VALUES ($1, $2);`, ownerId, "Owner")
	if err != nil {
		panic(err)
	}

	return nil
}

func Down00002(tx *sql.Tx) error {
	// This code is executed when the migration is rolled back.
	return nil
}
