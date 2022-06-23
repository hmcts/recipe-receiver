#!/usr/bin/env bash
set -e

ACTION=$1

KUBECONFIG="${KUBECONFIG_PATH}"
KUBE_FILES="${GITHUB_WORKSPACE}"/recipe-receiver/
CHART_DIR="./charts/recipe-receiver"
RELEASE_NAME="${APP_NAME}-pr-${GITHUB_EVENT_NUMBER}"

## Set context
az aks get-credentials --subscription "${CLUSTER_SUB}" \
                       --resource-group "${CFT_CLUSTER_RESOURCE_GROUP}" \
                       --name "${CFT_CLUSTER_NAME}" \
                       --admin
#                       --file "${KUBECONFIG_PATH}" \


if [[ $ACTION == "deploy" ]]; then
  ## Deploy with Helm
  helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" -n "${KUBE_NAMESPACE}" \
      --set function.image:"${ACR_REPO}":pr-"${GITHUB_EVENT_NUMBER}" \
      --set function.environment.QUEUE:"${QUEUE_NAME}" \
      --set function.triggers[0].type:azure-servicebus \
      --set function.triggers[0].namespace:"${SERVICE_BUS}" \
      --set function.triggers[0].queueName:"${QUEUE_NAME}" \
      --set function.triggers[0].queueLength:5 --wait
elif [[ $ACTION == "delete" ]]; then
  helm uninstall "${RELEASE_NAME}" --wait
fi

