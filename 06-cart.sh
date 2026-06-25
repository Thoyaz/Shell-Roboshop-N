#!/bin/bash

CURRENT_DIR=$(pwd)
USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MONGO_SERVER=mongodb.tzpc.site

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


dnf module disable nodejs -y &>>$LOGS_FILE
dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling nodejs 20 module"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing Node.js"

id roboshop &>>$LOGS_FILE

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding roboshop system user"
else
    echo -e "$Y roboshop system user already exists $N" | tee -a $LOGS_FILE
fi


mkdir -p /app &>>$LOGS_FILE

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip 
cd /app 
unzip /tmp/cart.zip

cd /app 
npm install 

cp $CURRENT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOGS_FILE

systemctl enable cart 
systemctl start cart &>>$LOGS_FILE

systemctl daemon-reload &>>$LOGS_FILE
