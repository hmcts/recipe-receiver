#!/usr/bin/env bash

CLOSED_PRS=$(curl -sS -H "Accept: application/vnd.github.v3+json" 'https://api.github.com/repos/hmcts/sds-recipe-receiver/pulls?state=closed' | jq '.[].number')
SCRIPT_DIR=$(dirname "${0}")

cd "${SCRIPT_DIR}"

echo $CLOSED_PRS

delete_release() {
  ./k8s.sh delete $1
}

queue() {
     "${1}"
}

for i in ${CLOSED_PRS}; do
  ./k8s.sh delete "recipe-receiver-pr-${i}"
done

queue ./cleanup-infra.sh "${CLOSED_PRS}"
