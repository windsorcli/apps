# The Vercel Project module creates and manages a Vercel project and domains.
# It owns project-level settings and should be managed by a single Terraform state.

# =============================================================================
# Provider Configuration
# =============================================================================

terraform {
  required_version = ">=1.8"
  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = "~> 4.6"
    }
  }
}

# =============================================================================
# Locals
# =============================================================================

locals {
  domains_by_name = {
    for domain in var.domains : domain.domain => domain
  }

  environment_variables_by_key = {
    for idx, env in nonsensitive(var.environment_variables) : join("|", [
      env.key,
      env.git_branch != null ? env.git_branch : "",
      join(",", sort(tolist(env.target))),
      join(",", sort(tolist(env.custom_environment_ids))),
    ]) => idx
  }

  # Vercel Git linking expects provider-specific repo slugs (e.g. owner/repo).
  # Normalize common URL and host-prefixed forms into slug-like paths.
  git_repository_repo_normalized = var.git_repository == null ? null : (
    startswith(var.git_repository.repo, "http://") || startswith(var.git_repository.repo, "https://") ? trimsuffix(join("/", slice(split("/", var.git_repository.repo), 3, length(split("/", var.git_repository.repo)))), ".git") : (
      startswith(var.git_repository.repo, "ssh://") ? trimsuffix(join("/", slice(split("/", var.git_repository.repo), 3, length(split("/", var.git_repository.repo)))), ".git") : (
        startswith(var.git_repository.repo, "git@") ? trimsuffix(element(split(":", var.git_repository.repo), 1), ".git") : (
          startswith(var.git_repository.repo, "github.com/") ? trimsuffix(trimprefix(var.git_repository.repo, "github.com/"), ".git") : (
            startswith(var.git_repository.repo, "www.github.com/") ? trimsuffix(trimprefix(var.git_repository.repo, "www.github.com/"), ".git") : (
              startswith(var.git_repository.repo, "gitlab.com/") ? trimsuffix(trimprefix(var.git_repository.repo, "gitlab.com/"), ".git") : (
                startswith(var.git_repository.repo, "www.gitlab.com/") ? trimsuffix(trimprefix(var.git_repository.repo, "www.gitlab.com/"), ".git") : (
                  startswith(var.git_repository.repo, "bitbucket.org/") ? trimsuffix(trimprefix(var.git_repository.repo, "bitbucket.org/"), ".git") : (
                    startswith(var.git_repository.repo, "www.bitbucket.org/") ? trimsuffix(trimprefix(var.git_repository.repo, "www.bitbucket.org/"), ".git") : trimsuffix(var.git_repository.repo, ".git")
                  )
                )
              )
            )
          )
        )
      )
    )
  )
}

# =============================================================================
# Project Resources
# =============================================================================

resource "vercel_project" "this" {
  name    = var.project_name
  team_id = var.team_id

  framework        = var.project_framework
  root_directory   = var.project_root_directory
  build_command    = var.build_command
  install_command  = var.install_command
  dev_command      = var.dev_command
  ignore_command   = var.ignore_command
  output_directory = var.output_directory
  node_version     = var.node_version

  auto_assign_custom_domains   = var.auto_assign_custom_domains
  preview_deployments_disabled = var.preview_deployments_disabled
  public_source                = var.public_source

  protection_bypass_for_automation        = var.protection_bypass_for_automation
  protection_bypass_for_automation_secret = var.protection_bypass_for_automation_secret

  skew_protection = var.skew_protection
  resource_config = var.resource_config

  git_repository = var.git_repository == null ? null : {
    type              = var.git_repository.type
    repo              = local.git_repository_repo_normalized
    production_branch = var.git_repository.production_branch
  }

  vercel_authentication = var.vercel_authentication_deployment_type == null ? null : {
    deployment_type = var.vercel_authentication_deployment_type
  }

  password_protection = var.password_protection == null ? null : {
    deployment_type = var.password_protection.deployment_type
    password        = var.password_protection.password
  }

  trusted_ips = var.trusted_ips == null ? null : {
    deployment_type = var.trusted_ips.deployment_type
    protection_mode = var.trusted_ips.protection_mode
    addresses = [
      for address in var.trusted_ips.addresses : {
        value = address.value
        note  = address.note
      }
    ]
  }
}

# =============================================================================
# Domain Resources
# =============================================================================

resource "vercel_project_domain" "this" {
  for_each = local.domains_by_name

  project_id = vercel_project.this.id
  team_id    = var.team_id

  domain                = each.value.domain
  git_branch            = each.value.git_branch
  custom_environment_id = each.value.custom_environment_id
  redirect              = each.value.redirect
  redirect_status_code  = each.value.redirect_status_code
}

# =============================================================================
# Environment Variable Resources
# =============================================================================

resource "vercel_project_environment_variable" "this" {
  for_each = local.environment_variables_by_key

  project_id = vercel_project.this.id
  team_id    = var.team_id

  key   = nonsensitive(var.environment_variables[each.value].key)
  value = var.environment_variables[each.value].value

  target                 = length(nonsensitive(var.environment_variables[each.value].target)) > 0 ? nonsensitive(var.environment_variables[each.value].target) : null
  custom_environment_ids = length(nonsensitive(var.environment_variables[each.value].custom_environment_ids)) > 0 ? nonsensitive(var.environment_variables[each.value].custom_environment_ids) : null
  git_branch             = var.environment_variables[each.value].git_branch != null ? nonsensitive(var.environment_variables[each.value].git_branch) : null
  sensitive              = nonsensitive(var.environment_variables[each.value].sensitive)
  comment                = var.environment_variables[each.value].comment != null ? nonsensitive(var.environment_variables[each.value].comment) : null
}
