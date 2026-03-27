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
