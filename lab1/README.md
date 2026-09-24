# Lab 1

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 1 in this folder.
The `create-security-group.sh` script creates a security group named `acs730-week1-sg`. It allows SSH access on port 22 only from the current public IP address using a /32 CIDR block.

The `create-instance.sh` script gets the latest Amazon Linux 2023 AMI ID and launches a t3.micro EC2 instance. The instance uses the LabInstanceProfile and is named `acs730-week1`.

The `delete-instance.sh` script searches for EC2 instances named `acs730-week1`. If an instance is found, the script terminates it. If no matching instance is found, it displays a message saying there is nothing to delete.

The `delete-security-group.sh` script deletes the `acs730-week1-sg` security group when it is no longer needed. This helps clean up the AWS resources created during the lab.
