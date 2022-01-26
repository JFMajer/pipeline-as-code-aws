#!/bin/bash

echo "Install Jenkins stable release"
yum remove -y java
amazon-linux-extras install epel -y
yum update –y
#wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
yum upgrade -y
yum install jenkins java-1.8.0-openjdk-devel -y
java -version
systemctl daemon-reload
chkconfig jenkins on


yum install -y git
mkdir /var/lib/jenkins/.ssh
touch /var/lib/jenkins/.ssh/known_hosts
chown -R jenkins:jenkins /var/lib/jenkins/.ssh
chmod 700 /var/lib/jenkins/.ssh
mv /tmp/id_rsa /var/lib/jenkins/.ssh/id_rsa
chmod 600 /var/lib/jenkins/.ssh/id_rsa
chown -R jenkins:jenkins /var/lib/jenkins/.ssh/id_rsa

mkdir -p /var/lib/jenkins/init.groovy.d
mv /tmp/scripts/*.groovy /var/lib/jenkins/init.groovy.d
mv /tmp//config/jenkins /etc/sysconfig/jenkins
chmod +x /tmp//config/install-plugins.sh
bash /tmp/config/install-plugins.sh
service jenkins start