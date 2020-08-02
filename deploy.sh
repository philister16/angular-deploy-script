#!/usr/bin/env bash

## Important note: this script is called from the root thus all processing of local files must be thought of accordingly

echo "[STARTING] Starting deployment tasks"

# Environment setups

PROJECT_NAME="my-app"

## Test
TEST_SSH="user@domain.com"
TEST_BASE="/app/path"
TEST_SERVER="/server/path/to/app"

## Production
PROD_SSH="user@domain.com"
PROD_BASE="/app/path"
PROD_SERVER="/server/path/to/app"

if [ "$1" = "production" ]; then
    TARGET_BASE=$PROD_BASE
    TARGET_SERVER=$PROD_SERVER
    TARGET_SSH=$PROD_SSH
else
    TARGET_BASE=$TEST_BASE
    TARGET_SERVER=$TEST_SERVER
    TARGET_SSH=$TEST_SSH
fi

echo "[TARGET] Deploying to ${TARGET_SERVER}" &&

# Build project
ng build --prod --build-optimizer --baseHref=$TARGET_BASE --deployUrl=$TARGET_BASE &&
echo "[SUCCESS] Build ran successfully" &&

# Generate .htaccess
echo "RewriteEngine On
# If an existing asset or directory is requested go to it as it is
RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI} -f [OR]
RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI} -d
RewriteRule ^ - [L]

# If the requested resource doesn't exist, use index.html
RewriteRule ^ ${TARGET_BASE}index.html" >> "./dist/${PROJECT_NAME}/.htaccess" &&
echo "[SUCCESS] Created .htaccess file" &&

# # Remove old files
ssh $TARGET_SSH "rm -rfv ${TARGET_SERVER}" &&

# # Replicate new build to server
rsync -azP --exclude={'.DS_Store'} "./dist/${PROJECT_NAME}/" "${TARGET_SSH}:${TARGET_SERVER}" &&

echo "[DEPLOYED] Project deployed successfully. Check here ${TARGET_BASE}."