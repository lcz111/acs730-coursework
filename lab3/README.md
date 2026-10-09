# Lab 3

In a real AWS account, GitHub Actions should use OIDC to obtain short-lived AWS credentials without storing long-lived access keys as GitHub secrets.

In AWS Academy, IAM restrictions prevent us from configuring OIDC, so we use session-scoped AWS credentials stored as GitHub Actions secrets, whose limited lifetime reduces the potential damage if they are leaked.

## Troubleshooting

### ExpiredToken

If a GitHub Actions deployment fails with an ExpiredToken error, the AWS Academy lab session may have expired. Start a new lab session, run `./scripts/refresh-gha-creds.sh` again to update the GitHub Actions secrets, and re-run the failed workflow job. No repository changes are required.

### Input required and not supplied: aws-region

This error means the GitHub Actions variable `AWS_REGION` is missing. It is not necessarily a credential problem. Run `./scripts/refresh-gha-creds.sh` to configure the variable, or set it manually using `gh variable set AWS_REGION --body us-east-1`.

## Terraform Version

Terraform version used: **1.10.3**.

## Experiments

### Experiment 1 — Expired AWS Credentials

I predicted that ending the AWS Academy lab session would cause the deployment workflow to fail during AWS authentication with an ExpiredToken or InvalidClientTokenId error. After ending the lab and rerunning GitHub Actions, Terraform Init actually failed with an S3 403 Forbidden error while accessing the remote state. After starting a new lab session and refreshing the GitHub Actions credentials, the workflow succeeded without changing any repository files (0 files changed).

### Experiment 2 — Remove the S3 Backend

I predicted that removing the S3 backend and migrating the state would create a local terraform.tfstate file, and that CI could propose duplicate resources if it used a separate, empty state. After commenting out the S3 backend and running terraform init -migrate-state, Terraform successfully switched to the local backend and created a 1.7 KB terraform.tfstate file containing the existing resource state. I restored the S3 backend, reinitialized Terraform, verified that the existing SSM parameter remained in the remote state, and deleted the temporary local state and backup files.

