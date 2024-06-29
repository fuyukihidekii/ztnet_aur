#!/usr/bin/env bash

# Enable error detection
set -e

# Disable debug tracing on "production" release
# set -x  ( DEBUG )

error_detector() {
    echo "An error occurred. Exiting..."
    exit 1
}

# Trap errors
trap error_detector ERR

# Generate a 32-character token
ztn_token() {
    head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32
}

# Update or append new variables from service environment
ztn_env_vars_handler() {
    local key="$1"
    local value="$2"

    # Check if the key already exists in .env file
    if grep -q "^$key=" "$ZTN_ENV_VARS"; then
        # If the key exists, update its value
        sed -i "s#^$key=.*#$key=$value#" "$ZTN_ENV_VARS"
    else
        # Otherwise, if the key doesn't exist, append it
        echo "$key=$value" >> "$ZTN_ENV_VARS"
    fi

    # Set secure permission to the .env file
    chmod 600 "$ZTN_ENV_VARS"
}

# .env file
ZTN_ENV_VARS=".env"

# Check if .token file exists, create if not, and set secure permission.
TOKEN_FILE=".token"
if [ ! -f "$TOKEN_FILE" ]; then
    ztn_token > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
fi

# Set NEXTAUTH_SECRET from .token file
NEXTAUTH_SECRET=$(cat "$TOKEN_FILE")

# Ensure required environment variables are set
: "${POSTGRES_USER:?POSTGRES_USER must be set in the systemd service unit}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD must be set in the systemd service unit.}"
: "${POSTGRES_HOST:?POSTGRES_HOST must be set in the systemd service unit.}"
: "${POSTGRES_PORT:?POSTGRES_PORT must be set in the systemd service unit.}"
: "${POSTGRES_DB:?POSTGRES_DB must be set in the systemd service unit.}"
: "${ZT_ADDR:?ZT_ADDR must be set in the systemd service unit.}"
: "${NEXT_PUBLIC_APP_VERSION:?NEXT_PUBLIC_APP_VERSION must be set in the systemd service unit.}"

# Check if .env file exists
if [ ! -f "$ZTN_ENV_VARS" ]; then
    echo "Creating .env file..."

    # Populate .env file with variables from systemd service environment
    {
        echo "DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}?schema=public"
        echo "ZT_ADDR=${ZT_ADDR}"
        echo "NEXT_PUBLIC_APP_VERSION=${NEXT_PUBLIC_APP_VERSION}"
        echo "NEXTAUTH_SECRET=${NEXTAUTH_SECRET}"
    } > "$ZTN_ENV_VARS"

    # Set permissions to 0600
    chmod 600 "$ZTN_ENV_VARS"

    echo ".env file created"
else
    # Always update variables in .env file
    echo ".env file already exists. Updating variables..."

    ztn_env_vars_handler DATABASE_URL "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}?schema=public"
    ztn_env_vars_handler ZT_ADDR "${ZT_ADDR}"
    ztn_env_vars_handler NEXT_PUBLIC_APP_VERSION "${NEXT_PUBLIC_APP_VERSION}"
    ztn_env_vars_handler NEXTAUTH_SECRET "${NEXTAUTH_SECRET}"

    echo "Variables updated in .env file"
fi

# Take command-line args from systemd service environment
cmd="$@"

# Wait for the database be avaliable
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\q'; do
  echo "Postgres is unavailable - sleeping"
  sleep 1
done

# Apply migrations to the database
echo "Prisma: Applying migrations to the database..."
npx prisma migrate deploy
echo "Prisma: Migrations applied successfully!"

# Seed the database
echo "Prisma: Seeding the database..."
npx prisma db seed
echo "Prisma: Database seeded successfully!"

# Execute ZTNET with command-line from the systemd service environment
echo "Initialising ZTNET ${NEXT_PUBLIC_APP_VERSION}"
exec $cmd
