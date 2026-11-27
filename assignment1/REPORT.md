# ACS730 Assignment 1 - Multi-Environment Terraform Deployment

Author: Chengze Li

## Introduction

The objective of this assignment is to implement a reusable, secure, and automated infrastructure deployment solution using Terraform, GitHub Actions, and AWS.

The infrastructure is organized into three independent environments: dev, staging, and prod. A shared Terraform module reduces code duplication, while separate remote state files isolate infrastructure management across environments.

The deployment pipeline automatically deploys staging after changes are merged into the main branch. Production deployment requires manual approval.

The project also demonstrates environment-scoped AWS credentials, a proposed OIDC trust policy, AWS Systems Manager Parameter Store integration, and CloudWatch monitoring.

## Task 1 - Reusable Terraform Module

The reusable infrastructure module is located at:

    assignment1/terraform/modules/web-infrastructure/

The module provisions a VPC, public subnets, an internet gateway, route tables, security groups, and EC2 web servers.

Input variables allow each environment to configure its network CIDR, subnet configuration, instance type, instance count, security rules, and environment-specific settings.

The module uses for_each for public subnets and route table associations because named map keys provide stable resource addresses. The count argument is used for EC2 instances and optional resources.

Module outputs expose VPC IDs, subnet IDs, instance IDs, security group IDs, and web application URLs.

Security measures include mandatory IMDSv2, encrypted root volumes, and no publicly accessible SSH ingress rule. The EC2 instances use the existing LabInstanceProfile.

The module was validated successfully using terraform fmt and terraform validate.

## Task 2 - Multi-Environment Configuration

Three independent Terraform root modules were implemented:

| Environment | VPC CIDR | Instance Type | Instance Count |
| --- | --- | --- | --- |
| dev | 10.42.0.0/16 | t3.micro | 1 |
| staging | 10.43.0.0/16 | t3.micro | 1 |
| prod | 10.44.0.0/16 | t3.micro | 1 |

All three environments use the same reusable infrastructure module.

The instance size and count were kept identical to minimize AWS Learner Lab costs. In a real production environment, these values could be adjusted independently according to workload requirements.

Each environment uses the existing S3 backend bucket with a unique state key:

- assignment1/dev/terraform.tfstate
- assignment1/staging/terraform.tfstate
- assignment1/prod/terraform.tfstate

Separate state keys prevent Terraform operations in one environment from accidentally managing resources belonging to another environment.

S3 state encryption and Terraform state locking are enabled.

All three state files were verified in the S3 bucket after successful deployments.

Evidence: evidence/backend-state-keys.txt

## Task 3 - GitHub Environment Protection

Two GitHub Environments were configured: staging and prod.

The staging environment does not require manual approval, allowing automatic deployment after changes are merged into main.

The prod environment requires approval from the designated reviewer, lcz111. Its deployment branch policy permits deployments only from main.

Administrator bypass was disabled for production. Self-review was permitted because this assignment was completed by a single student. In a real production team, independent reviewers and prevention of self-review would provide stronger separation of duties.

The deployment workflow uses environment-specific jobs and makes production dependent on successful staging deployment.

This ensures that production cannot proceed until staging succeeds and the required production approval is granted.

Evidence:

- evidence/environments.json
- evidence/prod-approval-pending.png
- evidence/prod-approval-approved.png


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

## Task 5 - Actual AWS Deployment

The deployment workflow is located at:

    .github/workflows/assignment1-deploy.yml

The workflow is triggered when relevant infrastructure changes are merged into the main branch. Evidence and report-only changes are excluded to avoid unnecessary deployments.

Each deployment job performs Terraform initialization, formatting checks, validation, planning, and application of the saved plan.

The dev environment was deployed manually from the workstation. Staging and production were deployed through GitHub Actions using environment-scoped AWS credentials.

### Deployment Execution

Pull request #14 was created to introduce the deployment workflow. All ten CI checks passed before the pull request was merged into main.

The merge triggered GitHub Actions workflow run 46066316355.

Workflow run:

https://github.com/lcz111/acs730-coursework/actions/runs/46066316355

The staging job completed automatically. The production job remained pending until manual approval was granted.

After approval, production deployment completed successfully.

### Deployment Results

