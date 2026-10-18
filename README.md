# ☁️ Terraform Infrastructure on Azure

This project provisions and manages Azure infrastructure entirely through Terraform and demonstrates the complete Infrastructure as Code lifecycle, including resource provisioning, RBAC, reusable configuration, Terraform state management, remote backend migration, troubleshooting, and safe infrastructure destruction.

---

## 🚀 What This Project Deploys

The Terraform configuration provisions:

- **Azure Resource Group** – Logical container for the infrastructure
- **Azure Container Registry (ACR)** – Private registry for container images
- **Azure Kubernetes Service (AKS)** – Managed Kubernetes cluster
- **Azure Key Vault** – Secure secrets and key management
- **Azure Storage Account** – Storage used for the Terraform remote backend
- **Private Blob Container (`tfstate`)** – Stores Terraform state remotely
- **Azure RBAC Role Assignments**
  - AKS access to ACR
  - AKS access to Azure Key Vault

The project also implements:

- Terraform variables
- Local values
- Common resource tags
- Terraform outputs
- Remote state management
- Azure RBAC
- Resource dependencies
- Saved Terraform plans
- Git exclusions for state, plans and sensitive files

---

## 🏗️ Architecture

```text
Azure Subscription
│
└── Resource Group
    │
    ├── Azure Kubernetes Service (AKS)
    │        │
    │        ├── RBAC ──────> Azure Container Registry
    │        │                  (AcrPull)
    │        │
    │        └── RBAC ──────> Azure Key Vault
    │
    ├── Azure Container Registry (ACR)
    │
    ├── Azure Key Vault
    │
    └── Azure Storage Account
             │
             └── Private Blob Container
                      │
                      └── terraform.tfstate
```

---

## 📁 Project Structure

```text
nimbus-infra/
│
├── .gitignore
│
└── terraform/
    ├── .terraform.lock.hcl
    ├── provider.tf
    ├── main.tf
    ├── variables.tf
    ├── locals.tf
    ├── acr.tf
    ├── aks.tf
    ├── keyvault.tf
    ├── storage.tf
    ├── rbac.tf
    ├── outputs.tf
    └── backend.tf
```

### File Responsibilities

| File | Purpose |
|---|---|
| `provider.tf` | Defines Terraform and the AzureRM provider |
| `main.tf` | Defines the Azure Resource Group |
| `variables.tf` | Declares reusable Terraform input variables |
| `locals.tf` | Defines reusable local values and naming conventions |
| `acr.tf` | Deploys Azure Container Registry |
| `aks.tf` | Deploys Azure Kubernetes Service |
| `keyvault.tf` | Deploys Azure Key Vault |
| `storage.tf` | Deploys the Storage Account and private state container |
| `rbac.tf` | Defines Azure RBAC role assignments |
| `outputs.tf` | Exposes useful infrastructure information |
| `backend.tf` | Configures the Azure Storage remote Terraform backend |
| `.terraform.lock.hcl` | Locks Terraform provider versions for reproducible deployments |

---

## 🛠️ Prerequisites

Before running the project, install:

- Terraform
- Azure CLI
- Git
- VS Code or another code editor

You also need:

- An active Microsoft Azure subscription
- Permission to create Azure resources
- Permission to create Azure RBAC role assignments

For RBAC creation, an account with **Owner**, or equivalent resource creation and role-assignment permissions, is required.

Verify the tools:

```bash
terraform --version
az version
git --version
```

---

## 🔐 Azure Authentication

Login to Azure:

```bash
az login
```

Check the active subscription:

```bash
az account show --output table
```

If required, select the correct subscription:

```bash
az account set --subscription "<subscription-name-or-id>"
```

---

# 🚀 Deployment Workflow

## 1. Initialize Terraform

```bash
terraform init
```

This initializes the working directory and downloads the required AzureRM provider.

---

## 2. Format the Terraform Configuration

```bash
terraform fmt
```

This formats Terraform files according to Terraform conventions.

---

## 3. Validate the Configuration

```bash
terraform validate
```

This checks the Terraform configuration for syntax and structural errors.

---

## 4. Create a Deployment Plan

```bash
terraform plan -out=tfplan
```

The plan allows infrastructure changes to be reviewed before deployment.

Inspect the saved plan if required:

```bash
terraform show tfplan
```

---

## 5. Apply the Saved Plan

```bash
terraform apply tfplan
```

Terraform then provisions the Azure infrastructure defined in the configuration.

---

# 🗄️ Terraform State and Remote Backend

Terraform uses a state file to map Terraform configuration to real Azure resources.

Initially, this project uses **local state** because the Azure Storage Account and Blob Container required for the remote backend do not yet exist.

The initial deployment therefore follows this flow:

