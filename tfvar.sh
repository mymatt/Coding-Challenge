#!/bin/bash

# Example Use: ./tfvar.sh ec2profile=art account_ami_owner=notart

file=Terraform/io.tf
m="= "

while
[[ $# -gt 0 ]]
do
  arr=($(echo $1 | tr "=" "\n"))
  j="= \"${arr[1]}\""
  sed -i -e "/${arr[0]}/{n;s/$m.*$/$j/;}" $file
  shift
done
