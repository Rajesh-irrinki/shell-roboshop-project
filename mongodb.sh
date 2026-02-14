#!/bin/bash

user_id=$UID 
log_folder=/var/log/roboshop
log_file=$log_folder/$0.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $user_id -ne 0 ]; then
   echo -e "$R Please run the script with root access $N " | tee -a $log_file
   exit 1
fi

mkdir -p $log_folder

validate() {
    if [ $1 -eq 0 ]; then
      echo -e "$2 is$G successful $N" | tee -a  $log_file
    else
      echo -e "$2 is$R failed $N " | tee -a $log_file
      exit 1
    fi
}

dnf list installed mongodb-org

if [ $? -ne 0 ]; then
    cp mongo.repo /etc/yum.repos.d/mongo.repo
    validate $? "copying mongodb configuration to yum.repos.d"
    echo "Mongodb installing......."
    dnf install mongodb-org -y &>> $log_file
    validate $? "Mongodb installing"
else
    echo -e "Mongodb is already installed $Y SKIPPING $N" | tee -a $log_file
    exit 1
fi

echo "Enabling the mongodb service" &>> $log_file
systemctl enable mongod &>> $log_file
validate $? "Enable mongod service"

echo "Mongodb service start" &>> $log_file
systemctl start mongod &>> $log_file
validate $? "Mongodb service start"

sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf &>> $log_file
validate $? "Modifying local host in mongod.conf file"

systemctl restart mongod
validate $? "Restart Mongod service"


