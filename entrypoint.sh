#!/bin/sh

# export env variables from .env file
export $(grep -v '^#' .env | xargs)

if [ "$IGNORE_DB" = "false" ]; then
  # run db migrations
  echo "----- Running migrations..."
  cd migrations

  DB_CONFIG="host=$DB_HOST user=$DB_USERNAME dbname=$DB_NAME sslmode=disable password=$DB_PASSWORD"
  goose postgres "$DB_CONFIG" reset
  goose postgres "$DB_CONFIG" up
  cd ..
  echo "----- ...Migrations done"
fi