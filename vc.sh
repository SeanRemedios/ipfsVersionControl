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
printf "Current IPFS Repository: ${CYAN}$WORKREPO${NC}\n\n"


function addFiles() {

	# Need to make sure they're not specifying something stupid
	if [[ "$DIRADD" == "$WORKREPO" || "$DIRADD" == "" ]]
		then
		REPO=$(basename $WORKREPO) # Get just the name of the repo
		#cd ".tmp" && mkdir "$REPO" && cd .. # Make sure the repo exists in .tmp
		# -ra : Recursively and all hidden files excluding those mentioned
		# Copy everything from the working dir to .tmp
		# Exclude any file from .vcignore
		rsync -ra --exclude ".tmp" --exclude ".DS_Store" --exclude-from ".vcignore" ./ ".tmp/"
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
	ALLFILES=$(find ".tmp/" 2>/dev/null -mtime -14 ! -iname ".DS_Store" | xargs -n 1 basename)
	if [[ $ALLFILES == "" ]]
		then
		printf "\tBranch is up-to-date with 'master' or staged for commit\n"
	else
		for FILE in $ALLFILES
		do
			EXIST=$(find . -name "$FILE" -not -path "./.tmp/*")
			printf "\t${GREEN}added: $FILE${NC}\n"
		done
	fi
	printf "\n"
	getExclusions
}


function missingArgs() {
	NEEDED="$2"
	if [[ $NUMARGS -lt "$1" ]]
		then
		printf "${RED}Error:${NC} Argument '$NEEDED' is required for option '$ARG'\n"
		helpArgs
		exit -1
	fi
}


function loadingBar() {
	printf "${RED}Loading:${NC} #####                     (33%%)\r"
	sleep 0.5
	printf "${RED}Loading:${NC} #############             (66%%)\r"
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


function helpArgs() {
	printf "\n"
	printf "${LIGHTPURPLE}INFORMATION${NC}\n"
	printf "  To add, commit or push any files, the working directory must be the repository name\n"
	printf "\n${LIGHTPURPLE}USAGE${NC}\n"
	printf "  vc [-options]\n"
	printf "\n${LIGHTPURPLE}OPTIONS${NC}\n"
	printf "  add : Add files/directories to be committed\n"
	printf "  status : See what files/directories are added and are excluded\n"
	printf "  commit : Commit files to be pushed to the repository\n"
	printf "  push : Push files to the IPFS repository\n"
	printf "  diff : See the difference between added files and repo files\n"
	printf "  pull [zip] : Pull a copy or a zipped of the repo locally\n"
	printf "  new : Create a new repository\n"
	printf "\n"
}

if [ $# -eq 0 ]
	then
	echo "Invalid number of arguments"
	helpArgs
else
	NUMARGS=$#
fi

ARG=$1
case "$1" in
	add)
		mkdir ".tmp" 2>/dev/null >/dev/null
		DIRADD="$2"
		addFiles
		loadingBar
		;;
	status)
		getStatus
		;;
	commit)
		missingArgs 3 "message"
		OPTION="$2"
		MESSAGE="$3"
		DIR=".tmp"
		if [[ ! -d "$DIR" ]]
			then
			printf "${RED}Error:${NC} No files added"
		else
			./ipfsStorage.sh -x "$WORKREPO" -c ".tmp" -m "$MESSAGE" &
			loadingBar
			printf "${GREEN}Success:${NC} Files committed"
			rm -rf "$DIR" 2>/dev/null >/dev/null
		fi
		shift # Once for "OPTION" ($2)
		shift # Once for "MESSAGE" ($3)
		;;
	push)
		./ipfsStorage.sh -x "$WORKREPO" -p "$WORKREPO"
		;;
	diff)
		printf "\n${RED}Error:${NC} 'vc diff' is currently broken"
		exit 1
		#./ipfsStorage.sh -x "$WORKREPO" -d
		;;	
	new)
		./ipfsStorage.sh -x "$WORKREPO" -r
		printf "\nCreating new repository: ${LIGHTBLUE}$WORKREPO${NC}...\n"
		loadingBar
		;;
	pull)
		ZIP="$2"
		if [[ $ZIP == "zip" ]]
			then
			# Zipped
			./ipfsStorage.sh -x "$WORKREPO" -U
		else
			# Non-zipped
			./ipfsStorage.sh -x "$WORKREPO" -u
		fi
		shift # Once for zip ($2)
		;;
	-help|--help|help)
		helpArgs
		;;
	*)
		;;
esac
shift