#!/usr/bin/env bash

ACTION=$1

KUBECONFIG="${KUBECONFIG_PATH}"
KUBE_FILES="${GITHUB_WORKSPACE}"/recipe-receiver/
CHART_DIR="./charts/recipe-receiver"
RELEASE_NAME="${APP_NAME}-pr-${GITHUB_EVENT_NUMBER}"
ACR_REPO=${REGISTRY_NAME}.azurecr.io/${PRODUCT}/${APP_NAME}
AKS_LOG_FILE="./aks-auth-logs"

## Set context
get_creds() {
  az aks get-credentials --subscription "${CLUSTER_SUB}" \
                         --resource-group "${AKS_PROJECT}-${AKS_ENV}-${1}-rg" \
                         --name "${AKS_PROJECT}-${AKS_ENV}-${1}-aks" \
                         --admin
}

# Try getting Cluster 00 creds first then 01. Fail if problems with both
get_creds 00 2> "${AKS_LOG_FILE}" || get_creds 01 2> "${AKS_LOG_FILE}" || ( echo "Failed to authenticate after trying both clusters. Errors below." && cat "${AKS_LOG_FILE}"&& exit 1)


set -e

if [[ ${ACTION} == "deploy" ]]; then

  helm repo add function https://hmctspublic.azurecr.io/helm/v1/repo
  helm dependency build "${CHART_DIR}"

  helm upgrade -f "${CHART_DIR}/values-${PROJECT}.yaml" --install "${RELEASE_NAME}" "${CHART_DIR}" -n "${KUBE_NAMESPACE}" \
      --set function.image="${ACR_REPO}":pr-"${GITHUB_EVENT_NUMBER}" \
      --set function.environment.QUEUE="${QUEUE_NAME}" \
      --set function.environment.FULLY_QUALIFIED_NAMESPACE="${SERVICE_BUS}.servicebus.windows.net" \
      --set function.triggers[0].type=azure-servicebus \
      --set function.triggers[0].namespace="${SERVICE_BUS}" \
      --set function.triggers[0].queueName="${QUEUE_NAME}" \
      --set function.triggers[0].queueLength=5 \
      --wait

elif [[ ${ACTION} == "delete" ]]; then
  # Delete helm release if it exists
  if [[ $(helm list -n "${KUBE_NAMESPACE}" --short --filter "${RELEASE_NAME}" ) != "" ]]; then
    echo "Deleting release ${RELEASE_NAME}"
    helm uninstall -n "${KUBE_NAMESPACE}" "${RELEASE_NAME}" --wait

  fi
fi

