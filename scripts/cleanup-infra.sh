#!/usr/bin/env bash
set -e

get_lock() {
   az group lock list --subscription "${SUBSCRIPTION}" --resource-group "${SB_RESOURCE_GROUP}" --query '[].name' -o tsv | grep "${LOCK_NAME}"
}

if get_lock; then
  for (( i=0; i<=2; i++ )); do
    echo "Locks in place: $(get_lock)"

    # Remove lock on resource group
    echo "Removing lock"
    az group lock delete --subscription "${SUBSCRIPTION}" --resource-group "${SB_RESOURCE_GROUP}" --name "${LOCK_NAME}"

    if ! get_lock; then
      break
    fi
    sleep 10
  done
fi

echo "Lock deleted"

echo "Delete PR queue"
az servicebus queue delete \
  --namespace-name "${SERVICE_BUS}" \
  --resource-group "${SB_RESOURCE_GROUP}" \
  --subscription "${SUBSCRIPTION}" \
  --name "${1}"

# Make sure queue has been deleted
count=3
until [[ $deleted == "true" ]] || [[ $count == 0 ]]; do
  if [[ ! $(az servicebus queue show --subscription "${SUBSCRIPTION}" --namespace-name "${SERVICE_BUS}" --resource-group "${SB_RESOURCE_GROUP}" --name "${1}") ]]; then
    deleted="true"
    echo "${1} queue has been deleted"
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

