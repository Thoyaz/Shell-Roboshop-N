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


dnf module disable redis -y &>>$LOGS_FILE
dnf module enable redis:7 -y &>>$LOGS_FILE
VALIDATE $? "Enabling redis 7 module"

dnf install redis -y &>>$LOGS_FILE
VALIDATE $? "Install redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' /etc/redis.conf -e 's/protected-mode/ c protected-mode no' &>>$LOGS_FILE
VALIDATE $? "Change config of redis"

systemctl enable redis  &>>$LOGS_FILE
systemctl start redis  &>>$LOGS_FILE
VALIDATE $? "start the redis service"
