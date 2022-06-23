#!/usr/bin/env bash
set -e


# Watch the queue for 5 minutes then fail if the queue isn't empty.
#
QUEUE_TIMEOUT_MINS=5
wait_until=$(date +'%l%M%S' -d "'${QUEUE_TIMEOUT_MINS} mins'")

# watch queue until it is empty
until [[ "${CURRENT_QUEUE_SIZE}" == "0" ]]; do
  CURRENT_QUEUE_SIZE=$(az servicebus queue show --resource-group "${SB_RESOURCE_GROUP}" \
      --namespace-name "${SERVICE_BUS}" \
      --name "${QUEUE_NAME}" \
      --subscription "${SUBSCRIPTION}" \
      --query countDetails.activeMessageCount -o tsv)
  echo "Current queue size: ${CURRENT_QUEUE_SIZE}"

  if [[ $(date +'%l%M%S') > ${wait_until} ]]; then
    echo "Queue isn't empty after ${QUEUE_TIMEOUT_MINS}, quitting..."
    exit 1
  else
    sleep 5
  fi

done

echo "${QUEUE_NAME} queue is now empty"


