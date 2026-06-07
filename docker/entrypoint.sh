#!/usr/bin/env bash

set -euo pipefail

# Function helpers
function create_new_user(){
    groupadd -g "${DEMO_API_MAIN_SYSTEM_USER_ID}" "${DEMO_API_MAIN_SYSTEM_USER_NAME}"
    useradd -u "${DEMO_API_MAIN_SYSTEM_USER_ID}" -g "${DEMO_API_MAIN_SYSTEM_USER_ID}" -s /bin/bash -m "${DEMO_API_MAIN_SYSTEM_USER_NAME}"
    usermod -aG sudo "${DEMO_API_MAIN_SYSTEM_USER_NAME}"
    echo "${DEMO_API_MAIN_SYSTEM_USER_NAME}:${DEMO_API_MAIN_SYSTEM_USER_PASSWORD}" | chpasswd
}

# function unify_access_rights(){
#     local USER="${DEMO_API_MAIN_SYSTEM_USER_NAME}"
#     local GROUP="${DEMO_API_MAIN_SYSTEM_USER_NAME}"
#     # Changing the owner, excluding docker
#     find /app -path "/app/docker" -prune -o -exec chown "$USER":"$GROUP" {} +

#     # Changing access rights, excluding docker
#     find /app -path "/app/docker" -prune -o -exec chmod 775 {} +
# }
#===========================================================

# Create user and group for unifying file access rights on the host and in the container
if ! getent passwd "$DEMO_API_MAIN_SYSTEM_USER_NAME" > /dev/null ; then
    create_new_user
fi
#unify_access_rights

cd /app || exit 1

GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

echo -e "${YELLOW}Waiting for PostgreSQL...${ENDCOLOR}"

until pg_isready \
  -h "${DB_HOST:-demo-api-db-pg}" \
  -p "${DB_PORT:-5432}" \
  -U "${DB_USER:-app}" >/dev/null 2>&1
do
  sleep 1
done

echo -e "${YELLOW}Waiting for Redis...${ENDCOLOR}"

until redis-cli \
  -h "${REDIS_HOST:-demo-api-redis}" \
  ping >/dev/null 2>&1
do
  sleep 1
done

if [ -s ./docker/go/log/demo-api.log ]; then
    echo "" > ./docker/go/log/demo-api.log
fi

if find /app/migrations -name '*.up.sql' | grep -q .; then
    migrate \
        -path=/app/migrations \
        -database="$DEMO_API_DB_DSN" \
        up
else
    echo "No migrations found. Skipping."
fi

echo -e "${GREEN}+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++${ENDCOLOR}"
echo -e "${GREEN}+                     INSTALL DONE                            +${ENDCOLOR}"
echo -e "${GREEN}+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++${ENDCOLOR}"

echo -e "${GREEN}+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++${ENDCOLOR}"
echo -e "${GREEN}+                     Have a nice job :)                      +${ENDCOLOR}"
echo -e "${GREEN}+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++${ENDCOLOR}"

gosu "${DEMO_API_MAIN_SYSTEM_USER_NAME}" go build -o bin/demo-api ./cmd/demo-api
exec gosu "${DEMO_API_MAIN_SYSTEM_USER_NAME}" ./bin/demo-api