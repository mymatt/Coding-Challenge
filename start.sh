#!/usr/bin/env bash
set -e

ami_setup(){
  set -x

  MAN=manifest/manifest.json

  # run packer, specifiying which ansible roles to use
  cd Packer
  packer build -var $1 -var $2 pk_t.json

  # check for manifest file for ami_id
  while [ ! -f ${MAN} ]
  do
    sleep 0.4
  done

  #extract AMI_ID from manifest file
  AMI_ID=$(jq -r '.builds[-1].artifact_id' ${MAN} | cut -d ":" -f2)

  # remove manifast for next iteration
  rm manifest/*

  #update ami id variable for EC2 resource in terraform variables file
  AMI_TYPE=$3
  sed -i -e "/${AMI_TYPE}/{n;s/= .*$/= \"${AMI_ID}\"/;}" Terraform/io.tf
  set +x
}

# Create AMI's and Pass AMI_ID's to Terraform

echo "---------------------------------------------------"
echo "Running Packer - Creating AMI's"
echo "---------------------------------------------------"

# Create Bastion AMI
echo "***** Creating Bastion AMI..."
ami_setup "'roles=harden'" "'name=bastion'" 'bastion_ami_id'

# Create Web AMI
echo "***** Creating Web AMI..."
ami_setup "'roles=harden,web'" "'name=web'" 'web_ami_id'

# run Terraform

echo "---------------------------------------------------"
echo "Running Terraform"
echo "---------------------------------------------------"

cd ../Terraform
echo "***** Terraform Initializing..."
terraform init

echo "***** Terraform Creating Plan..."
terraform plan -out plan.terraform

echo "***** Terraform Apply..."
terraform apply plan.terraform
rm plan.terraform
