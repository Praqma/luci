#! /bin/bash

# /config is supposed to be mounted, and contain custom init files
for file in /config/*.sh; do
    source "$file"
done

checkEnvDefined() {
    [ $(eval echo \$$1) ] || (echo "ERROR: $1 not defined" ; exit 1)
}

# The init files in /config must define the following env vars
checkEnvDefined ZETTA_DOMAIN_NAME
checkEnvDefined ZETTA_DOMAIN_ID
checkEnvDefined ZETTA_USERNAME
checkEnvDefined ZETTA_PASSWORD

export OS_AUTH_URL=https://identity.api.zetta.io/v3
export OS_REGION_NAME="no-osl1"
export OS_PROJECT_NAME=${ZETTA_PROJECT_NAME:-Standard}
export OS_IDENTITY_API_VERSION="3"

export OS_PROJECT_DOMAIN_ID=$ZETTA_DOMAIN_ID
export OS_USER_DOMAIN_ID=$ZETTA_DOMAIN_ID

export OS_USERNAME=$ZETTA_USERNAME
export OS_PASSWORD=$ZETTA_PASSWORD

export OS_TENANT_NAME=$OS_PROJECT_NAME

export ZETTA_FLAVOR_ID=${ZETTA_FLAVOR_ID:-6}

exec "$@"
