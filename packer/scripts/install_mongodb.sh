#!/bin/bash
set -e

function instl_mongo
{
	echo "------Begin--------"
	echo $(date +"%y-%m-%d %T")
	echo "Add repositary key"
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
    echo "--------------------"
	echo "Add repositary MongoDB"
	echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list
	echo "--------------------"
	echo "Update the index of available packages"
	apt update
	echo "--------------------"
	echo "Install packages"
	apt install -y mongodb-org
	echo "--------------------"
	echo "Run MongoDB"
	systemctl start mongod
	echo "--------------------"
	echo "Add to autorun MongoDB"
	systemctl enable mongod
	echo "--------------------"
	echo "Check Mongo. Show status:"
	systemctl status mongod
	echo "-------End---------"
}
instl_mongo 2>&1 | tee -a install_mongo.log
