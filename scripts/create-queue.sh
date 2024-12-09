#!/usr/bin/env bash

set -e

MESSAGES=1000
SCRIPT_DIR=$(dirname "${0}")

# Create queue for pr
QUEUE=$( az servicebus queue create --namespace-name "${SERVICE_BUS}" \
  --resource-group "${SB_RESOURCE_GROUP}" \
  --name "${QUEUE_NAME}" \
  --subscription "${SUBSCRIPTION}" \
  --query name -o tsv )

echo "Queue created: $QUEUE"

cd "${SCRIPT_DIR}" || exit

# Fill up PR's service bus queue
echo ::group::Generate Messages
go run ../messageGenerator/main.go -service-bus="${SERVICE_BUS}.servicebus.windows.net" -queue="${QUEUE_NAME}" -messages="${MESSAGES}"
echo ::endgroup::

CURRENT_QUEUE_SIZE=$(az servicebus queue show --resource-group "${SB_RESOURCE_GROUP}" \
    --namespace-name "${SERVICE_BUS}" \
    --name "${QUEUE_NAME}" \
    --subscription "${SUBSCRIPTION}" \
    --query countDetails.activeMessageCount
    )
echo "Current queue size: ${CURRENT_QUEUE_SIZE}"
