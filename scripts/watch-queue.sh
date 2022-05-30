#!/usr/bin/env bash
set -e

# watch queue until it is empty
SERVICE_BUS='sds-keda-stg-01'
QUEUE_NAME="$1"
SB_RESOURCE_GROUP='sds-keda-stg'

until [[ "${CURRENT_QUEUE_SIZE}" == "0" ]]; do
  CURRENT_QUEUE_SIZE=$(az servicebus queue show --resource-group "${SB_RESOURCE_GROUP}" \
      --namespace-name "${SERVICE_BUS}" \
      --name "${QUEUE_NAME}" \
      --query countDetails.activeMessageCount -o tsv)
  echo "Current queue size: ${CURRENT_QUEUE_SIZE}"
done

echo "${QUEUE_NAME} queue is now empty"