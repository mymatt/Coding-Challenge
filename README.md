
## Recruitment Challenge

### Tools / Resources
- Orchestration - *Terraform*
- Configuration Management - *Ansible*
- Image Builds for Immutable Infrastructure - *Packer*

### Stages
There are 3 stages
1) Build Images with Packer and Provision with Ansible Roles
   - 2 Images (Bastion and Web Server)
2) Output Manifest file with AMI-ID's, then update Terraform Variables file
3) Create AWS Resources using Terraform (using newly created AMI's)

![Image Stages](https://github.com/mymatt/Coding-Challenge/blob/master/images/AfterPay_workflow.png)

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

![Image Account](https://github.com/mymatt/Coding-Challenge/blob/master/images/afterpay_account.png)

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

### Run
Ensure script is executable
```
chmod +x start.sh
```
Launch
```
./start.sh
```

### View Web Site
- The Load Balancer DNS is output to Command Line to retrieve e.g elbweb-886245521.ap-southeast-2.elb.amazonaws.com
- Enter into browser to view 'Hello Afterpay!'

### SSH
- Terraform generates key in terraform directory
- Public IP address of Bastion is output to Command Line to retrieve
- Transfer key to bastion
```
scp -i key_ec2.pem key_ec2.pem ubuntu@bastion_public_ip:~/
```
- ssh into bastion
```
ssh -i key_ec2.pem ubuntu@bastion_public_ip
```
- ssh into Web Server
```
ssh -i key_ec2.pem ubuntu@webserver_private_ip
```

### Ansible Roles
**Role 1 - Web**
- updates all packages
- pulls code from repository
- install apache
- install apache WSGI mod for serving Python app
- apache Security mod
- enable virtual site
- update apache config with new directory
- installs python requirements from repo
- installs/enables NTP (chronyd), telnet, mtr, tree

**Role 2 - Harden**
- disable IPv6
- sets max "open files" limit across all users/processes, soft & hard, to 65535
- SELinux
- SSH Security
- Firewall

*Configuration Note*
- modifying config files involves a mixture of bash scripting, templating, lineinfile
- tasks need to be idempotent, so there’s a risk when using shell, however, the desire was to provide some sed code
  In this case, a whole line is replaced, by matching the first part of the line, so idempotence is achieved
- Lineinfile with regexp to achieve idempotence
- Or alternatively use ansible template module with jinja2 variable substitution and move whole apache configuration file to server

### Packer
Creates 2 AMI's
1. Web Server
- Ansible Roles Harden and Web

2. Bastion
- Ansible Roles Harden

### Terraform - AWS

![Image Stages](https://github.com/mymatt/Coding-Challenge/blob/master/images/AfterPay_aws.png)

- 2 Availability Zones
- Public and Private Subnets (2 Each. 1 for each AZ for Redundancy)
- EC2 Instances for Bastion, Web Server
- Elastic Load Balancer (Classic)
- Auto Scaling Groups
- Internet Gateways
- NAT Gateways (redundant because of packer)

### Security Groups
- Bastion has ssh and icmp access to all security groups
- Web Server receives traffic only via Load Balancer
- Load Balancer is public facing

![Image Stages](https://github.com/mymatt/Coding-Challenge/blob/master/images/AfterPay_sec.png)

### Improvements
- CI/CD Pipeline to replace Bash Script
- Many additional hardening and security measures, only touched upon a few
- Migrate to Application Load Balancer from Classic
- No need for NAT Gateways because of Packer
- Use Molecule to test ansible role
- Use of Docker containers, ECS
