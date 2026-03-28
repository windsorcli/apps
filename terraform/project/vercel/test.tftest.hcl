mock_provider "vercel" {
  mock_resource "vercel_project" {
    defaults = {
      id = "prj_123"
    }
  }

  mock_resource "vercel_project_domain" {
    defaults = {
      id = "dom_123"
    }
  }

  mock_resource "vercel_project_environment_variable" {
    defaults = {
      id = "env_123"
    }
  }
}

run "minimal_configuration" {
  command = plan

  variables {
    project_name = "windsor-minimal"
  }

  assert {
    condition     = vercel_project.this.name == "windsor-minimal"
    error_message = "The project name should be set from project_name."
  }

  assert {
    condition     = length(vercel_project_domain.this) == 0
    error_message = "No domain resources should be created when domains is empty."
  }

  assert {
    condition     = length(vercel_project_environment_variable.this) == 0
    error_message = "No environment variable resources should be created when environment_variables is empty."
  }
}

run "full_configuration" {
  command = plan

  variables {
    team_id                                 = "team_abc"
    project_name                            = "windsor-full"
    project_framework                       = "nextjs"
    project_root_directory                  = "apps/web"
    build_command                           = "pnpm build"
    install_command                         = "pnpm install --frozen-lockfile"
    dev_command                             = "pnpm dev"
    ignore_command                          = "git diff --quiet HEAD^ HEAD ."
    output_directory                        = ".next"
    node_version                            = "20.x"
    auto_assign_custom_domains              = true
    preview_deployments_disabled            = false
    public_source                           = false
    protection_bypass_for_automation        = true
    protection_bypass_for_automation_secret = "12345678901234567890123456789012"
    skew_protection                         = "12 hours"
    resource_config = {
      fluid                     = true
      function_default_cpu_type = "standard"
      function_default_regions  = ["iad1", "sfo1"]
      function_default_timeout  = 60
    }
    git_repository = {
      type              = "github"
      repo              = "acme/windsor"
      production_branch = "main"
    }
    vercel_authentication_deployment_type = "all_deployments"
    password_protection = {
      deployment_type = "only_preview_deployments"
      password        = "preview-password" # checkov:skip=CKV_SECRET_6: Test fixture only, not a real secret
    }
    trusted_ips = {
      deployment_type = "only_preview_deployments"
      protection_mode = "trusted_ip_required"
      addresses = [
        {
          value = "10.0.0.0/8"
          note  = "corp-network"
        },
        {
          value = "192.168.0.0/16"
        }
      ]
    }
    domains = [
      {
        domain = "app.example.com"
      },
      {
        domain               = "staging.example.com"
        git_branch           = "staging"
        redirect             = "https://www.example.com"
        redirect_status_code = 308
      }
    ]
    environment_variables = [
      {
        key       = "DATABASE_URL"
        value     = "postgres://db"
        target    = ["production", "preview"]
        sensitive = true
        comment   = "Managed by Terraform"
      },
      {
        key                    = "FEATURE_FLAG"
        value                  = "true"
        custom_environment_ids = ["env_custom_1"]
        git_branch             = "staging"
      }
    ]
  }

  assert {
    condition     = vercel_project.this.team_id == "team_abc"
    error_message = "The project team_id should be set when provided."
  }

  assert {
    condition     = length(vercel_project_domain.this) == 2
    error_message = "One project domain resource should be created per domain input."
  }

  assert {
    condition     = length(vercel_project_environment_variable.this) == 2
    error_message = "One environment variable resource should be created per unique environment variable input."
  }

  assert {
    condition     = vercel_project_domain.this["staging.example.com"].redirect_status_code == 308
    error_message = "A domain redirect_status_code should pass through to the resource."
  }

  assert {
    condition     = vercel_project_environment_variable.this["DATABASE_URL||preview,production|"].target != null
    error_message = "An environment variable with explicit targets should keep a non-null target value."
  }
}

