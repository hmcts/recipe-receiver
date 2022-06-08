#!/usr/bin/env bash
set -e

# PR / prod
BUILD=$1
REGISTRY_SUB="8999dec3-0104-4a27-94ee-6588559729d1"

if [[ ${GITHUB_SHA} == "" ]]; then
  echo "No sha found"
  exit 1
fi

if [[ ${BUILD} =~ ^pr-* ]]; then

  docker build . -t "${REGISTRY_NAME}.azurecr.io/${APP_NAME}:${BUILD}"
  docker push "${REGISTRY_NAME}.azurecr.io/${APP_NAME}:${BUILD}"

elif [[ ${BUILD} == "prod" ]]; then

  TAG="prod-$(git show --no-patch --no-notes --pretty=format:"%h-%ad" --date=format:'%Y%m%d%H%M%S' "${GITHUB_SHA}")"
  REPO="${REGISTRY_NAME}.azurecr.io/${APP_NAME}"
  az acr import --force -n "${REGISTRY_NAME}" --subscription "${REGISTRY_SUB}" --source "${REPO}/pr-${GITHUB_EVENT_NUMBER}" -t "${REPO}/${TAG}"

fi