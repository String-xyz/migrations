-- +goose Up

-------------------------------------------------------------------------
-- IDENTITY -------------------------------------------------------------
CREATE TABLE identity (
    id UUID PRIMARY KEY NOT NULL DEFAULT UUID_GENERATE_V4(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    level TEXT DEFAULT '' NOT NULL,
    account_id TEXT DEFAULT '' NOT NULL,
    user_id TEXT NOT NULL,
    email_verified TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    phone_verified TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    selfie_verified TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    document_verified TIMESTAMP WITH TIME ZONE DEFAULT NULL
);

CREATE OR REPLACE TRIGGER update_identity_updated_at 
    BEFORE UPDATE 
    ON identity 
    FOR EACH ROW 
EXECUTE PROCEDURE update_updated_at_column();

-------------------------------------------------------------------------
-- ALTER ASSET  ---------------------------------------------------------
ALTER TABLE asset 
    ADD COLUMN address TEXT DEFAULT '' NOT NULL;

-------------------------------------------------------------------------
-- ALTER CONTRACT TABLE -------------------------------------------------
ALTER TABLE contract 
	ADD COLUMN type TEXT NOT NULL;


-------------------------------------------------------------------------
--         ______                         ____                    
--        / ____/___  ____  ________     / __ \____ _      ______ 
--       / / __/ __ \/ __ \/ ___/ _ \   / / / / __ \ | /| / / __ \
--      / /_/ / /_/ / /_/ (__  )  __/  / /_/ / /_/ / |/ |/ / / / /
--      \____/\____/\____/____/\___/  /_____/\____/|__/|__/_/ /_/ 
-------------------------------------------------------------------------  
-- +goose Down

-------------------------------------------------------------------------
-- ALTER CONTRACT TABLE -------------------------------------------------
ALTER TABLE contract 
	DROP COLUMN IF EXISTS type;

ALTER TABLE asset 
    DROP COLUMN IF EXISTS address;

DROP TABLE IF EXISTS identity;