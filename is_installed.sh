#!/bin/bash

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'

# return 1 if global command line program installed, else 0
function program_is_installed() {
	# set to 1 initially
	local return_=1
	# set to 0 if not found
	type $1 >/dev/null 2>&1 || { local return_=0; }
	# return value
	echo "$return_"
}

# display a message in red with a cross by it
function echo_fail() {
	PROGRAM=$1
	printf "${RED}✘ ${PROGRAM}${NC}"
}

# display a message in green with a tick by it
function echo_pass() {
	PROGRAM=$1
	printf "${GREEN}✔ ${PROGRAM}${NC}"
}

# echo pass or fail
# example
# echo echo_if 1 "Passed"
# echo echo_if 0 "Failed"
function echo_if() {
	RESULT=$1
	PROGRAM=$2
	if [ $RESULT == 1 ]
		then
		echo_pass $PROGRAM
	else
		echo_fail $PROGRAM
	fi
}


# command line programs
NPM=$(program_is_installed npm)
IPFS=$(program_is_installed ipfs)
printf "npm    $(echo_if $NPM)\n"
printf "ipfs   $(echo_if $IPFS)\n"

if [ $NPM -ne 1 ]
	then
	printf "Installing nvm...\n"
	# Get NVM first
	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash
	printf "Finished!"
	printf "Installing npm...\n"
	# Install npm and node
	nvm install node
	printf "Finished"
fi
if [ $IPFS -ne 1 ]
	then
	printf "Installing IPFS...\n"
	# Install ipfs
	npm install ipfs
	loading
	printf "Finished!"
fi


printf "\nEnter in the following command to your .bashrc then restart your terminal to start using vc:\n"
printf "\t${CYAN}alias vc=./vc.sh${NC}\n"
exit 1

# BROKEN

# RESULT=$(alias vc 2>/dev/null >/dev/null)
# if [[ "$RESULT" == "" ]]
# 	then
# 	printf "\nYou can now start using vc!\n"
# else
# 	"" >> ~/.bashrc
# 	"# Version Control Command by Sean - Be Careful" >> ~/.bashrc
# 	alias vc=./vc.sh >> ~/.bashrc
# 	printf "Restart your terminal to start using vc"
# fi
