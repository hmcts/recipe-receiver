#!/usr/bin/env bash
set -e

ACTION=$1

KUBECONFIG="${KUBECONFIG_PATH}"
KUBE_FILES="${GITHUB_WORKSPACE}"/recipe-receiver/
CHART_DIR="./charts/recipe-receiver"
RELEASE_NAME="${APP_NAME}-pr-${GITHUB_EVENT_NUMBER}"

## Set context
az aks get-credentials --subscription "${CLUSTER_SUB}" \
                       --resource-group "${CLUSTER_RESOURCE_GROUP}" \
                       --name "${CLUSTER_NAME}" \
                       --admin

#                       --file "${KUBECONFIG_PATH}" \


if [[ $ACTION == "deploy" ]]; then

  helm dependency build "${CHART_DIR}"
  helm upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" -n "${KUBE_NAMESPACE}" \
      --set function.image:"${ACR_REPO}"=pr-"${GITHUB_EVENT_NUMBER}" \
      --set function.environment.QUEUE="${QUEUE_NAME}" \
      --set function.triggers[0].type=azure-servicebus \
      --set function.triggers[0].namespace="${SERVICE_BUS}" \
      --set function.triggers[0].queueName="${QUEUE_NAME}" \
      --set function.triggers[0].queueLength=5 --wait

elif [[ $ACTION == "delete" ]]; then

  helm uninstall -n "${KUBE_NAMESPACE}" "${RELEASE_NAME}" --wait

fi

