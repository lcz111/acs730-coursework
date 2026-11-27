# ACS730 Assignment 1

## Task 4 - Environment-scoped Credentials and OIDC

### Environment-scoped Credentials

The three AWS session credentials were migrated from repository-level secrets to the staging and prod GitHub Environments.

Both environments were successfully tested using AWS STS GetCallerIdentity before the repository-level AWS secrets were removed.

The updated credential refresh command is:

    ./scripts/refresh-gha-creds.sh lcz111/acs730-coursework staging prod

Evidence: evidence/secrets-scope.txt

### Proposed OIDC Trust Policy

In a real AWS account, the following IAM trust policy would allow GitHub Actions to assume a production deployment role through OIDC federation.

    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
              "token.actions.githubusercontent.com:sub": "repo:lcz111/acs730-coursework:environment:prod"
            }
          }
        }
      ]
    }

### Security Explanation

- Principal: Specifies GitHub's registered OIDC identity provider as the trusted identity provider.
- Action: Allows AWS STS to exchange a valid OIDC token for temporary AWS credentials.
- Audience (aud): Ensures that the token is intended for AWS STS rather than another service.
- Subject (sub): Restricts access to workflows using the prod environment in the specified repository.
- StringEquals: Requires an exact match instead of allowing wildcard-based access.

A broader subject condition such as repo:lcz111/acs730-coursework:* could allow workflows from other branches or environments to assume the production role. A contributor with branch push access could potentially modify a workflow to request production credentials without passing the production approval gate.

The environment-specific subject condition reduces this risk. Combined with the required reviewer and main-only deployment branch policy, production access is subject to the configured GitHub Environment protection rules.

The IAM role would also require a separate least-privilege permissions policy defining which AWS resources and operations it can access.

### AWS Academy Limitation

This OIDC trust policy was not deployed because AWS Academy Learner Lab restricts the IAM operations required to create the OIDC provider and IAM role.

Therefore, temporary AWS Academy session credentials stored as environment-scoped GitHub secrets were used as the practical alternative.
