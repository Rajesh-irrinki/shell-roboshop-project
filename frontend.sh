#!/bin/bash

user_id=$UID
log_folder=/var/log/roboshop
log_file=$log_folder/$0.sh
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
    if [ $1 -ne 0 ] ; then
        echo -e "$2 ...$R FAILED $N" | tee -a $log_file
        exit 1
    else
        echo -e "$2 ...$G SUCCESS $N" | tee -a $log_file
}

dnf module disable nginx -y &>>$log_file
validate $? "Disbaling nginx default version"

dnf module enable nginx:1.24 -y &>>$log_file
validate $? "Enabling Nginx 1.24"

dnf install nginx -y &>>$log_file
validate $? "Installing Nginx"

systemctl enable nginx &>>$log_file
systemctl start nginx &>>$log_file
validate $? "Enable and start Nginx service"

rm -rf /usr/share/nginx/html/* &>>$log_file
validate $? "Removing existing Nginx configuration"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$log_file
validate $? "Downloading the Frontend code"

cd /usr/share/nginx/html &>>$log_file
validate $? "Moving to nginx configuration directory"

unzip /tmp/frontend.zip &>>$log_file
validate $? "Unzipping the Frontend code"

cp $script_dir /etc/nginx/nginx.conf &>>$log_file
validate $? "Reverse Proxy config creation"

systemctl restart nginx &>>$log_file
validate $? "Nginx service restarted"