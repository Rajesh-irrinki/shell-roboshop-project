#!/bin/bash

user_id=$UID
log_folder=/var/log/roboshop
log_file=$log_folder/$0.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
script_dir=$PWD
mysql_host=mysql-server.rajeshirrinki.online

if [ $user_id -ne 0 ]; then
    echo -e "$R Please run the script with root access $N" | tee -a $log_file
    exit 1
fi

mkdir -p $log_folder

validate() {
    if [ $1 -ne 0 ]; then
        echo "$2 ...$R FAILED$N"
        exit 1
    else
        echo "$2 ...$G SUCCESS$N"
    fi
}

dnf install maven -y &>>$log_file
validate $? "Installing maven"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "roboshop user creation"
else
    echo -e "Roboshop user already exists ...$Y SKIPPING$N" | tee -a $log_file
fi

mkdir -p /app
validate $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$log_file
validate $? "Downloadinf shipping code"

cd /app 
validate $? "Moving to app directory"

rm -rf /app/* &>>$log_file
validate $? "Removing existing code from app directory"

unzip /tmp/shipping.zip &>>$log_file
validate $? "Unzipping shipping code"

mvn clean package &>>$log_file
validate $? "Download dependencies and Build the application"

mv target/shipping-1.0.jar shipping.jar  &>>$log_file
validate $? "Renaming jar file"

cp $script_dir/shipping.service /etc/systemd/system/shipping.service &>>$log_file
validate $? "Creating systemctl service"

systemctl daemon-reload &>>$log_file
validate $? "Daemon reload"

systemctl enable shipping &>>$log_file
systemctl start shipping &>>$log_file
validate $? "Enabling and Starting Shipping service"

dnf install mysql -y &>>$log_file
validate $? "Installing mysql"

mysql -h $mysql_host -u root -p RoboShop@1 -e 'use cities' &>>$log_file
if [ $? -ne 0 ]; then
    mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/schema.sql &>>$log_file
    mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$log_file
    mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$log_file
    validate $? "Loaded data to mysql"
else
    echo -e "Data already loaded to mysql ...$Y SKIPPING$N" | tee -a $log_file
fi

systemctl restart shipping &>>$log_file
validate $? "Restarting shipping service"



