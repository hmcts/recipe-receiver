#!/usr/bin/env bash
set -e

# watch queue until it is empty
until [[ "${CURRENT_QUEUE_SIZE}" == "0" ]]; do
  CURRENT_QUEUE_SIZE=$(az servicebus queue show --resource-group "${SB_RESOURCE_GROUP}" \
      --namespace-name "${SERVICE_BUS}" \
      --name "${QUEUE_NAME}" \
      --subscription "${SUBSCRIPTION}" \
      --query countDetails.activeMessageCount -o tsv)
  echo "Current queue size: ${CURRENT_QUEUE_SIZE}"
  sleep 5
done

echo "${QUEUE_NAME} queue is now empty"