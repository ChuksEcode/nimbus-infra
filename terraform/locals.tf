locals {
  common_tags = merge(
    var.tags,
    {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  )
}