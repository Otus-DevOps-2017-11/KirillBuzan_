#!/bin/bash

function instl_ruby
{
	echo "------Begin--------"
    echo $(date +"%y-%m-%d %T")
    echo "Install Ruby"
	sudo apt update
	sudo apt install -y ruby-full ruby-bundler build-essential
	echo "--------------------"
	echo "Check Ruby. Show version:"
	ruby -v
	echo "--------------------"
	echo "Check Bundle. Show version:"
	bundle -v 
	echo "-------End---------"
}
instl_ruby 2>&1 | tee -a install_ruby.log

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

function deploy
{
	echo "------Begin--------"
	echo $(date +"%y-%m-%d %T")
	echo "Download git repositary"
	git clone https://github.com/Otus-DevOps-2017-11/reddit.git
	echo "--------------------"
	echo "Add relation"
	cd reddit && bundle install
	echo "--------------------"
	echo "Run AppServer"
	puma -d
	echo "--------------------"
	echo "Check AppServer. Show aux port"
	ps aux | grep puma
    echo "--------End---------"
}
deploy 2>&1 | tee -a deploy.log
