#!/bin/bash

user_id=$UID
log_folder=/var/log/roboshop
log_file=$log_folder/$0.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

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

dnf install mysql-server -y &>>$log_file
validate $? "Installing mysql-server"

systemctl enable mysqld &>>$log_file
systemctl start mysqld  &>>$log_file
validate $? "Enabling and Starting mysql-server service"

mysql_secure_installation --set-root-pass RoboShop@1 &>>$log_file
validate $? "Changed the default root password"

