#!/usr/bin/env bash
# Run from terraform/ after Azure Login. No backend migration is performed here.
set -euo pipefail
for NAME in ARM_SUBSCRIPTION_ID ARM_TENANT_ID ARM_CLIENT_ID ARM_CLIENT_SECRET RESOURCE_GROUP TF_BACKEND_RESOURCE_GROUP TF_BACKEND_STORAGE_ACCOUNT TF_BACKEND_CONTAINER TF_BACKEND_KEY; do
  [ -n "${!NAME:-}" ] || { echo "Required configuration missing: $NAME"; exit 1; }
done
if [ "${RESOURCE_GROUP,,}" = "${TF_BACKEND_RESOURCE_GROUP,,}" ]; then
  echo 'The Terraform state account must be in a separate resource group outside this project.'
  echo 'Migrate your existing state before using this workflow.'
  exit 1
fi
# Reject local/missing backends instead of creating an untracked empty local state.
python3 - <<'PYCHECK'
import pathlib, re
files = [*pathlib.Path('.').glob('*.tf')]
text = '\n'.join(x.read_text() for x in files)
text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
text = re.sub(r'(?m)^\s*(#|//).*$', '', text)
if not re.search(r'backend\s+"azurerm"\s*\{', text):
    raise SystemExit('An active backend "azurerm" block is required in terraform/.')
PYCHECK
az storage account show --resource-group "$TF_BACKEND_RESOURCE_GROUP" \
  --name "$TF_BACKEND_STORAGE_ACCOUNT" --output none
az storage container show --account-name "$TF_BACKEND_STORAGE_ACCOUNT" \
  --name "$TF_BACKEND_CONTAINER" --auth-mode login --output none

# The repository secret supplies your existing terraform.tfvars contents.
# Empty is allowed only if all required variables come from checked-in defaults.
if [ -n "${TERRAFORM_TFVARS:-}" ]; then
  umask 077
  printf '%s\n' "$TERRAFORM_TFVARS" > ci.auto.tfvars
fi
terraform init -input=false -reconfigure -lockfile=readonly \
  -backend-config="resource_group_name=$TF_BACKEND_RESOURCE_GROUP" \
  -backend-config="storage_account_name=$TF_BACKEND_STORAGE_ACCOUNT" \
  -backend-config="container_name=$TF_BACKEND_CONTAINER" \
  -backend-config="key=$TF_BACKEND_KEY" \
  -backend-config="subscription_id=$ARM_SUBSCRIPTION_ID" \
  -backend-config="use_azuread_auth=true"
