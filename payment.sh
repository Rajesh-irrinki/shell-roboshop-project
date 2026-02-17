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

dnf install python3 gcc python3-devel -y &>>$log_file
validate $? "Installing python"

id roboshop &>>&log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "Adding Roboshop user"
else
    echo -e "User already exists ... $Y SKIPPING $N" | tee -a $log_file
fi

mkdir -p /app &>>$log_file
validate $? "Creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$log_file
validate $? "Downloading payment code"

cd /app &>>$log_file
validate $? "Moving to app directory"

rm -rf /app/* &>>$log_file
validate $? "Removing existing code"

unzip /tmp/payment.zip &>>$log_file
validate $? "Unzipping the code"

cd /app &>>$log_file
pip3 install -r requirements.txt &>>$log_file
validate $? "Downloading dependencies"

cp $script_dir/payment.service /etc/systemd/system/payment.service &>>$log_file
validate $? "Created systemctl service"

systemctl daemon-reload &>>$log_file
validate $? "Daemon reload"

systemctl enable payment &>>$log_file
systemctl start payment &>>$log_file
validate $? "Enabling & Starting payment"



