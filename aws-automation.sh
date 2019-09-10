#!/bin/sh
echo 'Creating Network Segmnet
======================================='
#================================================Creating VPC================================================
read -p "$(tput setaf 2) Please enter cidr of vpc: $(tput sgr0)" cidr
read -p "$(tput setaf 2) Do you want to create public routetable (enter yes or no ) : $(tput sgr0)" pub_response
read -p "$(tput setaf 2) Do you want to create private routetable (enter yes or no ) : $(tput sgr0)" priv_response
read -p "$(tput setaf 2) enter public subnet cidr block (eg. 192.168.0.0/24) : $(tput sgr0)" pub_subnet_cidr
read -p "$(tput setaf 2) enter private subnet cidr block (eg. 192.168.0.0/24) : $(tput sgr0)" priv_subnet_cidr
read -p "$(tput setaf 2) enter name of Availability Zone  : $(tput sgr0)" az
listofaz=$(aws ec2 describe-availability-zones --filters Name=region-name,Values=ap-south-1|jq .AvailabilityZones[].ZoneName --raw-output)
existing_cidr=$(aws ec2 describe-vpcs --filters "Name=cidr,Values=$cidr" --query Vpcs[].CidrBlockAssociationSet[][CidrBlock][0]|jq .[0] --raw-output)
if [ $cidr == $existing_cidr ]
then
                echo "$(tput setaf 1)cidr already exist please use different cidr$(tput sgr0)"
                vpcid=$(aws ec2 describe-vpcs --filters "Name=cidr,Values=10.0.0.0/16" --query Vpcs[]|jq .[].VpcId --raw-output)
                echo 'VPC ID : ' $vpcid
fi

if [ $existing_cidr == null ]
then
    vpcid=$(aws ec2 create-vpc --cidr-block $cidr|jq .Vpc.VpcId --raw-output)
    echo 'VPC ID : ' $vpcid

#=================================================Creating InternetGateway=====================================
    echo "$(tput setaf 2) Creating InternetGateway $(tput sgr0)"
    igwid=$(aws ec2 create-internet-gateway|jq .InternetGateway.InternetGatewayId --raw-output)
    echo 'Internet_gateway ID :' $igwid
    echo "$(tput setaf 2) Attachng InternetGateway $(tput sgr0)"
    aws ec2 attach-internet-gateway --internet-gateway-id $igwid --vpc-id $vpcid
fi
#=============================================Creating public routetable=============================================
if [ $pub_response == yes ]
then
      echo "$(tput setaf 2)Creating Public Routetable $(tput sgr0)"
      pub_routetableid=$(aws ec2 create-route-table --vpc-id $vpcid|jq .RouteTable.RouteTableId --raw-output)
      echo "Public Route table ID:  $pub_routetableid $(tput setaf 3)<--------------- Please note this public route table id for further use $(tput sgr0)"
#=============================================creating public route ====================================================
      echo "$(tput setaf 2)Creating public route $(tput sgr0)"
      assoc_op=$(aws ec2 create-route --route-table-id $pub_routetableid  --destination-cidr-block 0.0.0.0/0 --gateway-id $igwid|jq .Return --raw-output)
      echo 'Public Route Association ID :' $assoc_op
#==============================================creating public subnet ===================================================

      pub_subnet_id=$(aws ec2 create-subnet --vpc-id $vpcid --availability-zone $az  --cidr-block $pub_subnet_cidr|jq .Subnet.SubnetId --raw-output)
      echo 'Public Subnet ID: ' $pub_subnet_id
      pub_assoc_routetbale_id=$(aws ec2 associate-route-table --route-table-id $pub_routetableid --subnet-id $pub_subnet_id|jq .AssociationId --raw-output)        echo 'Public route Association ID: ' $pub_assoc_routetbale_id
elif [ $pub_response == no ]
then
       read -p "$(tput setaf 2) please enter existing public routetable id (eg, rtb-xxxxxxxxx): $(tput sgr0)" routetable_id
       next_pub_subnet_id=$(aws ec2 create-subnet --vpc-id $vpcid --availability-zone $az  --cidr-block $pub_subnet_cidr|jq .Subnet.SubnetId --raw-output)
       echo 'Public Subnet ID : ' $next_pub_subnet_id
       pub_assoc_routetbale_id=$(aws ec2 associate-route-table --route-table-id $routetable_id --subnet-id $next_pub_subnet_id|jq .AssociationId --raw-output)
fi
#===================================================Creating private routetable===============================================
if [ $priv_response == yes ]
then
      echo "$(tput setaf 2)Creating Public Routetable $(tput sgr0)"
      priv_routetableid=$(aws ec2 create-route-table --vpc-id $vpcid|jq .RouteTable.RouteTableId --raw-output)
      echo "Private Route table ID:  $priv_routetableid $(tput setaf 3)<--------------- Please note this private route table id for further use $(tput sgr0)"
#=============================================creating private route ====================================================
      #echo "$(tput setaf 2)Creating public route $(tput sgr0)"
      #assoc_op=$(aws ec2 create-route --route-table-id $routetableid  --destination-cidr-block 0.0.0.0/0 --gateway-id $igwid|jq .Return --raw-output)
      #echo $assoc_op
#==============================================creating public subnet ===================================================

      priv_subnet_id=$(aws ec2 create-subnet --vpc-id $vpcid --availability-zone $az  --cidr-block $priv_subnet_cidr|jq .Subnet.SubnetId --raw-output)
      echo 'Private Subnet ID :' $priv_subnet_id
      priv_assoc_routetbale_id=$(aws ec2 associate-route-table --route-table-id $priv_routetableid --subnet-id $priv_subnet_id|jq .AssociationId --raw-output)
elif [ $priv_response == no ]
then
       read -p "$(tput setaf 2) please enter existing private routetable id (eg, rtb-xxxxxxxxx): $(tput sgr0)" priv_routetable_id
       next_priv_subnet_id=$(aws ec2 create-subnet --vpc-id $vpcid --availability-zone $az  --cidr-block $priv_subnet_cidr|jq .Subnet.SubnetId --raw-output)
       echo 'Private Subnet ID : ' $next_priv_subnet_id
       priv_assoc_routetbale_id=$(aws ec2 associate-route-table --route-table-id $priv_routetable_id --subnet-id $next_priv_subnet_id|jq .AssociationId --raw-output)
fi
