-------------------------------------------------------------------------
-- CONTRACT_TO_PLATFORM -------------------------------------------------
-- +goose Up
-- +goose StatementBegin
CREATE TABLE contract_to_platform (
	contract_id UUID REFERENCES contract (id),
	platform_id UUID REFERENCES platform (id)
);

CREATE UNIQUE INDEX contract_to_platform_contract_id_platform_id_idx ON contract_to_platform(contract_id, platform_id);
-------------------------------------------------------------------------
-- ALTER CONTRACT TABLE -------------------------------------------------
ALTER TABLE contract DROP COLUMN platform_id;
ALTER TABLE ADD COLUMN organization_id UUID REFERENCES organization (id);
-- Lets add a unique constraint so we can't have duplicates in the same network and organization
CREATE UNIQUE INDEX contract_address_network_id_org_id_idx ON contract(address,organization_id,network_id);
-- +goose StatementEnd

-------------------------------------------------------------------------
--         ______                         ____                    
--        / ____/___  ____  ________     / __ \____ _      ______ 
--       / / __/ __ \/ __ \/ ___/ _ \   / / / / __ \ | /| / / __ \
--      / /_/ / /_/ / /_/ (__  )  __/  / /_/ / /_/ / |/ |/ / / / /
--      \____/\____/\____/____/\___/  /_____/\____/|__/|__/_/ /_/ 
-------------------------------------------------------------------------  
-- +goose Down
-- +goose StatementBegin
DROP TABLE IF EXISTS contract_to_platform;
DROP INDEX IF EXISTS contract_address_network_id_org_id_idx;
ALTER TABLE contract DROP COLUMN organization_id;
ALTER TABLE contract ADD COLUMN platform_id UUID REFERENCES platform (id);
-- +goose StatementEnd