run "expression_logic_null_and_key_derivation" {
  command = plan

  variables {
    project_name = "windsor-expression"
    environment_variables = [
      {
        key       = "APP_MODE"
        value     = "preview"
        target    = ["preview", "production"]
        sensitive = false
      },
      {
        key        = "APP_MODE"
        value      = "preview-branch"
        target     = ["preview", "production"]
        git_branch = "feature/login"
      },
      {
        key                    = "ONLY_CUSTOM"
        value                  = "enabled"
        custom_environment_ids = ["env_custom_2"]
      }
    ]
  }

  assert {
    condition     = length(vercel_project_environment_variable.this) == 3
    error_message = "Distinct uniqueness keys should produce one resource per environment variable entry."
  }

  assert {
    condition     = contains(keys(local.environment_variables_by_key), "APP_MODE||preview,production|")
    error_message = "The uniqueness key should include APP_MODE with sorted targets and no git branch/custom environment values."
  }

  assert {
    condition     = vercel_project_environment_variable.this["APP_MODE|feature/login|preview,production|"].git_branch == "feature/login"
    error_message = "git_branch should be propagated when provided."
  }

  assert {
    condition     = contains(keys(local.environment_variables_by_key), "ONLY_CUSTOM|||env_custom_2")
    error_message = "The uniqueness key should include ONLY_CUSTOM with the custom environment identifier."
  }
}

run "runtime_defaults_and_required_env_policy" {
  command = plan

  variables {
    project_name             = "windsor-runtime-defaults"
    fluid_enabled            = true
    default_cpu_type         = "performance"
    default_function_timeout = 120
    allowed_regions          = ["iad1", "sfo1"]
    required_env_by_target = {
      production = ["OPENAI_API_KEY", "LLM_PROVIDER"]
      preview    = ["LLM_PROVIDER"]
    }
    environment_variables = [
      {
        key    = "OPENAI_API_KEY"
        value  = "secret"
        target = ["production"]
      },
      {
        key    = "LLM_PROVIDER"
        value  = "openai"
        target = ["production", "preview"]
      }
    ]
  }

  assert {
    condition     = vercel_project.this.resource_config.function_default_cpu_type == "performance"
    error_message = "default_cpu_type should be used when resource_config.function_default_cpu_type is not provided."
  }

  assert {
    condition     = vercel_project.this.resource_config.function_default_timeout == 120
    error_message = "default_function_timeout should be used when resource_config.function_default_timeout is not provided."
  }

  assert {
    condition     = output.effective_runtime_policy.fluid == true
    error_message = "effective_runtime_policy should expose the resolved fluid value."
  }

  assert {
    condition = (
      contains(output.environment_variable_keys_by_target.production, "OPENAI_API_KEY") &&
      contains(output.environment_variable_keys_by_target.production, "LLM_PROVIDER") &&
      contains(output.environment_variable_keys_by_target.preview, "LLM_PROVIDER")
    )
    error_message = "environment_variable_keys_by_target should include keys by target."
  }
}

run "github_repository_url_normalization" {
  command = plan

  variables {
    project_name = "windsor-git-repo-normalization"
    git_repository = {
      type              = "github"
      repo              = "github.com/windsorcli/apps"
      production_branch = "main"
    }
  }

  assert {
    condition     = vercel_project.this.git_repository.repo == "windsorcli/apps"
    error_message = "GitHub repository URLs should be normalized to owner/repo for Vercel linking."
  }

  assert {
    condition     = vercel_project.this.git_repository.type == "github"
    error_message = "Git repository type should be preserved after normalization."
  }
}

run "gitlab_repository_url_normalization" {
  command = plan

  variables {
    project_name = "windsor-gitlab-repo-normalization"
    git_repository = {
      type              = "gitlab"
      repo              = "https://gitlab.com/acme/platform/web.git"
      production_branch = "main"
    }
  }

  assert {
    condition     = vercel_project.this.git_repository.repo == "acme/platform/web"
    error_message = "GitLab repository URLs should be normalized to group/subgroup/repo."
  }

  assert {
    condition     = vercel_project.this.git_repository.type == "gitlab"
    error_message = "Git repository type should remain gitlab after normalization."
  }
}

