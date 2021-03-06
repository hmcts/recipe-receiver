#!/usr/bin/env bash
set -e

# PR / prod
BUILD=$1

ACR_REPO=${REGISTRY_NAME}.azurecr.io/${PRODUCT}/${APP_NAME}

if [[ ${BUILD} =~ ^pr-.* ]]; then
  docker build . -t "${ACR_REPO}:${BUILD}"
  docker push "${ACR_REPO}:${BUILD}"

elif [[ ${BUILD} == "prod" ]]; then
  TAG="prod-$(git show --no-patch --no-notes --pretty=format:"%h-%ad" --date=format:'%Y%m%d%H%M%S' "${GITHUB_SHA}")"
  echo "Promoting ${ACR_REPO}:pr-${GITHUB_EVENT_NUMBER} to ${ACR_REPO}:${TAG}"
  az acr import --force -n "${REGISTRY_NAME}" --subscription "${REGISTRY_SUB}" --source "${ACR_REPO}:pr-${GITHUB_EVENT_NUMBER}" -t "${PRODUCT}/${APP_NAME}:${TAG}"

else
  echo "Build type not recognised, use pr-{pr_number} or prod"
  exit 1
fi
