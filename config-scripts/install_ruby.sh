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