run "bitbucket_repository_url_normalization" {
  command = plan

  variables {
    project_name = "windsor-bitbucket-repo-normalization"
    git_repository = {
      type              = "bitbucket"
      repo              = "ssh://git@bitbucket.org/workspace/service-api.git"
      production_branch = "main"
    }
  }

  assert {
    condition     = vercel_project.this.git_repository.repo == "workspace/service-api"
    error_message = "Bitbucket repository URLs should be normalized to workspace/repo."
  }

  assert {
    condition     = vercel_project.this.git_repository.type == "bitbucket"
    error_message = "Git repository type should remain bitbucket after normalization."
  }
}

run "plan_shape_matches_test_context" {
  command = plan

  variables {
    project_name      = "wm37vl1m"
    project_framework = "nextjs"
    output_directory  = ".next"
    environment_variables = [
      {
        key    = "WINDSOR_BLUEPRINT"
        value  = "bp"
        target = ["development"]
      },
      {
        key    = "WINDSOR_CONTEXT_ID"
        value  = "ctx-id"
        target = ["development"]
      },
      {
        key    = "WINDSOR_CONTEXT"
        value  = "test"
        target = ["development"]
      },
      {
        key    = "WINDSOR_GIT_REF"
        value  = "main"
        target = ["development"]
      },
      {
        key    = "WINDSOR_GIT_REPO"
        value  = "acme/windsor"
        target = ["development"]
      }
    ]
  }

  assert {
    condition     = vercel_project.this.name == "wm37vl1m"
    error_message = "The project name should match the test context plan shape."
  }

  assert {
    condition     = vercel_project.this.framework == "nextjs"
    error_message = "The project framework should match the test context plan shape."
  }

  assert {
    condition     = vercel_project.this.output_directory == ".next"
    error_message = "The output directory should match the test context plan shape."
  }

  assert {
    condition     = length(vercel_project_environment_variable.this) == 5
    error_message = "Five environment variable resources should be created for the test context plan shape."
  }

  assert {
    condition     = output.project_name == "wm37vl1m"
    error_message = "The project_name output should mirror the planned project name."
  }

  assert {
    condition     = length(output.domain_ids) == 0
    error_message = "The domain_ids output should be empty when no domains are configured."
  }

  assert {
    condition = (
      contains(keys(output.environment_variable_ids), "WINDSOR_BLUEPRINT||development|") &&
      contains(keys(output.environment_variable_ids), "WINDSOR_CONTEXT_ID||development|") &&
      contains(keys(output.environment_variable_ids), "WINDSOR_CONTEXT||development|") &&
      contains(keys(output.environment_variable_ids), "WINDSOR_GIT_REF||development|") &&
      contains(keys(output.environment_variable_ids), "WINDSOR_GIT_REPO||development|")
    )
    error_message = "The environment_variable_ids output should include all expected test context keys."
  }
}

run "combined_negative_validation" {
  command = plan

  variables {
    project_name = " "
    git_repository = {
      type = "gitea"
      repo = "acme/windsor"
    }
    skew_protection = "2 weeks"
    resource_config = {
      function_default_cpu_type = "ultra"
    }
    protection_bypass_for_automation_secret = "too-short"
    vercel_authentication_deployment_type   = "preview_only"
    password_protection = {
      deployment_type = "none"
      password        = "x"
    }
    trusted_ips = {
      deployment_type = "preview_only"
      protection_mode = "required"
      addresses = [
        {
          value = "10.0.0.0/8"
        }
      ]
    }
    domains = [
      {
        domain               = "dup.example.com"
        redirect_status_code = 200
      },
      {
        domain = "dup.example.com"
      }
    ]
    environment_variables = [
      {
        key   = " "
        value = "x"
      },
      {
        key    = "BAD_TARGET"
        value  = "x"
        target = ["qa"]
      }
    ]
  }

  expect_failures = [
    var.project_name,
    var.git_repository,
    var.skew_protection,
    var.resource_config,
    var.protection_bypass_for_automation_secret,
    var.vercel_authentication_deployment_type,
    var.password_protection,
    var.trusted_ips,
    var.domains,
    var.environment_variables,
  ]
}
