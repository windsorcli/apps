output "project_id" {
  description = "The ID of the Vercel project."
  value       = vercel_project.this.id
}

output "project_name" {
  description = "The name of the Vercel project."
  value       = vercel_project.this.name
}

output "domain_ids" {
  description = "The map of domain names to Vercel project domain IDs."
  value = {
    for domain_name, resource in vercel_project_domain.this : domain_name => resource.id
  }
}

output "environment_variable_ids" {
  description = "The map of environment variable resource keys to IDs."
  value = {
    for env_key, resource in vercel_project_environment_variable.this : env_key => resource.id
  }
}

output "effective_runtime_policy" {
  description = "Effective runtime policy values applied to Vercel project resource configuration."
  value = {
    fluid                     = try(local.effective_resource_config.fluid, null)
    function_default_cpu_type = try(local.effective_resource_config.function_default_cpu_type, null)
    function_default_regions  = try(local.effective_resource_config.function_default_regions, null)
    function_default_timeout  = try(local.effective_resource_config.function_default_timeout, null)
  }
}

output "environment_variable_keys_by_target" {
  description = "Environment variable key inventory grouped by Vercel target."
  value       = local.environment_variable_keys_by_target
}

output "environment_variable_sensitive_keys_by_target" {
  description = "Sensitive environment variable key inventory grouped by Vercel target."
  value       = local.environment_variable_sensitive_keys_by_target
}
