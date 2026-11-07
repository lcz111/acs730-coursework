# Lab 5

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 5 in this folder.


## Why for_each here and count there

I used `for_each` for the public subnets and route table associations because these resources have stable, meaningful keys such as `a` and `b`. Each resource can be identified by its key, so adding or removing a subnet does not shift the indexes of other resources. This makes the Terraform configuration easier to maintain and reduces unnecessary infrastructure changes.

I used `count` for the optional S3 artifact bucket because the requirement is simply to enable or disable one resource using a Boolean variable. When `create_artifact_bucket` is true, Terraform creates one bucket; otherwise, it creates none.

I also used `count` for the AMI data source to skip the real AWS AMI lookup when running against LocalStack. The `one()` function in `outputs.tf` safely handles the optional bucket by returning its name when present or `null` when absent.


## Experiments

### Experiment 1: `count` vs `for_each` on Subnets


**Prediction:** With `count`, removing the middle CIDR from three subnets would shift the last subnet from index `[2]` to `[1]`, causing an unnecessary replacement. With `for_each`, removing key `b` should leave keys `a` and `c` unchanged.

**Observation:** The LocalStack `count` plan showed `2 to add, 1 to change, 4 to destroy`, including replacement of subnet `[1]` and deletion of subnet `[2]`. The `for_each` plan showed `0 to add, 1 to change, 2 to destroy`, deleting only subnet `["b"]` and its route table association.

**Explanation:** `count` identifies resources by numerical position, so removing a middle element shifts later indexes and causes unnecessary replacements. `for_each` uses stable keys, allowing Terraform to preserve unaffected resources. Both plans also showed an EC2 in-place update. All temporary configuration changes were restored after the experiment.



### Experiment 2: Delete `depends_on`

Prediction: Removing depends_on from the EC2 instance should not change the number of resources in the Terraform plan because it changes dependency ordering rather than resource attributes.

Observation: Both LocalStack plans showed Plan: 10 to add, 0 to change, 0 to destroy, confirming that removing the explicit dependency did not change the planned resource actions.

Explanation: Without depends_on, Terraform may create the EC2 instance before the public route table associations are complete, potentially causing the Nginx installation to fail because internet access is not yet available. LocalStack does not fully simulate EC2 boot processes or real network connectivity, so this potential race condition is not detected by the plan. The original depends_on was restored after the experiment.

## Why Not Plan and Apply Against Real AWS on Every Pull Request?

Running Terraform against real AWS on every pull request can introduce security risks, unexpected costs, and unintended infrastructure changes. Pull requests may contain unreviewed code, so automatically granting AWS deployment permissions could expose cloud resources to unauthorized modifications.

LocalStack provides a safer environment for testing Terraform configurations without creating or deleting real AWS resources. Terraform formatting, validation, and LocalStack-based checks can run during pull request CI. Real AWS deployments should require appropriate permissions, code review, and controlled approval before applying infrastructure changes.
