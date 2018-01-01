#!/bin/bash

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
