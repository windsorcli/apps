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

  environment_variable_keys_by_target = {
    for target in ["development", "preview", "production"] : target => toset([
      for env in nonsensitive(var.environment_variables) : env.key
      if contains(env.target, target)
    ])
  }

  environment_variable_sensitive_keys_by_target = {
    for target in ["development", "preview", "production"] : target => toset([
      for env in nonsensitive(var.environment_variables) : env.key
      if contains(env.target, target) && try(env.sensitive, false) == true
    ])
  }

  sensitive_env_disallowed_targets = var.sensitive_env_policy.disallowed_targets
  sensitive_env_allowlist_keys     = var.sensitive_env_policy.allowlist_keys

  resolved_fluid                     = try(var.resource_config.fluid, null) != null ? try(var.resource_config.fluid, null) : var.fluid_enabled
  resolved_function_default_cpu_type = try(var.resource_config.function_default_cpu_type, null) != null ? try(var.resource_config.function_default_cpu_type, null) : var.default_cpu_type
  resolved_function_default_timeout  = try(var.resource_config.function_default_timeout, null) != null ? try(var.resource_config.function_default_timeout, null) : var.default_function_timeout
  resolved_function_default_regions  = try(var.resource_config.function_default_regions, null) != null ? try(var.resource_config.function_default_regions, null) : var.allowed_regions

  effective_resource_config = (
    (
      local.resolved_fluid == null &&
      local.resolved_function_default_cpu_type == null &&
      local.resolved_function_default_timeout == null &&
      length(local.resolved_function_default_regions != null ? local.resolved_function_default_regions : toset([])) == 0
      ) ? null : {
      fluid                     = local.resolved_fluid
      function_default_cpu_type = local.resolved_function_default_cpu_type
      function_default_regions  = length(local.resolved_function_default_regions != null ? local.resolved_function_default_regions : toset([])) > 0 ? local.resolved_function_default_regions : null
      function_default_timeout  = local.resolved_function_default_timeout
    }
  )

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

check "required_env_keys_by_target_present" {
  assert {
    condition = alltrue([
      for target, required_keys in var.required_env_by_target : alltrue([
        for required_key in required_keys : contains(local.environment_variable_keys_by_target[target], required_key)
      ])
    ])
    error_message = "All required_env_by_target keys must exist in environment_variables for each corresponding target."
  }
}

check "required_sensitive_env_keys_by_target_present" {
  assert {
    condition = alltrue([
      for target, required_keys in var.required_sensitive_env_by_target : alltrue([
        for required_key in required_keys : contains(local.environment_variable_sensitive_keys_by_target[target], required_key)
      ])
    ])
    error_message = "All required_sensitive_env_by_target keys must exist in environment_variables as sensitive=true for each corresponding target."
  }
}

check "no_disallowed_sensitive_env_targets" {
  assert {
    condition = alltrue([
      for env in nonsensitive(var.environment_variables) : alltrue([
        for target in env.target : !(
          contains(local.sensitive_env_disallowed_targets, target) &&
          try(env.sensitive, false) == true &&
          !contains(local.sensitive_env_allowlist_keys, env.key)
        )
      ])
    ])
    error_message = "Sensitive environment variables are configured on disallowed targets. Use sensitive_env_policy.allowlist_keys for explicit exceptions."
  }
}

check "env_key_pattern_enforced" {
  assert {
    condition = alltrue([
      for env in nonsensitive(var.environment_variables) : (
        var.env_key_pattern == null ||
        can(regex(var.env_key_pattern, env.key))
      )
    ])
    error_message = "All environment variable keys must match env_key_pattern when it is set."
  }
}

check "env_key_denylist_enforced" {
  assert {
    condition = alltrue([
      for env in nonsensitive(var.environment_variables) : !contains(var.env_key_denylist, env.key)
    ])
    error_message = "One or more environment variable keys are present in env_key_denylist."
  }
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
  resource_config = local.effective_resource_config

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
