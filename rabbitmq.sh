#!/bin/bash

user_id=$UID
log_folder=/var/log/roboshop
log_file=$log_folder/$0.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $user_id -ne 0 ]; then
    echo -e "$R Please run the script with root access $N"
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

cp rabbitmq /etc/yum.repos.d/rabbitmq.repo &>>$log_file
validate $? "Created Systemctl service"

dnf install rabbitmq-server -y &>>$log_file
validate $? "Installing rabbitmq-server"

systemctl enable rabbitmq-server &>>$log_file
systemctl start rabbitmq-server &>>$log_file
validate $? "Enabling and Starting rabittmq-server"

rabbitmqctl add_user roboshop roboshop123 &>>$log_file
validate $? "Add user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$log_file
validate $? "set permissions for user"

