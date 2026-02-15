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

validate () {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ...$R FAILER $N" | tee -a $log_file
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $log_file
    fi
}

dnf module disable nodejs -y &>>$log_file
validate $? "Disabling default Nodejs version"

dnf module enable nodejs:20 -y &>>$log_file
validate $? "Enabled Nodejs 20"

dnf install nodejs -y
validate $? "Installing Nodejs"  &>>$log_file

id roboshop
if [ $? -eq 0 ]; then
    echo -e "Roboshop user already exists ...$Y SKIPPING $N" | tee -a $log_file
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Roboshop user creation"
fi

mkdir -p /app
validate $? "app directory created" 

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$log_file
validate $? "Downloading user code"

cd /app 
validate $? "Moving to /app directory"

rm -r /app/* &>>$log_file
validate $? "Removing existing code in app directory"

unzip /tmp/user.zip &>>$log_file
validate $? "Unzipping code"

npm install &>>$log_file
validate $? "Installing dependencies"

cp $script_dir/user.service /etc/systemd/system/user.service 
validate $? "Creating User service" 

systemctl daemon-reload &>>$log_file
systemctl enable user &>>$log_file
systemctl start user &>>$log_file
validate $? "Enabling & staring User service"

