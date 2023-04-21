package migrations

import (
	"database/sql"
	"os"

	"github.com/pressly/goose/v3"
)

func init() {
	goose.AddMigration(Up00002, Down00002)
}

func Up00002(tx *sql.Tx) error {
	// Insert networks
	_, err := tx.Exec(`
		INSERT INTO network (name, network_id, chain_id, gas_oracle, rpc_url, explorer_url) VALUES
		('Polygon Mainnet', 137, 137, 'poly', 'https://rpc-mainnet.matic.quiknode.pro', 'https://polygonscan.com'),
		('Mumbai Testnet', 80001, 80001, 'poly', 'https://matic-mumbai.chainstacklabs.com', 'https://mumbai.polygonscan.com'),
		('Goerli Testnet', 5, 5, 'eth', 'https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161', 'https://goerli.etherscan.io'),
		('Ethereum Mainnet', 1, 1, 'eth', 'https://rpc.ankr.com/eth', 'https://etherscan.io'),
		('Fuji Testnet', 1, 43113, 'avax', 'https://api.avax-test.network/ext/bc/C/rpc', 'https://testnet.snowtrace.io'),
		('Avalanche Mainnet', 1, 43114, 'avax', 'https://api.avax.network/ext/bc/C/rpc', 'https://snowtrace.io'),
		('Nitro Goerli Rollup Testnet', 421613, 421613, 'arb', 'https://goerli-rollup.arbitrum.io/rpc', 'https://goerli.arbiscan.io'),
		('Arbitrum Nova Mainnet', 42170, 42170, 'arb', 'https://nova.arbitrum.io/rpc', 'https://nova-explorer.arbitrum.io');
	`)
	if err != nil {
		return err
	}

	// Insert assets
	_, err = tx.Exec(`
		INSERT INTO asset (name, description, decimals, is_crypto, network_id, value_oracle, value_oracle2) VALUES
		('AVAX', 'Avalanche', 18, true, 6, 'avalanche-2', 'avalanche'),
		('ETH', 'Ethereum', 18, true, 4, 'ethereum', 'ethereum'),
		('MATIC', 'Matic', 18, true, 1, 'matic-network', 'matic'),
		('GOERLIETH', 'Goerli Ethereum', 18, true, 7, 'ethereum', 'ethereum'),
		('USD', 'United States Dollar', 6, false, NULL, NULL, NULL);
	`)
	if err != nil {
		return err
	}

	// Update networks with gas_token_id
	updateStmt := `
		UPDATE network
		SET gas_token_id = (SELECT id FROM assets WHERE name = $1)
		WHERE name = $2;
	`
	updates := [8][2]string{
		{"MATIC", "Polygon Mainnet"},
		{"MATIC", "Mumbai Testnet"},
		{"ETH", "Goerli Testnet"},
		{"ETH", "Ethereum Mainnet"},
		{"AVAX", "Fuji Testnet"},
		{"AVAX", "Avalanche Mainnet"},
		{"GOERLIETH", "Nitro Goerli Rollup Testnet"},
		{"ETH", "Arbitrum Nova Mainnet"},
	}

	for _, update := range updates {
		_, err := tx.Exec(updateStmt, update[0], update[1])
		if err != nil {
			return err
		}
	}

	// Insert String User
	var stringUserId string
	row := tx.QueryRow(`INSERT INTO string-user (type, status) VALUES ('internal', 'internal') RETURNING id;`)
	if err := row.Scan(&stringUserId); err != nil {
		return err
	}

	// Set String User ID to what's defined in the ENV
	internalId := os.Getenv("STRING_INTERNAL_ID")
	if internalId == "" {
		panic("STRING_INTERNAL_ID is not set in ENV!")
	}

	_, err = tx.Exec(`UPDATE users SET id = $1 WHERE id = $2;`, internalId, stringUserId)
	if err != nil {
		return err
	}

	// Insert Instrument Developer Card
	var bankStringId string
	row = tx.QueryRow(`INSERT INTO instrument (type, status, network, public_key, user_id) VALUES ('bank account', 'live', 'bankprov', '420481286', $1) RETURNING id;`, internalId)
	if err := row.Scan(&bankStringId); err != nil {
		return err
	}

	bankId := os.Getenv("STRING_BANK_ID")
	if bankId == "" {
		panic("STRING_BANK_ID is not set in ENV!")
	}

	_, err = tx.Exec(`UPDATE instrument SET id = $1 WHERE id = $2;`, bankId, bankStringId)
	if err != nil {
		return err
	}

	walletAddress := os.Getenv("STRING_HOTWALLET_ADDRESS")
	if walletAddress == "" {
		panic("STRING_HOTWALLET_ADDRESS is not set in ENV!")
	}

	// Insert Instrument Developer Wallet
	var walletStringId string
	row = tx.QueryRow(`INSERT INTO instrument (type, status, network, public_key, user_id) VALUES ('crypto wallet', 'internal', 'EVM', $1, $2) RETURNING id;`, walletAddress, internalId)
	if err := row.Scan(&walletStringId); err != nil {
		return err
	}

	walletId := os.Getenv("STRING_WALLET_ID")
	if walletId == "" {
		panic("STRING_WALLET_ID is not set in ENV!")
	}

	_, err = tx.Exec(`UPDATE instrument SET id = $1 WHERE id = $2;`, walletId, walletStringId)
	if err != nil {
		return err
	}

	return nil
}

func Down00002(tx *sql.Tx) error {
	// This code is executed when the migration is rolled back.
	return nil
}
