#!/usr/bin/env bash
set -euo pipefail

# Prevent Windows Git Bash from modifying Azure resource IDs.
export MSYS_NO_PATHCONV=1

# Require values supplied by the workflow.
: "${RESOURCE_GROUP:?RESOURCE_GROUP is missing}"
: "${EXPECTED_APP_NAME:?EXPECTED_APP_NAME is missing}"
: "${PIPELINE_CLIENT_ID:?PIPELINE_CLIENT_ID is missing}"

echo "Finding the pipeline service principal..."

PIPELINE_OBJECT_ID="$(az ad sp show \
  --id "$PIPELINE_CLIENT_ID" \
  --query id \
  --output tsv)"

PIPELINE_APP_NAME="$(az ad sp show \
  --id "$PIPELINE_CLIENT_ID" \
  --query displayName \
  --output tsv)"

if [ "$PIPELINE_APP_NAME" != "$EXPECTED_APP_NAME" ]; then
  echo "Unexpected application: $PIPELINE_APP_NAME"
  echo "Expected: $EXPECTED_APP_NAME. Check the client ID."
  exit 1
fi

echo "Application confirmed: $PIPELINE_APP_NAME"
echo "Finding resource group: $RESOURCE_GROUP"

NIMBUS_SCOPE="$(az group show \
  --name "$RESOURCE_GROUP" \
  --query id \
  --output tsv)"

echo "Checking existing Contributor access..."

EXISTING_ASSIGNMENTS="$(az role assignment list \
  --assignee-object-id "$PIPELINE_OBJECT_ID" \
  --fill-principal-name false \
  --scope "$NIMBUS_SCOPE" \
  --include-inherited \
  --role Contributor \
  --query 'length(@)' \
  --output tsv)"

if [ "$EXISTING_ASSIGNMENTS" -gt 0 ]; then
  echo "Contributor access already exists. Nothing to create."
else
  echo "Assigning Contributor access..."

  az role assignment create \
    --assignee-object-id "$PIPELINE_OBJECT_ID" \
    --assignee-principal-type ServicePrincipal \
    --role Contributor \
    --scope "$NIMBUS_SCOPE" \
    --output none

  echo "Contributor access assigned successfully."
fi

echo "Resulting role assignments:"

az role assignment list \
  --assignee-object-id "$PIPELINE_OBJECT_ID" \
  --fill-principal-name false \
  --scope "$NIMBUS_SCOPE" \
  --include-inherited \
  --query "[].{Role:roleDefinitionName,Scope:scope}" \
  --output table