#!/bin/bash

CURRENT_DIR=$(pwd)
USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MONGO_SERVER=mongodb.tzpcsystems.xyz

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y
VALIDATE $? "Disabling Node.js module"

dnf module enable nodejs:20 -y
VALIDATE $? "Enabling nodejs 20 module"

dnf install nodejs -y
VALIDATE $? "Installing Node.js"

id roboshop &>>$LOGS_FILE

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding roboshop system user"
else
    echo -e "$Y roboshop system user already exists $N" | tee -a $LOGS_FILE
fi


mkdir -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
cd /app 
rm -rf /app/*
VALIDATE $? "Cleaning /app directory"
unzip /tmp/catalogue.zip
VALIDATE $? "Extracting catalogue zip file"

npm install 

cp $CURRENT_DIR/catalogue.service /etc/systemd/system/catalogue.service
systemctl daemon-reload
systemctl enable catalogue  &>>$LOGS_FILE
systemctl start catalogue
VALIDATE $? "Starting and enabling catalogue"

cp $CURRENT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y
VALIDATE $? "Installing MongoDB Shell"

CHECK_DB=$(mongosh --host $MONGO_SERVER --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $CHECK_DB -le 0 ]; then
    mongosh --host $MONGO_SERVER </app/db/master-data.js
    VALIDATE $? "Loading products"
else
    echo -e "$Y Database already exists $N" | tee -a $LOGS_FILE
fi

systemctl restart catalogue
VALIDATE $? "Starting catalogue service"