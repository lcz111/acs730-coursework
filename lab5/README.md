# Lab 5

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 5 in this folder.


## Why for_each here and count there

I used `for_each` for the public subnets and route table associations because these resources have stable, meaningful keys such as `a` and `b`. Each resource can be identified by its key, so adding or removing a subnet does not shift the indexes of other resources. This makes the Terraform configuration easier to maintain and reduces unnecessary infrastructure changes.

I used `count` for the optional S3 artifact bucket because the requirement is simply to enable or disable one resource using a Boolean variable. When `create_artifact_bucket` is true, Terraform creates one bucket; otherwise, it creates none.

I also used `count` for the AMI data source to skip the real AWS AMI lookup when running against LocalStack. The `one()` function in `outputs.tf` safely handles the optional bucket by returning its name when present or `null` when absent.
