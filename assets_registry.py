#!/usr/bin/python
import numpy as np
import pandas as pd
import xlsxwriter
import boto3
elbdata=[]
client = boto3.client('elb')
res1=client.describe_load_balancers()
list2=res1['LoadBalancerDescriptions']
elbit=iter(list2)
for i in elbit:
    elbdata.append([i['LoadBalancerName'],i['DNSName'],len(i['Instances'])])
df1=pd.DataFrame(elbdata,columns=['Loadbalancer-name','ELB-DNS-name','No-of-Instance'])
data=[]
ec2client=boto3.client('ec2')
ec2res=boto3.resource('ec2')
list1=ec2client.describe_instances()
list2=list1['Reservations']
dict={'t2.medium':{'cpu':2,'memory':4},'t2.large': {'cpu':2,'memory':8},'t2.small': {'cpu':1,'memory':2},'t2.micro':{'cpu':1,'memory':1},
        'r3.xlarge': {'cpu':4,'memory':30.50},'r3.large': {'cpu':2,'memory':15.25},'r3.xlarge': {'cpu':4,'memory':30.50},'t1.micro':{'cpu':1,'memory':0.613},
                  'm4.xlarge':{'cpu':4,'memory':16},'m4.large':{'cpu':2,'memory':8},'m4.2xlarge':{'cpu':8,'memory':32},'m3.xlarge':{'cpu':4,'memory':15},
                  'm3.medium':{'cpu':1,'memory':3.75},'m3.large':{'cpu':2,'memory':7.50},'m3.2xlarge':{'cpu':8,'memory':30},
                  'm1.small':{'cpu':1,'memory':1.7},'m1.medium':{'cpu':1,'memory':3.75},'i2.xlarge':{'cpu':4,'memory':30.5},'c4.2xlarge':{'cpu':8,'memory':15},
                  'c4.xlarge':{'cpu':4,'memory':7.5},'c4.4xlarge':{'cpu':16,'memory':30}}
it=iter(list2)
for j in it:
    if j['Instances'][0]['InstanceType'] in dict:
       cpu= dict[j['Instances'][0]['InstanceType']]['cpu']
       memory=dict[j['Instances'][0]['InstanceType']]['memory']
    it1=j['Instances'][0]['Tags']
    for k in it1:
        if k['Key']=='Name':
            sn=k['Value']
        elif k['Key']=='Role':
            prp=k['Value']
        elif k['Key']=='Environment':
            envi=k['Value']
        elif k['Key']=='Hostname':
            hostname=k['Value']
    op=ec2res.Instance(id=j['Instances'][0]['InstanceId'])
    #print  j['Instances'][0]['InstanceType'],",",envi,",",hostname,",",sn,",",prp,",",cpu,",",memory,",",j['Instances'][0]['Placement']['AvailabilityZone'],",",op.public_ip_address,",",op.private_ip_address,",",op.private_dns_name,",",j['Instances'][0]['VirtualizationType'],",",j['Instances'][0]['Architecture'],",",j['Instances'][0]['RootDeviceName'],",",j['Instances'][0]['RootDeviceType'],",",j['Instances'][0]['State']['Name']
    data.append([j['Instances'][0]['InstanceType'],envi,hostname,sn,prp,cpu,memory,j['Instances'][0]['Placement']['AvailabilityZone'],op.public_ip_address,op.private_ip_address,op.private_dns_name,j['Instances'][0]['VirtualizationType'],j['Instances'][0]['Architecture'],j['Instances'][0]['RootDeviceName'],j['Instances'][0]['RootDeviceType'],j['Instances'][0]['State']['Name']])

df=pd.DataFrame(data,columns=['Instance-Type','Environment','Hostname','Name','Purpose','vCPU','memoryGB','AvailabilityZone','Public-ip','Private-ip','PrivateDNSName','Virtualization','Architecture','rootDevice-name','rootDevice-type','status'])
df1=pd.DataFrame(elbdata,columns=['Loadbalancer-name','ELB-DNS-name','No-of-Instance'])
writer=pd.ExcelWriter('inventory.xlsx',engine='xlsxwriter')
df.to_excel(writer, sheet_name='Ec2')
df1.to_excel(writer, sheet_name='ELBs')
writer.save()
