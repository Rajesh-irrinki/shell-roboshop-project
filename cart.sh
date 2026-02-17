#!/bin/bash

user_id=$UID
log_folder=/var/log/roboshop
log_file=$log_folder/$0.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
script_dir=$PWD

if [ $user_id -ne 0 ]; then
    echo -e "$R Please run the script with root access $N" | tee -a $log_file
    exit 1
fi

mkdir -p $log_folder

validate() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ...$R FAILED$N" | tee -a $log_file
        exit 1
    else
        echo -e "$2 ...$G SUCCESS$N" | tee -a $log_file
    fi
}

dnf module disable nodejs -y &>>$log_file
validate $? "Disbaling Nodejs default version"

dnf module enable nodejs:20 -y &>>$log_file
validate $? "Enabling Nodejs 20"

dnf install nodejs -y &>>$log_file
validate $? "Installing Nodejs"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "Roboshop user creation"
else
    echo -e "Roboshop user already exists ...$Y SKIPPING $N" | tee -a $log_file
fi

mkdir -p /app 
validate $? "Creating app directory" 

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$log_file
validate $? "Downloading cart code"

cd /app 
validate $? "Moving to app directory"

rm -rf /app/*
validate $? "Removing existing code"

unzip /tmp/cart.zip &>>$log_file
validate $? "Unzipping code in app directory"

npm install &>>$log_file
validate $? "Installing dependencies"

cp $script_dir/cart.service /etc/systemd/system/cart.service
validate $? "Created systemctl service"

systemctl daemon-reload
systemctl enable cart 
systemctl start cart
validate $? "Enabling and Starting cart service"