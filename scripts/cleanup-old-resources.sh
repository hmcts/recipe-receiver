#!/usr/bin/env bash

CLOSED_PRS=$(curl -sS -H "Accept: application/vnd.github.v3+json" 'https://api.github.com/repos/hmcts/sds-recipe-receiver/pulls?state=closed' | jq '.[].number')
SCRIPT_DIR=$(dirname "${0}")

cd "${SCRIPT_DIR}"

for i in ${CLOSED_PRS}; do
  echo deleting "recipe-receiver-pr-${i}"
  ./k8s.sh delete "recipe-receiver-pr-${i}"
done

echo "./cleanup-infra.sh ${CLOSED_PRS}"
./cleanup-infra.sh "${CLOSED_PRS}"
