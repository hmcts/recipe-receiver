#!/usr/bin/env bash
set -e

PR_NUMBER=$( echo "${QUEUE_NAME}" | cut -d "-" -f2)
LABEL="recipe-receiver-${PR_NUMBER}-function"

# Delete PR queue
az servicebus queue delete \
  --namespace-name "${SERVICE_BUS}" \
  --resource-group "${SB_RESOURCE_GROUP}" \
  --subscription "${SUBSCRIPTION}" \
  --name "${QUEUE_NAME}"

echo "${QUEUE_NAME} queue has been deleted"

# Delete kubernetes resources
kubectl delete triggerauthentications.keda.sh -n "${KUBE_NAMESPACE}" -l app.kubernetes.io/name="${LABEL}"
kubectl delete scaledjobs.keda.sh -n "${KUBE_NAMESPACE}" -l app.kubernetes.io/name="${LABEL}"