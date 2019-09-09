#!/bin/sh
echo 'Creating Network Segmnet
======================================='
#================================================Creating VPC================================================
read -p "$(tput setaf 2)Please enter cidr of vpc: $(tput sgr0)" cidr
aws ec2 describe-vpcs --filters "Name=cidr,Values=$cidr" --query Vpcs[].CidrBlockAssociationSet[][CidrBlock][0]|grep $cidr
if [ $? == 0 ]
then
        echo "$(tput setaf 1)cidr already exist please use different cidr$(tput sgr0)"
exit 1
fi

#aws ec2 create-vpc --cidr-block $cidr
vpcid=$(aws ec2 create-vpc --cidr-block $cidr|jq .Vpc.VpcId --raw-output)
echo $vpcid
#=================================================Creating InternetGateway=====================================
igwid=$(aws ec2 create-internet-gateway|jq .InternetGateway.InternetGatewayId --raw-output)
echo $igwid
aws ec2 attach-internet-gateway --internet-gateway-id $igwid --vpc-id $vpcid
