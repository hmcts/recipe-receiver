#!/usr/bin/env bash
#set -e

QUEUES=$@

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

for i in ${QUEUES}; do
  QUEUE="recipes-pr${i}"

  # Delete queue
  count=3
  if [[ ! $(az servicebus queue show --subscription "${SUBSCRIPTION}" --namespace-name "${SERVICE_BUS}" --resource-group "${SB_RESOURCE_GROUP}" --name "${QUEUE}" 2> /dev/null ) ]]; then
    # Not found, do nothing
    continue
  else
   echo "Working on deleting ${QUEUE}"
    # Delete if queue exists
    if [[ ${count} == 3 ]]; then
      az servicebus queue delete \
        --namespace-name "${SERVICE_BUS}" \
        --resource-group "${SB_RESOURCE_GROUP}" \
        --subscription "${SUBSCRIPTION}" \
        --name "${QUEUE}"
    fi


    until [[ ${deleted} == "true" ]] || [[ ${count} == 0 ]]; do
      if [[ ! $(az servicebus queue show --subscription "${SUBSCRIPTION}" --namespace-name "${SERVICE_BUS}" --resource-group "${SB_RESOURCE_GROUP}" --name "${QUEUE}" 2> /dev/null) ]]; then
        deleted="true"
        echo "${QUEUE} queue has been deleted"

      elif [[ ${count} == 1 ]]; then
        echo "Problem deleting queue: ${QUEUE}"
        exit 1
      else
        (( count-=1 ))
        sleep 5
      fi

    done
  fi
done

# Recreate lock on resource group
echo "Recreating lock"
az group lock create --subscription "${SUBSCRIPTION}" --resource-group "${SB_RESOURCE_GROUP}" --name "${LOCK_NAME}" --lock-type CanNotDelete

