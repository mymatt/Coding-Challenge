
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

### Bash Scripts
1) Script for updating Terraform variables
   - Credentials Profile, Account Owner ID
2) Script for Launching each of the 3 Stages
   - automates all stages

### Installation Requirements
- Packer https://packer.io/
- Terraform https://www.terraform.io/

### AWS Requirements
- Account Setup
AWS account must be created

![Image Account](/Users/M/Employment/DevOps/Project/aws_account.png)

- Generate Credentials on AWS
Retrieve Access and Secret Keys, and Account Number

- Store credentials here: ~/.aws/credentials
```
[profile_name]
aws_access_key_id = ""
aws_secret_access_key = ""
region = ap-southeast-2
```
- ~/.bash_profile option:
```
export AWS_ACCESS_KEY_ID=''
export AWS_SECRET_ACCESS_KEY=''
export AWS_REGION='ap-southeast-2'
export AWS_PROFILE=''
export AWS_ACCOUNT=''
```
- tfvar.sh will update necessary terraform variables

Ensure script is executable
```
chmod +x tfvar.sh
```
Run script
```
./tfvar.sh -v ec2profile=art account_ami_owner=notart
```
