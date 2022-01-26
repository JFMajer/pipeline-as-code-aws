#!/bin/bash

echo "Install Java JDK"
yum remove -y java
amazon-linux-extras install epel
yum install java-1.8.0-openjdk-devel -y
java -version

echo "Install Docker engine"
yum update -y
yum install docker -y
usermod -aG docker ec2-user
systemctl enable docker

echo "Install git"
yum install -y git