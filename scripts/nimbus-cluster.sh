#!/usr/bin/env bash
set -euo pipefail
: "${RESOURCE_GROUP:?Missing RESOURCE_GROUP}"
: "${AKS_CLUSTER:?Missing AKS_CLUSTER}"
: "${OPERATION:?Missing OPERATION}"

POWER_STATE="$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_CLUSTER" --query powerState.code -o tsv)"
PROVISIONING_STATE="$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_CLUSTER" --query provisioningState -o tsv)"
if [ "$PROVISIONING_STATE" != Succeeded ]; then
  echo "AKS currently has an operation in progress: $PROVISIONING_STATE. Wait and retry."
  exit 1
fi
case "$OPERATION" in
  stop-cluster)
    if [ "$POWER_STATE" = Stopped ]; then
      echo 'AKS is already stopped.'
    elif [ "$POWER_STATE" = Running ]; then
      echo 'Stopping the AKS cluster. This can take several minutes...'
      az aks stop -g "$RESOURCE_GROUP" -n "$AKS_CLUSTER"
    else
      echo "Unexpected power state: $POWER_STATE"; exit 1
    fi
    ;;
  start-cluster)
    if [ "$POWER_STATE" = Running ]; then
      echo 'AKS is already running.'
    elif [ "$POWER_STATE" = Stopped ]; then
      echo 'Microsoft recommends waiting 15-30 minutes after stopping before starting AKS.'
      echo 'Starting AKS. This can take several minutes...'
      az aks start -g "$RESOURCE_GROUP" -n "$AKS_CLUSTER"
    else
      echo "Unexpected power state: $POWER_STATE"; exit 1
    fi
    ;;
  *) echo 'Expected stop-cluster or start-cluster'; exit 1 ;;
esac
az aks show -g "$RESOURCE_GROUP" -n "$AKS_CLUSTER" \
  --query '{Cluster:name,Power:powerState.code,Provisioning:provisioningState}' -o table
{
  echo '## AKS operation completed'
  echo "Operation: $OPERATION"
  echo 'Stopping AKS reduces node compute charges. Other retained resources still incur charges.'
} >> "$GITHUB_STEP_SUMMARY"
