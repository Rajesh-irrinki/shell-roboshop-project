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

validate () {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ...$R FAILED $N" | tee -a $log_file
        exit 1
    else
        echo -e "$2 ...$G SUCCESS $N" | tee -a $log_file
    fi
}

dnf module disable redis -y &>>$log_file
dnf module enable redis:7 -y &>>$log_file
validate $? "Enabling Redis 7"

dnf install redis -y  &>>$log_file
validate $? "Installing Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf  &>>$log_file
validate $? "Allowing remote connections"

systemctl enable redis  &>>$log_file
systemctl start redis  &>>$log_file
validate $? "Enabling and starting Redis service"