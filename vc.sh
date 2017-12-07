#!/bin/bash

function initColours() {
	# Example of Use:
	#	RED='\033[0;31m'
	#	NC='\033[0m' # No Color
	#	echo -e "I ${RED}love${NC} different colours!"

	# No colour (Resets colour)
	NC='\033[0m'

	BLACK='\033[0;30m'
	RED='\033[0;31m'
	GREEN='\033[0;32m'
	ORANGE='\033[0;33m'
	BLUE='\033[0;34m'
	PURPLE='\033[0;35m'
	CYAN='\033[0;36m'
	LIGHTGRAY='\033[0;37m'

	DARKGRAY='\033[1;30m'
	LIGHTRED='\033[1;31m'
	LIGHTGREEN='\033[1;32m'
	YELLOW='\033[1;33m'
	LIGHTBLUE='\033[1;34m'
	LIGHTPURPLE='\033[1;35m'
	LIGHTCYAN='\033[1;36m'
	WHITE='\033[1;37m'
}

initColours
WORKREPO=${PWD##*/}
printf "Current IPFS Repository: ${CYAN}$WORKREPO${NC}\n"


function addFiles() {

	# Need to make sure they're not specifying something stupid
	if [[ "$DIRADD" == "$WORKREPO" || "$DIRADD" == "" ]]
		then
		REPO=$(basename $WORKREPO) # Get just the name of the repo
		#cd ".tmp" && mkdir "$REPO" && cd .. # Make sure the repo exists in .tmp
		# -ra : Recursively and all hidden files excluding those mentioned
		# Copy everything from the working dir to .tmp
		# Exclude any file from .vcignore
		rsync -ra --exclude ".tmp" --exclude ".DS_Store" --exclude-from ".vcignore" . ".tmp/"
	fi
}


function getExclusions() {
	echo "Excluded Files:"
	while IFS='' read -r line || [[ -n "$line" ]]; do
    	SUBSTRING=${line:0:2}
    	if [[ $SUBSTRING == "::" ]]
    		then
    		continue
    	fi
    	printf "\t${RED}$line${NC}\n"
	done < ".vcignore"
}


function getStatus() {
	echo -e "Added files and directories:"
	ALLFILES=$(find ".tmp/VersionControl" -mtime -14 ! -iname ".DS_Store" | xargs -n 1 basename)
	for FILE in $ALLFILES
	do
		EXIST=$(find . -name "$FILE" -not -path "./.tmp/*")		
		printf "\t${GREEN}added: $FILE${NC}\n"
	done
	printf "\n"
	getExclusions
}


function loadingBar() {
	printf "${RED}Loading:${NC} #####                     (33%%)\r"
	sleep 0.5
	printf "${RED}Loading:${NC}: #############             (66%%)\r"
	sleep 0.5
	printf "${GREEN}Complete:${NC} #######################   (100%%)\r"
	printf '\n'
}


function loadingDots() {
	printf '          \r'
	printf 'Loading: .\r'
	sleep 0.5
	printf 'Loading: ..\r'
	sleep 0.5
	printf 'Loading: ...\r'
	sleep 0.5
	printf '             \r'
}


case "$1" in
	add)
		rm -rf ".tmp"
		mkdir ".tmp"
		DIRADD="$2"
		addFiles
		printf "\n"
		loadingBar
		printf "Files added successfully!\n"
		;;
	status)
		getStatus
		;;
	commit)
		./ipfsStorage.sh -x "$WORKREPO" -c ".tmp"
		;;
	push)
		./ipfsStorage.sh -x "$WORKREPO" -p "$WORKREPO"
		;;
	diff)
		printf "\n${RED}Error:${NC} 'vc diff' is currently broken"
		exit 1
		: '
		rsync looks at the differences between all the files and directories
			-r : Recursive
			-c : Skip based on checksum, not mod-time & size
			-v : Increase verbosity
			-n : Dry-run (Do not actually do anything)
			-u : skip files that are newer in target
			--delete : Checks for files that are only in source
			--exclude-from : Does not check files listed in that file
			Need "/" at the end of each directory
		'
		cd ..
		# diff -rq "$WORKREPO" "$WORKREPO/.tmp"/* -X "$WORKREPO/.vcignore"
																	# SOURCE 			#TARGET
		rsync -rvunc --delete --exclude-from "$WORKREPO/.vcignore" "$WORKREPO"/ "$WORKREPO/.tmp"/*/
		# echo $RESULT
		cd "$WORKREPO"
		;;	
	new)
		./ipfsStorage.sh -x "$WORKREPO" -r "$WORKREPO"
		;;
	test)
		getExclusions
		;;
	*)
		;;
esac
shift