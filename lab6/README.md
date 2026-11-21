# Lab 6

Instructions for this section will be provided in class and on Blackboard when we reach it.

Put your work for Lab 6 in this folder.

## Experiments

### Experiment 1 — Breaking Idempotency

**Prediction:** Without `creates`, I predicted that the shell task would report `changed=1` on the second run even if the directory already existed. After adding `creates`, I predicted that the second run would report `changed=0`.

**Result and Explanation:** The second run without `creates` reported `changed=1` on both EC2 instances, while adding `creates` resulted in `changed=0` on both instances. Ansible cannot automatically determine whether an arbitrary shell command changes the system, so `creates` provides a condition for skipping unnecessary execution.

**Cleanup:** I removed the experimental shell task and restored the original configuration. The final Ansible run reported `changed=0` on both instances.

### Experiment 2 — state: latest vs. state: present

**Prediction:** I predicted that changing the DNF package task from `state: present` to `state: latest` might report `changed=1` on the first run if newer packages were available, but the second run would report `changed=0` if no new updates appeared.

**Result and Explanation:** Both runs with `state: latest` reported `changed=0` on both EC2 instances, indicating that no package updates were applied during the experiment. The result can depend on the date because repositories may publish newer versions, and automatically installing them on every pipeline run could introduce unexpected changes or compatibility issues.

**Cleanup:** I restored `state: present` and reran the original Playbook. Both instances reported `changed=0`, confirming that the original configuration remained idempotent.

