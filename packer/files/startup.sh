#!/bin/bash
set -e
function instl_ruby
{
	echo "------Begin--------"
    echo $(date +"%y-%m-%d %T")
    echo "Install Ruby"
	apt update
	apt install -y ruby-full ruby-bundler build-essential
	echo "--------------------"
	echo "Check Ruby. Show version:"
	ruby -v
	echo "--------------------"
	echo "Check Bundle. Show version:"
	bundle -v 
	echo "-------End---------"
}
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
function deploy
{
	echo "------Begin--------"
	echo $(date +"%y-%m-%d %T")
	echo "Create App_puma service"
	mv app_puma.service /etc/systemd/system
	systemctl enable app_puma
	echo "--------------------"
	echo "Download git repositary"
	git clone https://github.com/Otus-DevOps-2017-11/reddit.git
	echo "--------------------"
	echo "Add relation"
	cd reddit && bundle install	
	echo "--------------------"
	echo "Start App_Puma"	
	systemctl start app_puma
	echo "--------------------"
	echo "Check AppServer. Show aux port"
	ps aux | grep puma
	systemctl status app_puma
    echo "--------End---------"
}
instl_ruby 2>&1 | tee -a install_ruby.log
instl_mongo 2>&1 | tee -a install_mongo.log
deploy 2>&1 | tee -a deploy.log