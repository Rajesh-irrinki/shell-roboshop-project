#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0238a21d11979a649"
DOMAIN="rajeshirrinki.online"

for INSTANCE_NAME in $@
do 
  INSTANCE_ID=$(
    aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text
  )

  if [ $INSTANCE_NAME == "frontend" ]; then
    IP=$(
        aws ec2 describe-instances \
        --filters "Name=instance-id,Values=$INSTANCE_ID" \
        --query 'Reservations[].Instances[].PublicIpAddress' \
        --output text
        )
    echo "Public IP address: $IP"
  else
    IP=$(
        aws ec2 describe-instances \
        --filters "Name=instance-id,Values=$INSTANCE_ID" \
        --query 'Reservations[].Instances[].PrivateIpAddress' \
        --output text
        )
    echo "Private IP address: $IP"
  fi
  
  {
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
        "Name": "$INSTANCE_NAME.$DOMAIN",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$IP"
          }
        ]
      }
    }
      ]
   }

done
