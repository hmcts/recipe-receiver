#!/usr/bin/env bash

set -e

# Create queue for PR
# Fill up PR's service bus queue

SERVICE_BUS='sds-keda-stg-01'
QUEUE_NAME="$1"
SB_RESOURCE_GROUP='sds-keda-stg'
MESSAGES=200
SCRIPT_DIR=$(dirname "${0}")

az account set --subscription 74dacd4f-a248-45bb-a2f0-af700dc4cf68
# Create queue for pr
QUEUE=$(az servicebus queue create --namespace-name sds-keda-stg-01 \
        --resource-group sds-keda-stg --name "${QUEUE_NAME}"  \
        --query name -o tsv)

cd "${SCRIPT_DIR}" || exit
go run ../messageGenerator/main.go "${SERVICE_BUS}.servicebus.windows.net" "${QUEUE}" "${MESSAGES}"

CURRENT_QUEUE_SIZE=$(az servicebus queue show --resource-group "${SB_RESOURCE_GROUP}" \
    --namespace-name "${SERVICE_BUS}" \
    --name "${QUEUE_NAME}" \
    --query countDetails.activeMessageCount
    )

echo "${CURRENT_QUEUE_SIZE}"