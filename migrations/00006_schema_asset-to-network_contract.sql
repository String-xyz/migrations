-- +goose Up
-------------------------------------------------------------------------
-- ALTER ASSET -----------------------------------------------------------
ALTER TABLE asset 
    ADD COLUMN network_id UUID,
    ADD COLUMN address TEXT;

-------------------------------------------------------------------------
-- RESTORE NETWORK_ID IN ASSET -------------------------------------------
WITH asset_network AS (
    SELECT asset_id, network_id
    FROM asset_to_network
)
UPDATE asset
SET network_id = asset_network.network_id
FROM asset_network
WHERE asset.id = asset_network.asset_id;

-------------------------------------------------------------------------
-- DROP ASSET_TO_NETWORK ------------------------------------------------
DROP TABLE IF EXISTS asset_to_network;

-------------------------------------------------------------------------
-- +goose Down
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- CREATE ASSET_TO_NETWORK AND MIGRATE DATA ------------------------------
CREATE TABLE asset_to_network (
	asset_id UUID REFERENCES asset (id),
	network_id UUID REFERENCES network (id)
);

INSERT INTO asset_to_network(asset_id, network_id)
    SELECT id, network_id
    FROM asset
    WHERE network_id IS NOT NULL;

-- ALTER ASSET -----------------------------------------------------------
ALTER TABLE asset 
	DROP COLUMN IF EXISTS network_id,
    DROP COLUMN IF EXISTS address;