| Environment | Deployment Method | Resources Added | Changed | Destroyed |
| --- | --- | --- | --- | --- |
| dev | Manual Terraform apply | 9 | 0 | 0 |
| staging | Automatic GitHub Actions deployment | 9 | 0 | 0 |
| prod | GitHub Actions with manual approval | 9 | 0 | 0 |

All three environments were deployed successfully using independent Terraform state files.

The dev web server was also tested using an HTTP request and returned the expected environment-specific HTML response.

### Deployment Challenges and Resolution

The pull request was initially blocked because the required Terraform gates check had not been triggered.

The existing Lab 5 CI workflow was updated to include Assignment 1 in its pull request path filters. This allowed the required checks to execute without disabling branch protection.

The pull request was merged only after all ten checks passed.

This demonstrated the importance of aligning workflow path filters with required branch protection checks.

### Deployment Evidence

- evidence/staging-apply.txt
- evidence/prod-apply.txt
- evidence/prod-approval-pending.png
- evidence/prod-approval-approved.png
- evidence/backend-state-keys.txt

## Task 6 - Secrets Management with SSM Parameter Store

An application configuration parameter was created manually in AWS Systems Manager Parameter Store before running Terraform.

The following command was executed on the workstation as a prerequisite:

    aws ssm put-parameter \
      --name "/acs730/assignment1/app-config" \
      --description "Application configuration for ACS730 Assignment 1" \
      --type String \
      --value "assignment1-web-v1" \
      --tier Standard \
      --region us-east-1

The reusable Terraform module reads the existing parameter using a data source:

    data "aws_ssm_parameter" "app_config" {
      name = var.ssm_parameter_name
    }

Terraform does not create or manage the lifecycle of this parameter. This separates application configuration management from infrastructure provisioning and avoids hardcoding configuration values in Terraform resources.

The parameter was successfully read during the dev deployment. The Terraform output matched the value retrieved directly from AWS Parameter Store.

The output is marked as sensitive to prevent accidental disclosure in normal Terraform output. However, sensitive values may still be stored in Terraform state, so access to the remote S3 backend must be restricted.

A non-sensitive demonstration value was used because the repository is public.

Evidence: evidence/ssm-parameter.txt


## Task 7 - CloudWatch Monitoring and Alarm

A CloudWatch metric alarm was implemented in the reusable Terraform module to monitor EC2 CPU utilization.

The alarm configuration is:

- Alarm name: acs730-a1-chengzeli-dev-cpu-high
- Namespace: AWS/EC2
- Metric: CPUUtilization
- Statistic: Average
- Threshold: Greater than 80 percent
- Period: 300 seconds
- Evaluation periods: 2
- Datapoints to alarm: 2
- Missing data treatment: missing
- Dimension: InstanceId of the deployed dev EC2 instance

The alarm enters the ALARM state when CPU utilization exceeds 80 percent for two consecutive five-minute evaluation periods.

The alarm is controlled by a Boolean module variable, allowing individual environments to enable monitoring without duplicating Terraform code.

For this assignment, the alarm was enabled only in dev to demonstrate monitoring functionality while minimizing AWS Learner Lab costs.

CPUUtilization was selected because EC2 publishes CPU metrics even when the application is idle.

The alarm was successfully created through Terraform. Its initial state was INSUFFICIENT_DATA while CloudWatch evaluated the available metric data.

After CloudWatch evaluated the actual EC2 CPU metrics, the alarm transitioned from INSUFFICIENT_DATA to OK at 21:18:09 UTC on November 27, 2026.

The two evaluated CPU utilization datapoints were approximately 0.227% and 0.194%, both below the configured threshold of 80%.

This confirms that the alarm is monitoring a real EC2 instance and evaluating actual AWS CloudWatch metrics. No alarm state was manually forced.

The alarm demonstrates metric monitoring and threshold evaluation. SNS notification actions were not configured.

Evidence:

- evidence/cloudwatch-alarm.json
- evidence/cloudwatch-alarm.png

## Task 8 - AWS-native vs GitHub Actions Recommendation

Both AWS-native CI/CD services, such as AWS CodePipeline and AWS CodeBuild, and GitHub Actions can automate Terraform deployments. However, their suitability depends on security requirements, operational costs, team experience, and network accessibility.

