#!/bin/bash

echo "Creating new Forum Database"
psql -d postgres -c "drop database forum_db"
psql -d postgres -c "create database forum_db"

echo "Setting new schema"
psql -d forum_db -f ./db/create-schema.sql
psql -d forum_db -f ./db/populate-data.sql

echo "Finished Initialization"
