# Midterm Practice -- Notes

## Task 5: git hygiene

<!-- Replace this line with one sentence explaining why deleting the .tfstate
     file and the credential string in your latest commit is not sufficient
     by itself. -->

TODO





Deleting the Terraform state file and hardcoded credentials from the latest commit is not sufficient because they remain accessible in earlier Git commits, so the Git history must be cleaned and any exposed credentials must be revoked or rotated.
