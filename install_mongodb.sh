#!/bin/bash

function instl_mongo
{
	echo "------Begin--------"
	echo $(date +"%y-%m-%d %T")
	echo "Add repositary key"
	sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
    echo "--------------------"
	echo "Add repositary MongoDB"
	sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
	echo "--------------------"
	echo "Update the index of available packages"
	sudo apt update
	echo "--------------------"
	echo "Install packages"
	sudo apt install -y mongodb-org
	echo "--------------------"
	echo "Run MongoDB"
	sudo systemctl start mongod
	echo "--------------------"
	echo "Add to autorun MongoDB"
	sudo systemctl enable mongod
	echo "--------------------"
	echo "Check Mongo. Show status:"
	sudo systemctl status mongod
	echo "-------End---------"
}
instl_mongo 2>&1 | tee -a install_mongo.log
