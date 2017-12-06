#!/bin/bash

function initColours() {
	# Example of Use:
	#	RED='\033[0;31m'
	#	NC='\033[0m' # No Color
	#	echo -e "I ${RED}love${NC} different colours!"

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

function createRepo() {
	: '
	Add files to IPFS
		-q : Makes the output only contain hashes
		-r : Allows for directory
		tail -n1 : Ensures only the hash of the top folder is output
		`ipfs add -q -r $REPO | tail -n1` : Produces a hash
		/ipfs/ : Refers to somewhere in ipfs
	Must include "/" at the start of a folder
	'
	RESULT=$(ipfs files mkdir "/$WORKREPO")
	ipfs files cp "/ipfs/"`ipfs add -q -r $REPO | tail -n1` "/${WORKREPO}/${INITIAL}"
	tracker
}


function writeFile() {
	: '
	Write to a file in mfs
		-e : Creates the file if it does not exist
		-t : Truncates data in the file
	'
	getSize # Before
	ipfs files write -e -t "/$WORKREPO/$FILEPATH" "$FILEPATH"
	getSize # After
}


function pushRepo() {
	ipfs files mv "/$WORKREPO/.tmp" "/$WORKREPO/$REPO"
	tracker
}


function getSize() {
	: '
	Gets the size and cumululative size of a file or directory
		sed -n 2p : Gets the size of the file (--size does not work correctly)
		awk "{print $NF;}" : Separates on spaces
		--size : Is actually cumululative size
	'
	SIZE=$(ipfs files stat "/$WORKREPO/$FILEPATH" | sed -n 2p | awk '{print $NF;}')
	CUMSIZE=$(ipfs files stat --size "/$WORKREPO/$FILEPATH")
	echo "Size: $SIZE - Cumululative: $CUMSIZE"
}


function help() {
	echo -e "${LIGHTPURPLE}INFORMATION${NC}"
	echo -e "  To add, commit or push any files, the working directory must be the repository name"
	echo -e "\n${LIGHTPURPLE}USAGE${NC}"
	echo -e "  ./ipfsStorage.sh [[-options] <path>]"
	echo -e "\n${LIGHTPURPLE}ARGUMENTS${NC}"
	echo -e "  -r, --repository <path> : Create a new repository"
	echo -e "  -f, --writefile <path> : Write data to a file"
	echo -e "  -remove, --remove <path> : Removes a file or directory"
	echo -e "\n"
}


function missingArgs() {
	if [ $NUMARGS -lt 1 ]
		then
		echo -e "${RED}Error:${NC} Argument 'path' is required for option '$ARG'\n"
		helpArgs
		exit -1
	fi
}


function findCommit() {
	RESULT=$(ipfs files ls "/$WORKREPO")
	FIND=".tmp"
	# Checks if a commited file exists
	if echo "$RESULT" | grep -q "$FIND"
		then
		pushRepo
	else
		echo "${RED}Error:${NC} No commited files for project '$WORKREPO'"
	fi

}


function commitFiles() {
	COUNT=0
	for ARG in "$@"
	do
		C=${ARG:0:1}
		if [[ $C == '-' ]]
			then
			break
		fi
		let "COUNT++"
		echo "$ARG"
	done
	
	for (( i=0; i<$COUNT-1; i++))
	do
		shift # For every file in arguements
	done
}


function tracker() {
	DATE=`date '+%Y-%m-%d_%H-%M-%S'`
	LOGFILE=".tracker.log"
	echo "$DATE" >> "$LOGFILE"
	ipfs files write --create "/$WORKREPO/$LOGFILE" "$LOGFILE"
}


function locateFiles() {
	# See if the file path exists
	ipfs files ls "/$WORKREPO/$FILE"

}


if [ $# -eq 0 ]
	then
	echo "Invalid number of arguments"
	helpArgs
else
	NUMARGS=$#
fi

# Possible arguments
while test $# -gt 0
do
	ARG=$1
	# Argument 1
	case "$1" in
		# Working repository
		-x)
			WORKREPO="$2"
			shift
			;;
		# New Repository
		-r|--repository)
			missingArgs
			REPO="$2"
			INITIAL="$REPO"
			createRepo
			shift # Once for REPO ($2)
			;;
		# Write File
		-f|--writefile) 
			missingArgs
			FILEPATH="$2"
			writeFile
			shift # Once for REPO ($2)
			;;
		# Locate File
		-l|--locate)
			FILE=$2
			shift # Once for FILE ($2)
			;;
		# Commit an entire directory
		-cd|--commitDir)
			REPO="$2"
			INITIAL=".tmp"
			createRepo
			shift # Once for REPO ($2)
			;;
		# Commit files
		-cf|--commitFiles)
			echo "Commit multiple files is currently broken"
			echo "Use 'commit *' to commit the entire directory"
			exit 1
			shift # Once for "-cf" or "--commitFiles"
			commitFiles
			;;
		# Push
		-p|--push)
			REPO="$2"
			findCommit
			shift # Once for REPO ($2)
			;;
		# 
		-v) 
			echo "random length" > "test/test8.txt"
			echo 'v'
			;;
		# Remove file from repository
		-remove|--remove)
			missingArgs

			# Broken
			# echo "Error: Remove argument is broken"
			# exit -1

			PATH="$2"
			echo "Are you sure you want to remove the file from IPFS? (Y/n)"
			read answer
			
			if [[ $answer=="Y" ]]
				then
				result=ipfs files rm -r "$WORKREPO/$PATH"
				echo "File removed"
			else
				echo "File not removed"
			fi
			shift # Once for PATH ($2)
			;;

		#
		-help|--help)
			help
			;;

		# Any other argument
		*) echo -e "${RED}Error:${NC} Invalid argument '$1'\n"
			help
			;;
	esac
	shift
done