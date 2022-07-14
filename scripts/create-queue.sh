#!/usr/bin/env bash

set -ex

MESSAGES=100
SCRIPT_DIR=$(dirname "${0}")

# Create queue for pr
QUEUE=$( az servicebus queue create --namespace-name "${SERVICE_BUS}" \
  --resource-group "${SB_RESOURCE_GROUP}" \
  --name "${QUEUE_NAME}" \
  --subscription "${SUBSCRIPTION}" \
  --query name -o tsv )

echo "Queue created: $QUEUE"

cd "${SCRIPT_DIR}"/../messageGenerator || exit

# Build app - testing as go run seems to not run properly in the gh action
go build -o recipe-sender main.go

# Fill up PR's service bus queue
echo ::group::Send Recipes

./recipe-sender -service-bus="${SERVICE_BUS}.servicebus.windows.net" -queue="${QUEUE_NAME}" -messages="${MESSAGES}"

echo ::endgroup::

CURRENT_QUEUE_SIZE=$(az servicebus queue show --resource-group "${SB_RESOURCE_GROUP}" \
    --namespace-name "${SERVICE_BUS}" \
    --name "${QUEUE_NAME}" \
    --subscription "${SUBSCRIPTION}" \
    --query countDetails.activeMessageCount
    )
echo "Current queue size: ${CURRENT_QUEUE_SIZE}"
