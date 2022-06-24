#!/usr/bin/env bash
set -e

ACTION=$1

KUBECONFIG="${KUBECONFIG_PATH}"
KUBE_FILES="${GITHUB_WORKSPACE}"/recipe-receiver/
CHART_DIR="./charts/recipe-receiver"
RELEASE_NAME="${APP_NAME}-pr-${GITHUB_EVENT_NUMBER}"
ACR_REPO=${REGISTRY_NAME}.azurecr.io/${PRODUCT}/${APP_NAME}

## Set context
az aks get-credentials --subscription "${CLUSTER_SUB}" \
                       --resource-group "${CLUSTER_RESOURCE_GROUP}" \
                       --name "${CLUSTER_NAME}" \
                       --admin

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
  echo "Helm list: $(helm -n "${KUBE_NAMESPACE}" list)"
  echo "Helm list filter: $(helm list -n "${KUBE_NAMESPACE}" --short --filter ${RELEASE_NAME})"
  if [[ $(helm list -n "${KUBE_NAMESPACE}" --short --filter "${RELEASE_NAME}" ) != "" ]]; then
    echo "Deleting release ${RELEASE_NAME}"
    helm uninstall -n "${KUBE_NAMESPACE}" "${RELEASE_NAME}" --wait

  fi
fi

