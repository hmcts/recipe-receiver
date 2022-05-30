#!/usr/bin/env bash

# Create queue for PR
# Fill up PR's service bus queue

SERVICE_BUS='sds-keda-stg-01'

QUEUE_NAME="$1"
QUEUE=$(az servicebus queue create --namespace-name sds-keda-stg-01 \
        --resource-group sds-keda-stg --name recipes-pr"${QUEUE_NAME}"  \
        --query name -o tsv)

SB_RESOURCE_GROUP='sds-keda-stg'
MESSAGES=200
SCRIPT_DIR=$(dirname "${0}")

cd "${SCRIPT_DIR}" || exit
../messageGenerator/recipe-sender "${SERVICE_BUS}.servicebus.windows.net" "${QUEUE}" "${MESSAGES}"

CURRENT_QUEUE_SIZE=$(az servicebus queue show --resource-group "${SB_RESOURCE_GROUP}" \
    --namespace-name "${SERVICE_BUS}" \
    --name "${QUEUE}" \
    --query countDetails.activeMessageCount
    )

echo "${CURRENT_QUEUE_SIZE}"