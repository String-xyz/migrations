#!/bin/sh

# export env variables from .env file
export $(grep -v '^#' .env | xargs)
echo $(pwd)
echo $(ls -a)

# run db migrations
echo "----- Building migrations..."
# can't build from inside the container yet
go build -o migrations/goose-migrate cmd/main.go
echo "----- Running migrations..."
# cd migrations
./migrations/goose-migrate reset
./migrations/goose-migrate up
# DB_CONFIG="host=$DB_HOST user=$DB_USERNAME dbname=$DB_NAME sslmode=disable password=$DB_PASSWORD"
# goose postgres "$DB_CONFIG" reset
# goose postgres "$DB_CONFIG" up
# cd ..
echo "----- ...Migrations done"
