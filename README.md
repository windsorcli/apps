# Blueprint
This repository serves as the parent template from which other blueprints inherit. It contains common CI and dotfiles used by other blueprint repositories.

## Local tasks

This repository includes a `Taskfile.yaml` so CI-like checks can run locally.

- `task lint` runs YAML, shell, and Terraform format checks.
- `task sast` runs local SAST/IaC scanning with Checkov.
- `task test` runs Windsor and Terraform tests.
- `task ci` runs the full local CI sequence (`lint`, `sast`, `test`).

Use `task --list` to view all available tasks.