#!/bin/bash

SG_ID="sg-0f976eea1cc69544e"
AMI_ID="ami-0220d79f3f480ecf5"
DOMAIN_NAME="tzpcsystems.xyz"
DOMAIN_ZONE_ID="Z06013631BGH5ZPM28YZI"

for instance in $@
do

    INSTANCE_ID=$(
        aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query "Instances[0].InstanceId" \
        --output text 
        )


    if [ $instance == 'frontend' ];then
        IP=$( 
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[].Instances[].PublicIpAddress" \
            --output text 
        )

        RECORD_NAME=$DOMAIN_NAME # tzpcsystems.xyz
    else
        IP=$( 
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[].Instances[].PublicIpAddress" \
            --output text 
        )

        RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.tzpcsystems.xyz
    fi

    aws route53 change-resource-record-sets \
    --hosted-zone-id $DOMAIN_ZONE_ID \
    --change-batch '
    {
        "Comment":"Updating Records",
        "Changes":[
            {
                "Action":"UPSERT",
                "ResourceRecordSet":{
                    "Name":"'$RECORD_NAME'",
                    "Type":"A",
                    "TTL":1,
                    "ResourceRecords":[
                    {
                        "Value":"'$IP'"
                    }
                    ]
                }
            }
        ]
    }

    '

    echo "Instance $instance created with ID: $INSTANCE_ID and Public IP: $IP"

done

