-- +goose Up

-------------------------------------------------------------------------
-- ASSET_TO_NETWORK -------------------------------------------------
CREATE TABLE asset_to_network (
	asset_id UUID REFERENCES asset (id),
	network_id UUID REFERENCES network (id),
    address TEXT DEFAULT ''
);

CREATE UNIQUE INDEX asset_to_network_asset_id_network_id_idx ON asset_to_network(asset_id, network_id);

-------------------------------------------------------------------------
-- MIGRATE DATA TO ASSET_TO_NETWORK -------------------------------------
INSERT INTO asset_to_network(asset_id, network_id)
    SELECT a.id, a.network_id
        FROM asset AS a
        WHERE a.network_id IS NOT NULL;

-------------------------------------------------------------------------
-- ALTER ASSET  ---------------------------------------------------------
ALTER TABLE asset 
    DROP CONSTRAINT asset_network_id_fkey,
	DROP COLUMN IF EXISTS network_id;

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
    ADD COLUMN network_id UUID REFERENCES network (id);

DROP TABLE IF EXISTS asset_to_network;
