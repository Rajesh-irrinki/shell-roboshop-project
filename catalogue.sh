#!/bin/bash

user_id=$UID 
log_folder=/var/log/roboshop
log_file=$log_folder/$0.log
mongodb_server=mongodb.rajeshirrinki.online
script_dir=$PWD
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
    if [ $1 -eq 0 ]; then
      echo -e "$2 is$G SUCCESS $N" | tee -a $log_file
    else
      echo -e "$2 is$R FAILED $N" | tee -a $log_file
      exit 1
    fi
}

dnf module disable nodejs -y &>> $log_file
validate $? "Disabled default nodejs version"

dnf module enable nodejs:20 -y &>> $log_file
validate $? "Enabling Nodejs 20"

dnf install nodejs -y &>> $log_file
validate $? "Installing Nodejs"

id roboshop &>> $log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "System user creation"
else
    echo -e "Roboshop user is already exists..$Y SKIPPING $N"
fi

mkdir /app 
validate $? "/app directory creation"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $log_file
validate $? "Downloading catalogue code"

cd /app
validate $? "Moving to /app directory"

rm -rf /app/*
validate $? "Removing existing code"

unzip /tmp/catalogue.zip &>> $log_file
validate $? "unzipping catalogue code"
 
npm install &>> $log_file 
validate $? "Installing Dependencies"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service
validate $? "Setup SystemD Catalogue Service"

systemctl daemon-reload &>> $log_file
validate $? "Daemon-reload"

systemctl enable catalogue &>> $log_file
systemctl start catalogue &>> $log_file
validate $? "Catalogue service start"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Mongo.repo copying to yum.repos.d"

dnf install mongodb-mongosh -y &>> $log_file
validate $? "Installing Mongo client"

INDEX=$(mongosh --host $mongodb_server --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    mongosh --host $mongodb_server </app/db/master-data.js
    VALIDATE $? "Loading products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue"