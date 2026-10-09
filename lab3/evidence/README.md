# Lab 3 Deployment Evidence

## 1. Terraform Plan on Pull Request

Workflow:
https://github.com/lcz111/acs730-coursework/actions/runs/37970507165

Event: pull_request

Result:
Plan: 0 to add, 1 to change, 0 to destroy.

Terraform Apply was not executed during the pull request.

## 2. Terraform Apply After Merge

Workflow:
https://github.com/lcz111/acs730-coursework/actions/runs/37971298776

Event: push to main

Result:
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

## 3. Verification

The AWS SSM Parameter /acs730/lab3/demo was originally created
from the EC2 workstation.

After merging Pull Request #3, GitHub Actions updated the same
resource using the shared Terraform S3 remote state.

Original value: Created from workstation
Updated value: Updated by GitHub Actions

No additional AWS resources were created.
