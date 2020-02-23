
## Recruitment Challenge

### Tools / Resources
Orchestration - *Terraform*
Configuration Management - *Ansible*
Image Builds for Immutable Infrastructure - *Packer*

### Stages
There are 3 stages
1) Build Images with Packer and Provision with Ansible Roles
   - 2 Images (Bastion and Web Server)
2) Output Manifest file with AMI-ID's, then update Terraform Variables file
3) Create AWS Resources using Terraform (using newly created AMI's)

![Image Stages](/Users/M/Employment/DevOps/Project/AfterPay.png)

#### Objective
Fully Automate all 3 stages
