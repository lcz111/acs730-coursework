
# Lab 1

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 1 in this folder.
The `create-security-group.sh` script creates a security group named `acs730-week1-sg`. It allows SSH access on port 22 only from the current public IP address using a /32 CIDR block.

The `create-instance.sh` script gets the latest Amazon Linux 2023 AMI ID and launches a t3.micro EC2 instance. The instance uses the LabInstanceProfile and is named `acs730-week1`.

The `delete-instance.sh` script searches for EC2 instances named `acs730-week1`. If an instance is found, the script terminates it. If no matching instance is found, it displays a message saying there is nothing to delete.

The `delete-security-group.sh` script deletes the `acs730-week1-sg` security group when it is no longer needed. This helps clean up the AWS resources created during the lab.

## Experiments

Experiment 2
predict:I guess that changing the CIDR from `/32` to `/24` will increase the address range from 1 IP
 address to 256 IP addresses, so more devices could potentially access SSH port 22.

what I saw:AWS changed the SSH source to 100.53.110.0/24."CidrIpv4": "100.53.110.0/24"

Experiment 3
predict:I predict that running the security group deletion script a second time will return "no such group"

what I saw:A error.
An error occurred (InvalidGroup.NotFound) when calling the DeleteSecurityGroup operation:
 The security group 'acs730-week1-sg' does not exist in default VPC 'vpc-0d87b3c5adb6f49d0'
