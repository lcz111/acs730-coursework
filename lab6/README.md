# ACS730 Lab 6 — Ansible Configuration Management and Golden AMI

## Overview

This lab demonstrates how Terraform, Ansible, AWS Systems Manager (SSM), and Packer can be used together to provision and configure AWS EC2 web servers. Terraform provisions the infrastructure, Ansible configures the application, and Packer creates a reusable Golden AMI.

## Infrastructure and Security

Terraform provisioned two Amazon Linux 2023 EC2 instances with the tags `Lab=lab6` and `Role=web`. Ansible used the AWS EC2 dynamic inventory plugin to discover these instances automatically instead of relying on hard-coded IP addresses.

I used AWS Systems Manager Session Manager to connect to the EC2 instances because it does not require opening inbound SSH port 22 or storing a long-lived private SSH key in GitHub repository secrets. The instances used the existing `LabInstanceProfile` and outbound connectivity for SSM access.

The Ansible SSM connection plugin also required an S3 bucket for temporary file transfers. The bucket and SSM connection configuration used the same AWS Region, `us-east-1`, to prevent region mismatch errors.

## Ansible Configuration and Idempotency

The Ansible `webserver` role creates a dedicated service user, configures the application directory, deploys a Jinja2-generated web page, and manages the web application through systemd.

The second Ansible run reported `changed=0` and `failed=0` on both instances. This demonstrates idempotency: the managed resources already matched the desired configuration, so Ansible did not need to modify them.

Using idempotent modules makes repeated deployments more predictable and reduces unnecessary changes in automated pipelines.

## Golden AMI and Performance Comparison

I used Packer to build a Golden AMI containing the preconfigured web server. The image was then tested by launching an EC2 instance and checking the HTTP response.

| Measurement | Terraform + Ansible | Packer Golden AMI |
| --- | --- | --- |
| Configuration method | Configure after provisioning | Configure during image build |
| Recorded duration | 34 seconds | 4 minutes 50 seconds |
| What the duration measures | Ansible convergence only | One-time Packer image build |
| EC2 launch-to-HTTP-ready time | Not measured | Not measured |
| HTTP verification | Successful | 200 OK |
| Ansible required after instance launch | Yes, for initial configuration | No |

The recorded Ansible convergence took 34 seconds. During this measurement, one instance required configuration changes while the other was already configured. Therefore, the result represents that particular convergence run rather than a complete fresh-instance deployment.

The Packer Golden AMI build took approximately 4 minutes and 50 seconds. The Golden AMI test instance returned HTTP status 200 without running an additional Ansible playbook after launch.

These two durations measure different stages of deployment. The Ansible duration excludes EC2 provisioning, while the Packer duration measures image creation rather than instance startup. Therefore, the available evidence does not establish an exact numerical improvement in boot-to-ready time.

## Trade-offs and Recommendation

### Terraform + Ansible Converge-on-Boot

This approach allows configuration changes to be applied directly through a reusable Ansible role. However, each newly deployed instance must wait for SSM registration and configuration tasks, and package installation can depend on external repositories being available.

### Packer Golden AMI

A Golden AMI moves configuration work into a one-time image-building process. Instances launched from that image can start with the application already installed, reducing the amount of configuration required after launch.

However, building and storing an AMI introduces additional costs, including build-instance usage and EBS snapshot storage. Golden AMIs can also become outdated, so they require regular rebuilding and security updates.

### Recommendation

I recommend Golden AMIs for environments that repeatedly launch many similar web servers because the configuration work can be reused across instances. For smaller environments or frequently changing applications, Terraform with Ansible may be easier to maintain.

The recommendation would change if image maintenance overhead exceeded the operational benefits of preconfigured instances.

## AMI and Snapshot Cleanup

Deregistering an AMI does not necessarily delete its underlying EBS snapshots. These snapshots can continue generating storage charges even after the AMI is deregistered.

Therefore, cleanup must include both deregistering the AMI and deleting its associated snapshots after confirming that they are no longer needed.

After completing the lab, I destroyed the Terraform-managed EC2 instances and security group, removed the temporary SSM S3 bucket, and verified that the Terraform state contained no remaining managed resources.

## Experiments

### Experiment 1 — Breaking Idempotency

**Prediction:** Without `creates`, I predicted that the shell task would report `changed=1` on the second run even if the directory already existed. After adding `creates`, I predicted that the second run would report `changed=0`.

**Result and Explanation:** The second run without `creates` reported `changed=1` on both EC2 instances, while adding `creates` resulted in `changed=0` on both instances. Ansible cannot automatically determine whether an arbitrary shell command changes the system, so `creates` provides a condition for skipping unnecessary execution.

**Cleanup:** I removed the experimental shell task and restored the original configuration. The final Ansible run reported `changed=0` on both instances.

### Experiment 2 — state: latest vs. state: present

**Prediction:** I predicted that changing the DNF package task from `state: present` to `state: latest` might report `changed=1` on the first run if newer packages were available, but the second run would report `changed=0` if no new updates appeared.

**Result and Explanation:** Both runs with `state: latest` reported `changed=0` on both EC2 instances, indicating that no package updates were applied during the experiment. The result can depend on the date because repositories may publish newer versions, and automatically installing them on every pipeline run could introduce unexpected changes or compatibility issues.

**Cleanup:** I restored `state: present` and reran the original Playbook. Both instances reported `changed=0`, confirming that the original configuration remained idempotent.

