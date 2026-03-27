# =============================================================================
# Core Inputs
# =============================================================================

variable "team_id" {
  description = "The team ID that owns the Vercel project."
  type        = string
  default     = null
}

variable "project_name" {
  description = "The desired name for the Vercel project."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "The project_name must not be empty."
  }
}

variable "project_framework" {
  description = "The framework for the Vercel project."
  type        = string
  default     = null
}

variable "project_root_directory" {
  description = "The root directory path for the Vercel project source."
  type        = string
  default     = null
}

variable "git_repository" {
  description = "The Git repository configuration for the Vercel project."
  type = object({
    type              = string
    repo              = string
    production_branch = optional(string)
  })
  default = null

  validation {
    condition = (
      var.git_repository == null ||
      contains(["github", "gitlab", "bitbucket"], try(var.git_repository.type, ""))
    )
    error_message = "The git_repository.type must be one of github, gitlab, or bitbucket."
  }
}

# =============================================================================
# Build and Runtime Settings
# =============================================================================

variable "build_command" {
  description = "The build command for the project."
  type        = string
  default     = null
}

variable "install_command" {
  description = "The install command for the project."
  type        = string
  default     = null
}

variable "dev_command" {
  description = "The development command for the project."
  type        = string
  default     = null
}

variable "ignore_command" {
  description = "The ignore command for the project."
  type        = string
  default     = null
}

variable "output_directory" {
  description = "The output directory for project build artifacts."
  type        = string
  default     = null
}

variable "node_version" {
  description = "The Node.js version used by builds and functions."
  type        = string
  default     = null
}

variable "auto_assign_custom_domains" {
  description = "Whether to automatically assign custom domains to production deployments."
  type        = bool
  default     = true
}

variable "preview_deployments_disabled" {
  description = "Whether preview deployments are disabled."
  type        = bool
  default     = false
}

variable "public_source" {
  description = "Whether project logs and source paths are publicly viewable."
  type        = bool
  default     = false
}

variable "skew_protection" {
  description = "The duration value for skew protection."
  type        = string
  default     = null

  validation {
    condition = (
      var.skew_protection == null ||
      contains(["30 minutes", "12 hours", "1 day", "7 days"], var.skew_protection == null ? "" : var.skew_protection)
    )
    error_message = "The skew_protection must be one of 30 minutes, 12 hours, 1 day, or 7 days."
  }
}

variable "resource_config" {
  description = "The resource configuration for project functions."
  type = object({
    fluid                     = optional(bool)
    function_default_cpu_type = optional(string)
    function_default_regions  = optional(set(string))
    function_default_timeout  = optional(number)
  })
  default = null

  validation {
    condition = (
      var.resource_config == null ||
      try(var.resource_config.function_default_cpu_type, null) == null ||
      contains(["standard_legacy", "standard", "performance"], try(var.resource_config.function_default_cpu_type, ""))
    )
    error_message = "The resource_config.function_default_cpu_type must be one of standard_legacy, standard, or performance."
  }
}

# =============================================================================
# Protection Settings
# =============================================================================

variable "protection_bypass_for_automation" {
  description = "Whether automation can bypass deployment protection."
  type        = bool
  default     = false
}

variable "protection_bypass_for_automation_secret" {
  description = "The secret used for automation bypass of deployment protection."
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition = (
      var.protection_bypass_for_automation_secret == null ||
      try(length(var.protection_bypass_for_automation_secret), 0) == 32
    )
    error_message = "The protection_bypass_for_automation_secret must be exactly 32 characters when set."
  }
}

variable "vercel_authentication_deployment_type" {
  description = "The deployment type protected by Vercel authentication."
  type        = string
  default     = null

  validation {
    condition = (
      var.vercel_authentication_deployment_type == null ||
      contains([
        "standard_protection_new",
        "standard_protection",
        "all_deployments",
        "only_preview_deployments",
        "none",
      ], var.vercel_authentication_deployment_type == null ? "" : var.vercel_authentication_deployment_type)
    )
    error_message = "The vercel_authentication_deployment_type must be one of standard_protection_new, standard_protection, all_deployments, only_preview_deployments, or none."
  }
}

