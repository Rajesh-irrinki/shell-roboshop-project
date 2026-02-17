#!/bin/bash

user_id=$UID
log_folder=/var/log/roboshop
log_file=$log_folder/$0.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $user_id -ne 0 ]; then
    echo "$R Please run the script with root access $N"
    exit 1
fi

mkdir -p $log_folder

validate() {
    if [ $1 -ne 0 ]; then
        echo "$2 ... $R FAILED $N" | tee -a $log_file
        exit 1
    else
        echo "$2 ... $G SUCCESS $N" | tee -a $log_file  
    fi 
}

cp rabbitmq /etc/yum.repos.d/rabbitmq.repo &>>$log_file
validate $? "Created Systemctl service"

dnf install rabbitmq-server -y &>>$log_file
validate $? "Installing rabbitmq-server"

systemctl enable rabbitmq-server
systemctl start rabbitmq-server
validate $? "Enabling and Starting rabittmq-server"

rabbitmqctl add_user roboshop roboshop123
validate $? "Add user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
validate $? "set permissions for user"

