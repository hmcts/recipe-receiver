#!/usr/bin/env bash
set -e

# Remove lock on resource group
echo "Removing lock"
get_lock() {
   az group lock list --subscription "${SUBSCRIPTION}" --resource-group "${SB_RESOURCE_GROUP}" --query '[].name' -o tsv | grep "${LOCK_NAME}"
}

az group lock delete --subscription "${SUBSCRIPTION}" --resource-group "${SB_RESOURCE_GROUP}" --name "${LOCK_NAME}"
delete_lock() {
  az group lock delete --subscription "${SUBSCRIPTION}" --resource-group "${SB_RESOURCE_GROUP}" --name "${LOCK_NAME}"
}
get_lock
delete_lock
sleep 60
until get_lock; do
  delete_lock
  sleep 60
done

echo "Lock deleted"

# Delete PR queue
az servicebus queue delete \
  --namespace-name "${SERVICE_BUS}" \
  --resource-group "${SB_RESOURCE_GROUP}" \
  --subscription "${SUBSCRIPTION}" \
  --name "${QUEUE_NAME}"

# Make sure queue has been deleted
count=3
until [[ $deleted == "true" ]] || [[ $count == 0 ]]; do
  if [[ ! $(az servicebus queue show --subscription "${SUBSCRIPTION}" --namespace-name "${SERVICE_BUS}" --resource-group "${SB_RESOURCE_GROUP}" --name "${QUEUE_NAME}") ]]; then
    deleted="true"
    echo "${QUEUE_NAME} queue has been deleted"
  elif [[ $count == 1 ]]; then
    echo "Problem deleting queue"
    exit 1
  else
    (( count-=1 ))
    sleep 5
  fi
done

# Recreate lock on resource group
echo "Recreating lock"
az group lock create --subscription "${SUBSCRIPTION}" --resource-group "${SB_RESOURCE_GROUP}" --name "${LOCK_NAME}" --lock-type CanNotDelete

