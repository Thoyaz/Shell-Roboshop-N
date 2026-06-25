#!/bin/bash

CURRENT_DIR=$(pwd)
USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MYSQL_SERVER=mysql.tzpc.site

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

dnf install python3 gcc python3-devel -y
VALIDATE $? "Installing Python3 and dependencies"

id roboshop &>>$LOGS_FILE

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding roboshop system user"
else
    echo -e "$Y roboshop system user already exists $N" | tee -a $LOGS_FILE
fi

mkdir -p /app &>>$LOGS_FILE
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
cd /app 
unzip /tmp/payment.zip

cd /app 
pip3 install -r requirements.txt

cp $CURRENT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOGS_FILE

systemctl enable payment 
systemctl start payment
VALIDATE $? "Starting payment service"

systemctl daemon-reload
VALIDATE $? "Reloading systemd daemon"