```text
Terraform configuration
        │
        ▼
Local terraform.tfstate
        │
        ▼
Create Azure infrastructure
        │
        ├── Storage Account
        └── tfstate Blob Container
```

Once the Storage Account and `tfstate` container exist, the AzureRM backend in `backend.tf` is enabled.

The state is then migrated to Azure Storage:

```bash
terraform init -migrate-state
```

Terraform copies the existing local state into the Azure remote backend.

The final state architecture becomes:

```text
Terraform
    │
    ▼
Azure Storage Account
    │
    ▼
tfstate container
    │
    ▼
terraform.tfstate
```

Verify the migrated state with:

```bash
terraform state list
```

and:

```bash
terraform plan
```

A successful configuration should show no unexpected infrastructure changes.

---

## Why Remote State?

Remote state provides several advantages over keeping Terraform state only on a local workstation:

- Centralized state storage
- Team collaboration
- Reduced risk of losing state if a workstation fails
- State locking support
- Better suitability for CI/CD pipelines
- Improved infrastructure management

Terraform state files should never be committed to Git.

---

# 🔐 RBAC

Azure Role-Based Access Control is used to securely connect Azure services.

The project configures permissions such as:

```text
AKS
 │
 ├── AcrPull ───────────────> Azure Container Registry
 │
 └── Key Vault access ─────> Azure Key Vault
```

This allows Azure services to communicate using identities and RBAC rather than embedding credentials in application code.

---

# 📤 Terraform Outputs

Useful resource information is exposed through `outputs.tf`.

Display the outputs using:

```bash
terraform output
```

Outputs can be used by engineers, scripts and CI/CD pipelines after deployment.

---

# 🔎 Useful Terraform Commands

```bash
terraform init
```

Initializes the Terraform working directory.

```bash
terraform fmt
```

Formats Terraform configuration files.

```bash
terraform validate
```

Validates the configuration.

```bash
terraform plan
```

Shows proposed infrastructure changes.

```bash
terraform plan -out=tfplan
```

Creates and saves an execution plan.

```bash
terraform apply tfplan
```

Applies the reviewed execution plan.

```bash
terraform output
```

Displays Terraform outputs.

```bash
terraform state list
```

Lists all resources tracked in Terraform state.

```bash
terraform show
```

Displays state or a saved Terraform plan.

```bash
terraform destroy
```

Destroys Terraform-managed infrastructure.

---

# 🧹 Safe Destruction Workflow

Because this project stores its Terraform backend inside infrastructure that is itself managed by Terraform, the state should first be moved back to local storage before destroying the backend resources.

## 1. Back Up the Remote State

```bash
terraform state pull > terraform-state-before-destroy.json
```

---

## 2. Disable the AzureRM Backend

Temporarily comment out the backend configuration in `backend.tf`.

---

## 3. Migrate State Back to Local

```bash
terraform init -migrate-state
```

Verify that Terraform still tracks the resources:

```bash
terraform state list
```

---

## 4. Create a Destroy Plan

```bash
terraform plan -destroy -out=destroy.tfplan
```

Review the plan:

```bash
terraform show destroy.tfplan
```

---

## 5. Destroy the Infrastructure

```bash
terraform apply destroy.tfplan
```

A successful teardown should finish with output similar to:

```text
Apply complete! Resources: 0 added, 0 changed, 8 destroyed.
```

---

# 🧪 Troubleshooting Experience

During this project I worked through several real-world Terraform and Azure issues, including:

- Azure globally unique resource naming requirements
- Storage Account naming restrictions
- AKS VM SKU availability in the selected Azure region
- RBAC role assignments
- Terraform resource dependencies
- Local versus remote Terraform state
- Backend initialization and migration
- Terraform configuration drift

This reinforced the importance of reading Terraform error messages carefully and understanding both Terraform and the underlying cloud platform.

---

# 🔒 Security and Git Hygiene

The repository excludes local/generated/sensitive files including:

```text
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
tfplan
destroy.tfplan
terraform-state-before-destroy.json
.env
```

The `.terraform.lock.hcl` file **is committed** so Terraform provider versions remain reproducible.

Sensitive credentials and secrets should never be stored directly in Terraform source files.

---

# 📚 Key Learning Outcomes

This project provided practical experience with:

- Infrastructure as Code
- Terraform workflow
- Azure resource provisioning
- Azure Kubernetes Service
- Azure Container Registry
- Azure Key Vault
- Azure Storage
- Azure RBAC
- Terraform variables
- Terraform locals
- Terraform outputs
- Terraform state
- Remote backends
- Infrastructure troubleshooting
- Safe infrastructure destruction

The key lesson is that Infrastructure as Code is not simply about writing Terraform files. It requires understanding how cloud resources, identities, permissions, dependencies, state and platform constraints work together throughout the infrastructure lifecycle.

