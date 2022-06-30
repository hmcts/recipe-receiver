#!/usr/bin/env bash

CLOSED_PRS=$(curl -sS -H "Accept: application/vnd.github.v3+json" 'https://api.github.com/repos/hmcts/sds-recipe-receiver/pulls?state=closed' | jq '.[].number')
SCRIPT_DIR=$(dirname "${0}")

cd "${SCRIPT_DIR}"

echo $CLOSED_PRS

delete_release() {
  ./k8s.sh delete $1
}

queue() {
    ./cleanup-infra.sh "${1}"
}

for i in ${CLOSED_PRS}; do
  delete_release "recipe-receiver-pr-${i}"
  queue "recipes-pr${1}"
done

