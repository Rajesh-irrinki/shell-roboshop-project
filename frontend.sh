#!/bin/bash

user_id=$UID
log_folder=/var/log/roboshop
log_file=$log_folder/$0.sh
R="\e[31m"
G="\e[32m"
Y="\e[33m"

if [ $user_id -ne 0 ]; then
    echo -e "$R Please run the script with root access $N" | tee -a $log_file
    exit 1
fi

mkdir -p $log_folder

validate () {
    if [ $1 -ne 0 ] ; then
        echo "$2 ...$R FAILED $N" | tee -a $log_file
        exit 1
    else
        echo "$2 ...$G SUCCESS $N" | tee -a $log_file
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

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
validate $? "Downloading the Frontend code"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
validate $? "Unzipping the Frontend code"

sed -i ""