### 1. Identity and Security

AWS-native pipelines can use IAM service roles to access AWS resources without storing AWS access keys in an external platform. This provides centralized identity management within AWS.

GitHub Actions can achieve similar security through OIDC federation and temporary AWS credentials. In this assignment, environment-scoped temporary credentials were used because AWS Academy restricts IAM role creation. Production credentials were protected by a required reviewer and a main-only deployment branch policy.

In a real AWS account, I would replace the manually refreshed credentials with OIDC and separate least-privilege IAM roles for staging and production.

### 2. Cost and Runner Maintenance

GitHub-hosted runners provide managed execution environments without requiring the team to maintain dedicated EC2 runner instances. Standard hosted runners are available without execution-minute charges for public repositories such as this coursework repository.

AWS CodePipeline and CodeBuild are also managed services, but their costs depend on pipeline usage, build duration, and configuration.

For this small project with a limited AWS Learner Lab budget, GitHub-hosted runners reduce infrastructure management and avoid additional AWS build-service charges.

### 3. Team Experience and Development Workflow

The coursework already uses GitHub for source control, pull requests, automated testing, and deployment workflows.

GitHub Actions integrates these activities within the same platform. Developers can review infrastructure changes, inspect CI results, approve production deployments, and investigate deployment logs without switching between multiple services.

An AWS-native solution would require additional pipeline configuration and familiarity with CodePipeline, CodeBuild, and their IAM permissions.

### 4. Private Network Accessibility

AWS CodeBuild can be configured to access resources inside a VPC, making it suitable for deployments that require access to private databases or internal application endpoints.

Standard GitHub-hosted runners do not automatically have access to private AWS networks. If future deployments require private connectivity, the team would need an appropriate networking solution or self-hosted runners, which introduce additional security and maintenance responsibilities.

The current Terraform deployment communicates with AWS service APIs and does not require direct access to private application endpoints.

### 5. Deployment Governance

GitHub Environments provide environment-specific secrets, deployment branch restrictions, and manual approval gates.

These features were successfully demonstrated in this assignment. Staging deployed automatically after merging to main, while production waited for explicit approval.

AWS CodePipeline also supports manual approval actions and can provide strong deployment governance, particularly for organizations that centralize their operations within AWS.

### Final Recommendation

I recommend GitHub Actions for this project because it integrates with the existing repository, minimizes runner maintenance, supports environment-specific deployment controls, and meets the current network requirements.

The successful staging and production deployments demonstrate that this approach is practical for the current environment.

For a future production implementation, I would introduce OIDC federation, separate IAM roles, and independent production reviewers. If the organization later requires extensive VPC-internal access or centralized AWS governance, an AWS-native pipeline should be reconsidered.

## Conclusion

This assignment successfully demonstrated a multi-environment infrastructure deployment solution using Terraform, GitHub Actions, and AWS.

The reusable Terraform module reduced code duplication, while independent remote state files allowed dev, staging, and production infrastructure to be managed separately.

The successful deployment demonstrated that automation and security controls can work together. Staging was deployed automatically, while production required explicit approval before infrastructure changes were applied.

One important lesson from this assignment was that successful automation depends on more than correct Terraform code. Branch protection, workflow triggers, credential scope, and environment dependencies must also be configured consistently.

The initial pull request was blocked by a required CI check that had not been triggered. Resolving this issue without disabling branch protection demonstrated the importance of maintaining deployment governance while troubleshooting automation.

The SSM Parameter Store integration demonstrated how application configuration can be managed separately from infrastructure provisioning. CloudWatch also demonstrated the importance of verifying monitoring functionality using actual metric data rather than simply confirming that an alarm exists.

The current implementation has several limitations. AWS Academy restricts IAM role creation, requiring manually refreshed temporary credentials instead of OIDC federation. All three environments use small EC2 instances to minimize laboratory costs, and production approval is performed by a single student.

In a real production environment, I would implement OIDC federation, separate least-privilege IAM roles, independent production reviewers, private application subnets, and centralized monitoring with notification actions.

Overall, this assignment improved my understanding of infrastructure modularity, environment isolation, deployment governance, credential management, and operational monitoring. These practices provide a foundation for building more secure, maintainable, and reliable cloud infrastructure.
