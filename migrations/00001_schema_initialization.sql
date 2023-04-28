-------------------------------------------------------------------------
-- +goose Up

-------------------------------------------------------------------------
-- create extension for UUID --------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-------------------------------------------------------------------------
-- UPDATE_UPDATED_AT_COLUMN() -------------------------------------------
-------------------------------------------------------------------------
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION update_updated_at_column()
	RETURNS TRIGGER AS
$$
BEGIN
	NEW.updated_at = now();
	RETURN NEW;
END;
$$ language 'plpgsql';
-- +goose StatementEnd
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- STRING_USER ----------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE string_user (
	id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
	created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	type TEXT NOT NULL, -- enum: to be defined at struct level in Go
	status TEXT NOT NULL, -- enum: to be defined at struct level in Go
	tags JSONB DEFAULT '{}'::JSONB, -- platforms should be listed in the tags
	first_name TEXT DEFAULT '', -- name in separate table?
	middle_name TEXT DEFAULT '',
	last_name TEXT DEFAULT ''
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_string_user_updated_at
	BEFORE UPDATE
	ON string_user
	FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- ORGANIZATION ---------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE organization (
  id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  activated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  name TEXT NOT NULL,
  description TEXT DEFAULT ''
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_organization_updated_at
  BEFORE UPDATE
  ON organization
  FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- PLATFORM -------------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE platform (
	id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
	created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	name TEXT NOT NULL DEFAULT '',
	description TEXT DEFAULT '',
	domains TEXT[] DEFAULT '{}'::TEXT[], -- define which domains can make calls to API (web-to-API)
	ip_addresses TEXT[] DEFAULT '{}'::TEXT[],
	organization_id UUID NOT NULL REFERENCES organization (id)
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_platform_updated_at
	BEFORE UPDATE
	ON platform
	FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- NETWORK --------------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE network (
	id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
	created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	name TEXT NOT NULL,
	network_id TEXT DEFAULT '', -- might actually be big.Int
	chain_id TEXT NOT NULL, -- might actually be big.Int
	gas_token_id TEXT DEFAULT '', -- INDEX CREATED BELOW
	gas_oracle TEXT DEFAULT '', -- the name of the network in oracle (i.e. in owlracle)
	rpc_url TEXT DEFAULT '', -- The RPC used to access the network (ie "https://mainnet.infura.io/v3")
	explorer_url TEXT DEFAULT '' -- The Block Explorer URL used to view transactions and entities in the browser
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_network_updated_at
	BEFORE UPDATE
	ON network
	FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- ASSET ----------------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE asset ( -- We will write sql commands to add/update these in bulk.
	id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
	created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
	name TEXT NOT NULL,
	description TEXT DEFAULT '',
	decimals INT DEFAULT 0,
	is_crypto BOOLEAN NOT NULL,
	network_id UUID REFERENCES network (id) DEFAULT NULL,
	value_oracle TEXT DEFAULT '', -- the name of the asset in oracle (i.e. in coingecko).  
	value_oracle_2 TEXT DEFAULT ''
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_asset_updated_at
	BEFORE UPDATE
	ON asset
	FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX network_gas_token_id_fk ON network (gas_token_id);
-- +goose StatementEnd

-------------------------------------------------------------------------
-- USER_TO_PLATFORM -----------------------------------------------------
-- +goose StatementBegin
CREATE TABLE user_to_platform (
  user_id UUID NOT NULL REFERENCES string_user (id),
  platform_id UUID NOT NULL REFERENCES platform (id)
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE UNIQUE INDEX user_to_platform_user_id_platform_id_idx ON user_to_platform(user_id, platform_id);
-- +goose StatementEnd

-------------------------------------------------------------------------
-- DEVICE ---------------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE device (
  id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_used_at TIMESTAMP WITH TIME ZONE NOT NULL,
  validated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  type TEXT DEFAULT '', -- enum: to be defined at struct level in Go
  description TEXT DEFAULT '',
  fingerprint TEXT DEFAULT '',
  ip_addresses TEXT[] DEFAULT '{}'::TEXT[],
  user_id UUID NOT NULL REFERENCES string_user (id)
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_device_updated_at
  BEFORE UPDATE
  ON device
  FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-- +goose StatementBegin
CREATE UNIQUE INDEX device_fingerprint_id_idx ON device(fingerprint, user_id);
-- +goose StatementEnd

-------------------------------------------------------------------------
-- CONTACT --------------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE contact (
  id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_authenticated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  validated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  type TEXT NOT NULL, -- enum: [phone, email, etc...] to be defined at struct level in Go
  status TEXT DEFAULT '', -- enum: [primary, inactive] to be defined at struct level in Go
  data TEXT DEFAULT '', -- the contact information
  user_id UUID NOT NULL REFERENCES string_user (id)
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_contact_updated_at
  BEFORE UPDATE
  ON contact
  FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- LOCATION -------------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE location (
  id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  type TEXT DEFAULT '',
  status TEXT NOT NULL, -- enum: 
  tags JSONB DEFAULT '{}'::JSONB,
  building_number TEXT DEFAULT '',
  unit_number TEXT DEFAULT '',
  street_name TEXT DEFAULT '',
  city TEXT DEFAULT '',
  state TEXT DEFAULT '',
  postal_code TEXT DEFAULT '',
  country TEXT DEFAULT '' -- ISO 3166-1 standard
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_location_updated_at
  BEFORE UPDATE
  ON location
  FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- INSTRUMENT -----------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE instrument (
  id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  type TEXT NOT NULL, -- enum:  includes crypto wallet
  status TEXT NOT NULL, -- enum: 
	name TEXT NOT NULL DEFAULT '',
  tags JSONB DEFAULT '{}'::JSONB,
  network TEXT NOT NULL, -- enum: 
  public_key TEXT DEFAULT '',
  last_4 TEXT DEFAULT '',
  user_id UUID REFERENCES string_user (id) DEFAULT NULL, -- instrument can be null in the circumstance that a user sends an asset to an unknown wallet
  location_id UUID REFERENCES location (id) DEFAULT NULL
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_instrument_updated_at
  BEFORE UPDATE
  ON instrument
  FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- CONTACT_TO_PLATFORM --------------------------------------------------
-- +goose StatementBegin
CREATE TABLE contact_to_platform (
  contact_id UUID NOT NULL REFERENCES contact (id),
  platform_id UUID NOT NULL REFERENCES platform (id)
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE UNIQUE INDEX contact_to_platform_contact_id_platform_id_idx ON contact_to_platform(contact_id, platform_id);
-- +goose StatementEnd

-------------------------------------------------------------------------
-- DEVICE_INSTRUMENT ----------------------------------------------------
-- +goose StatementBegin
CREATE TABLE device_to_instrument (
  device_id UUID NOT NULL REFERENCES device (id),
  instrument_id UUID NOT NULL REFERENCES instrument (id)
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE UNIQUE INDEX device_to_instrument_device_id_instrument_id_idx ON device_to_instrument(device_id, instrument_id);
-- +goose StatementEnd

-------------------------------------------------------------------------
-- TX_LEG ---------------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE tx_leg (
  id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(), -- unique identifier for the TX leg which we generate
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP, -- initial timestamp of creation
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP, -- timestamp whenever this tx_leg is updated
  deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  -- TIMESTAMP:
  -- For CC send = auth timestamp
  -- For CC receive = capture timestamp
  -- For EVM send = txid generation timestamp
  -- For EVM receive = txid confirmation timestamp 
  timestamp TIMESTAMP WITH TIME ZONE, 
  amount TEXT DEFAULT '', -- Quantity of financial asset in Asset wei
  value TEXT DEFAULT '', -- Quantity of financial asset in [USD wei (6 digits precision)]
  asset_id UUID REFERENCES asset (id), -- ID of table entry of Asset (for USD, ETH, AVAX etc)
  -- USER_ID:
  -- For CC send = id that correlates to the end-user in our user table
  -- For CC receive = id that correlates to the STRING entry in our user table
  -- For EVM send = id that correlates to the STRING entry in our user table
  -- For EVM receive = NULL if recipient is not an end user, or id that corrlates to end-user recipient in our user table
  user_id UUID REFERENCES string_user (id) DEFAULT NULL,
  -- INSTRUMENT_ID:
  -- For CC send = id that correlates to the users credit card in our Instrument table
  -- For CC receive = id that correlates to STRING bank account in our Instrument table
  -- For EVM send = id that correlates to our wallet address in our Instrument table
  -- For EVM receive = id that correlates to RECIPIENTS wallet in our Instrument table, regardless of if they are a user
  instrument_id UUID NOT NULL REFERENCES instrument (id)
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_tx_leg_updated_at
  BEFORE UPDATE
  ON tx_leg
  FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- TRANSACTION ----------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE transaction (
  id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(), -- unique idenfier for the transaction which we generate
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP, -- time transaction entry was initially created
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP, -- time transaction entry was last updated, including adding tags
  deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  type TEXT DEFAULT '', -- enum [fiat-to-crypto, crypto-to-fiat] (these types may eventually have subtypes, ie NFT_MINT)
  status TEXT DEFAULT '', --enum State of the transaction in the /transact endpoint
  tags JSONB DEFAULT '{}'::JSONB, -- Empty but will be used for Unit21.  These are key-val pairs for flagging transactions
  device_id UUID REFERENCES device (id), -- id that correlates to end-users device in our Device table, we get the data from fingerprint.com -- TODO: Get this with fingerprint integration
  ip_address TEXT DEFAULT '', -- we get this data from fingerprint.com, whatever is being used at time of transaction
  platform_id UUID REFERENCES platform (id), -- id that correlates to CUSTOMER in our Platform table (ie gamefi.xyz)
  transaction_hash TEXT DEFAULT '', -- EVM/network TX ID after it is generated by executor
  network_id UUID NOT NULL REFERENCES network (id), -- id that correlates to the Network (Chain) in our Network table
  network_fee TEXT DEFAULT '', -- The true amount of gas in wei that was used to facilitate the transaction
  contract_params TEXT[] DEFAULT NULL, -- The parameters passed into the EVM function call passed into the endpoint
  contract_func TEXT DEFAULT '', -- The declaration of the EVM function call passed into the endpoint
  transaction_amount TEXT DEFAULT '', -- The cost in native token wei of the transaction passed into the endpoint
  origin_tx_leg_id UUID REFERENCES tx_leg (id) DEFAULT NULL, -- id that correlates to the Leg of the CC send in our Leg table
  receipt_tx_leg_id UUID REFERENCES tx_leg (id) DEFAULT NULL, -- id that correlates to the Leg of the CC receive in our Leg table
  response_tx_leg_id UUID REFERENCES tx_leg (id) DEFAULT NULL, -- id that correlates to the leg of the EVM send in our Leg table
  destination_tx_leg_id UUID REFERENCES tx_leg (id) DEFAULT NULL, -- id that correlates to the leg of the EVM receive in our Leg table
  processing_fee TEXT DEFAULT '', -- CC (ie checkout) processing fee in (USD/???) wei
  processing_fee_asset UUID REFERENCES asset (id), -- CC processing fee asset id in asset table (ie id for USD)
  string_fee TEXT DEFAULT '', -- Amount in (USD!) wei that we charged to facilitate this transaction, likely always will be USD
  payment_code TEXT DEFAULT ''
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_transaction_updated_at
  BEFORE UPDATE
  ON transaction
  FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- ORGANIZATION_MEMBER --------------------------------------------------
-- +goose StatementBegin
CREATE TABLE organization_member (
  id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  email TEXT NOT NULL,
  password TEXT DEFAULT '', -- how do we maintain this?
  name TEXT DEFAULT ''
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_organization_member_updated_at
  BEFORE UPDATE
  ON organization_member
  FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- MEMBER_TO_ORGANIZATION -----------------------------------------------
-- +goose StatementBegin
CREATE TABLE member_to_organization (
  member_id UUID REFERENCES organization_member (id),
  organization_id UUID REFERENCES organization (id)
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE UNIQUE INDEX member_to_organization_member_id_organization_id_idx ON member_to_organization(member_id, organization_id);
-- +goose StatementEnd

-------------------------------------------------------------------------
-- MEMBER_ROLE ----------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE member_role (
  id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  name TEXT NOT NULL
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_member_role_updated_at
  BEFORE UPDATE
  ON member_role
  FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- MEMBER_TO_ROLE -------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE member_to_role (
  member_id UUID REFERENCES organization_member (id),
  role_id UUID REFERENCES member_role (id)
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE UNIQUE INDEX member_to_role_member_id_role_id_idx ON member_to_role(member_id, role_id);
-- +goose StatementEnd

-------------------------------------------------------------------------
-- MEMBER_INVITE --------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE member_invite (
  id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  expired_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  accepted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  email TEXT NOT NULL,
  name TEXT DEFAULT '',
  invited_by UUID REFERENCES organization_member (id) DEFAULT NULL,
  organization_id UUID NOT NULL REFERENCES organization (id),
  role_id UUID NOT NULL REFERENCES member_role (id)
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_member_invite_updated_at
  BEFORE UPDATE
  ON member_invite
  FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- APIKEY ---------------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE apikey (
  id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  type TEXT NOT NULL, -- [public,private] for now all public?
  data TEXT NOT NULL, -- the key itself
	hint TEXT DEFAULT '',
  description TEXT DEFAULT '',
  created_by UUID NOT NULL REFERENCES organization_member (id),
  platform_id UUID REFERENCES platform (id),
  organization_id UUID NOT NULL REFERENCES organization (id)
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_apikey_updated_at
  BEFORE UPDATE
  ON apikey
  FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
-- CONTRACT -------------------------------------------------------------
-- +goose StatementBegin
CREATE TABLE contract (
  id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deactivated_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
  name TEXT DEFAULT '',
  address TEXT NOT NULL,
  functions TEXT[] DEFAULT '{}'::TEXT[],
  network_id UUID NOT NULL REFERENCES network (id),
  platform_id UUID NOT NULL REFERENCES platform (id)
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE OR REPLACE TRIGGER update_contract_updated_at
  BEFORE UPDATE
  ON contract
  FOR EACH ROW
EXECUTE PROCEDURE update_updated_at_column();
-- +goose StatementEnd

-------------------------------------------------------------------------
--         ______                         ____                    
--        / ____/___  ____  ________     / __ \____ _      ______ 
--       / / __/ __ \/ __ \/ ___/ _ \   / / / / __ \ | /| / / __ \
--      / /_/ / /_/ / /_/ (__  )  __/  / /_/ / /_/ / |/ |/ / / / /
--      \____/\____/\____/____/\___/  /_____/\____/|__/|__/_/ /_/ 
-------------------------------------------------------------------------                                                           

-------------------------------------------------------------------------
-- +goose Down

-------------------------------------------------------------------------
-- CONTRACT -------------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS contract;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- APIKEY ---------------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS apikey;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- MEMBER_INVITE --------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS member_invite;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- MEMBER_TO_ROLE -------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS member_to_role;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- MEMBER_ROLE ----------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS member_role;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- MEMBER_TO_ORGANIZATION -----------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS member_to_organization;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- ORGANIZATION_MEMBER --------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS organization_member;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- TRANSACTION ----------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS transaction;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- TX_LEG ---------------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS tx_leg;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- DEVICE_TO_INSTRUMENT -------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS device_to_instrument;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- CONTACT_TO_PLATFORM --------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS contact_to_platform;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- INSTRUMENT -----------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS instrument;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- LOCATION -----------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS location;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- CONTACT --------------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS contact;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- DEVICE ---------------------------------------------------------------
-- +goose StatementBegin
DROP INDEX IF EXISTS device_fingerprint_id_idx;
-- +goose StatementEnd

-- +goose StatementBegin
DROP TABLE IF EXISTS device;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- USER_TO_PLATFORM -----------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS user_to_platform;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- ASSET ----------------------------------------------------------------
-- +goose StatementBegin
DROP INDEX IF EXISTS network_gas_token_id_fk;
-- +goose StatementEnd

-- +goose StatementBegin
DROP TABLE IF EXISTS asset;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- NETWORK --------------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS network;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- PLATFORM -------------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS platform;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- ORGANIZATION ---------------------------------------------------------
-- +goose StatementBegin
DROP TABLE organization;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- STRING_USER ----------------------------------------------------------
-- +goose StatementBegin
DROP TABLE IF EXISTS string_user;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- UPDATE_UPDATED_AT_COLUMN() -------------------------------------------
-- +goose StatementBegin
DROP FUNCTION IF EXISTS update_updated_at_column;
-- +goose StatementEnd

-------------------------------------------------------------------------
-- UUID EXTENSION -------------------------------------------------------
-- +goose StatementBegin
DROP EXTENSION IF EXISTS "uuid-ossp";
-- +goose StatementEnd