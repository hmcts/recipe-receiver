#!/usr/bin/env bash

set -e

# Create queue for PR
# Fill up PR's service bus queue

#SERVICE_BUS='sds-keda-stg-01'
#QUEUE_NAME="$1"
#SB_RESOURCE_GROUP='sds-keda-stg'
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

go run ../messageGenerator/main.go "${SERVICE_BUS}.servicebus.windows.net" "${QUEUE_NAME}" "${MESSAGES}"

CURRENT_QUEUE_SIZE=$(az servicebus queue show --resource-group "${SB_RESOURCE_GROUP}" \
    --namespace-name "${SERVICE_BUS}" \
    --name "${QUEUE_NAME}" \
    --subscription "${SUBSCRIPTION}" \
    --query countDetails.activeMessageCount
    )
echo "Current queue size: ${CURRENT_QUEUE_SIZE}"