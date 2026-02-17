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
        echo -e "$2 ... $R FAILED $N" | tee -a $log_file
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $log_file
    fi
}

dnf install golang -y &>>$log_file
validate $? "Installing Golang"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "Roboshop user creation"
else 
    echo -e "Roboshop user already exists ... $Y SKIPPING $N" | tee -a $log_file
fi

mkdir -p /app 
validate $? "Creating app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip  &>>$log_file
validate $? "Downloading dispatch code"

cd /app
validate $? "Moving to app directory"

rm -rf /app/*
validate $? "Removing existing code in app directory"

unzip /tmp/dispatch.zip &>>$log_file
validate $? "Unzipping code in app directory"

go mod init dispatch  &>>$log_file
validate $? "Initializing dispatch module"

go get &>>$log_file
validate $? "Installing dependencies"

go build &>>$log_file
validate $? "Building Dispatch"

cp $script_dir/dispatch.service /etc/systemd/system/dispatch.service &>>$log_file
validate $? "Dispatch systemctl service creation"

systemctl daemon-reload &>>$log_file
validate $? "Daemon reload"

systemctl enable dispatch &>>$log_file
systemctl start dispatch &>>$log_file
validate $? "Enabling and Starting systemctl service"