variable "password_protection" {
  description = "The password protection configuration for project deployments."
  type = object({
    deployment_type = string
    password        = string
  })
  default   = null
  sensitive = true

  validation {
    condition = (
      var.password_protection == null ||
      contains([
        "standard_protection_new",
        "standard_protection",
        "all_deployments",
        "only_preview_deployments",
      ], try(var.password_protection.deployment_type, ""))
    )
    error_message = "The password_protection.deployment_type must be one of standard_protection_new, standard_protection, all_deployments, or only_preview_deployments."
  }
}

variable "trusted_ips" {
  description = "The trusted IP settings for deployment access."
  type = object({
    deployment_type = string
    protection_mode = optional(string)
    addresses = set(object({
      value = string
      note  = optional(string)
    }))
  })
  default = null

  validation {
    condition = (
      var.trusted_ips == null ||
      contains([
        "standard_protection_new",
        "standard_protection",
        "all_deployments",
        "only_production_deployments",
        "only_preview_deployments",
      ], try(var.trusted_ips.deployment_type, ""))
    )
    error_message = "The trusted_ips.deployment_type must be one of standard_protection_new, standard_protection, all_deployments, only_production_deployments, or only_preview_deployments."
  }

  validation {
    condition = (
      var.trusted_ips == null ||
      try(var.trusted_ips.protection_mode, null) == null ||
      contains(["trusted_ip_required", "trusted_ip_optional"], try(var.trusted_ips.protection_mode, ""))
    )
    error_message = "The trusted_ips.protection_mode must be one of trusted_ip_required or trusted_ip_optional."
  }
}

# =============================================================================
# Domain Inputs
# =============================================================================

variable "domains" {
  description = "The list of domains to associate with the project."
  type = list(object({
    domain                = string
    git_branch            = optional(string)
    custom_environment_id = optional(string)
    redirect              = optional(string)
    redirect_status_code  = optional(number)
  }))
  default = []

  validation {
    condition = length(var.domains) == length(toset([
      for domain in var.domains : domain.domain
    ]))
    error_message = "Each domain entry must have a unique domain value."
  }

  validation {
    condition = alltrue([
      for domain in var.domains : (
        domain.redirect_status_code == null ||
        contains([301, 302, 307, 308], domain.redirect_status_code == null ? 0 : domain.redirect_status_code)
      )
    ])
    error_message = "If provided, redirect_status_code must be one of 301, 302, 307, or 308."
  }
}

# =============================================================================
# Environment Variable Inputs
# =============================================================================

variable "environment_variables" {
  description = "The list of environment variables to define for the project."
  type = list(object({
    key                    = string
    value                  = string
    target                 = optional(set(string), [])
    custom_environment_ids = optional(set(string), [])
    git_branch             = optional(string)
    sensitive              = optional(bool, false)
    comment                = optional(string)
  }))
  default   = []
  sensitive = true

  validation {
    condition = alltrue([
      for env in var.environment_variables : length(trimspace(env.key)) > 0
    ])
    error_message = "Each environment variable key must not be empty."
  }

  validation {
    condition = alltrue([
      for env in var.environment_variables : length(env.target) > 0 || length(env.custom_environment_ids) > 0
    ])
    error_message = "Each environment variable must define at least one target or one custom_environment_id."
  }

  validation {
    condition = alltrue(flatten([
      for env in var.environment_variables : [
        for target in env.target : contains(["production", "preview", "development"], target)
      ]
    ]))
    error_message = "Environment variable targets must be one of production, preview, or development."
  }

  validation {
    condition = length(var.environment_variables) == length(toset([
      for env in var.environment_variables : join("|", [
        env.key,
        env.git_branch != null ? env.git_branch : "",
        join(",", sort(tolist(env.target))),
        join(",", sort(tolist(env.custom_environment_ids))),
      ])
    ]))
    error_message = "Environment variable entries must be unique by key, git_branch, target set, and custom_environment_ids set."
  }
}
