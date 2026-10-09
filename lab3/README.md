# Lab 3

In a real AWS account, GitHub Actions should use OIDC to obtain short-lived AWS credentials without storing long-lived access keys as GitHub secrets.

In AWS Academy, IAM restrictions prevent us from configuring OIDC, so we use session-scoped AWS credentials stored as GitHub Actions secrets, whose limited lifetime reduces the potential damage if they are leaked.
