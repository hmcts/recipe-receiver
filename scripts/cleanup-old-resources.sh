#!/usr/bin/env bash

CLOSED_PRS=$(curl -sS -H "Accept: application/vnd.github.v3+json" 'https://api.github.com/repos/hmcts/sds-recipe-receiver/pulls?state=closed' | jq '.[].number')
SCRIPT_DIR=$(dirname "${0}")

cd "${SCRIPT_DIR}"

echo "Delete Helm releases"
./k8s.sh delete ${CLOSED_PRS}

echo "Delete Queues"
./cleanup-infra.sh ${CLOSED_PRS}
