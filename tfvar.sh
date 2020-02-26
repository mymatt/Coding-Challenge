#!/bin/bash

# Example Use: ./tfvar.sh awsprofile=art awsregion=notart awsowner=art awsbucket=notart

declare -a FileArray=("Terraform/main.tf" "Terraform/io.tf" )
m="= "

while
[[ $# -gt 0 ]]
do
  arr=($(echo $1 | tr "=" "\n"))
  for val in ${FileArray[@]}; do
    sed -i '' "s/${arr[0]}/${arr[1]}/g" $val
  done
  shift
done
