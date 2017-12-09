#!/bin/bash

function initColours() {
	# Example of Use:
	#	RED='\033[0;31m'
	#	NC='\033[0m' # No Color
	#	printf "I ${RED}love${NC} different colours!"

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
	ipfs files cp "/ipfs/"`ipfs add -q -r $REPO | tail -n1` "/$WORKREPO/${INITIAL}"
	#tracker "date '+%Y-%m-%d_%H-%M-%S'"
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
	DATE=$(date '+%Y-%m-%d_%H-%M-%S')
	tracker " -- $DATE\n"
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


function helpArgs() {
	printf "${LIGHTPURPLE}INFORMATION${NC}\n"
	printf "  To add, commit or push any files, the working directory must be the repository name\n"
	printf "\n${LIGHTPURPLE}USAGE${NC}\n"
	printf "  ./ipfsStorage.sh [[-options] <path>]\n"
	printf "\n${LIGHTPURPLE}ARGUMENTS${NC}\n"
	printf "  -r, --repository <path> : Create a new repository\n"
	printf "  -f, --writefile <path> : Write data to a file\n"
	printf "  -remove, --remove <path> : Removes a file or directory\n"
	printf "\n"
}


function missingArgs() {
	if [[ $NUMARGS -lt "$1" ]]
		then
		printf "${RED}Error:${NC} Argument 'path' is required for option '$ARG'\n"
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
		getHash
		printf "${GREEN}Success:${NC} Files pushed\n"
		printf "To ${PURPLE}$HASH${NC} - master -> master"
	else
		printf "${RED}Error:${NC} No commited files for project '$WORKREPO'\n"
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
	DATA="$1"
	LOGFILE=".tracker.log"
	printf "$DATA" >> "$LOGFILE"
	#ipfs files write --create "/$WORKREPO/$LOGFILE" "$LOGFILE"
}


function locateFiles() {
	# See if the file path exists
	ipfs files ls "/$WORKREPO/$FILE"

}


function getHash() {
	RESULT=$(ipfs files ls -l "/$WORKREPO")
	HASH=$(echo $RESULT | cut -d " " -f 2)
}


function pullFiles() {
	PATHTOPULL="$1"
	getHash
	ipfs get -o="$PATHTOPULL" "/ipfs/$HASH"
}


function zipFiles() {
	zip -r "$WORKREPO".zip "$HOME/Downloads/$WORKREPO" 2>/dev/null >/dev/null
	cp "$WORKREPO.zip" "$HOME/Downloads"
	rm -f "./$WORKREPO.zip"
	rm -rf "$HOME/Downloads/$WORKREPO"
	loadingBar
}


function getDiff() {
	printf "\n"
	pullFiles "../$WORKREPO-Diff" 2>/dev/null >/dev/null

	cd ..
	#diff -qNr "$WORKREPO-Diff/" "$WORKREPO/.tmp/"
	#rsync -avunc $WORKREPO-Diff/*/ $WORKREPO/.tmp/*/
	#rsync -rvunc --delete --exclude-from "$WORKREPO/.vcignore" "$WORKREPO-Diff"/*/ "$WORKREPO/.tmp"/*/
	cd "$WORKREPO"

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
	# cd ..
	# diff -rq "$WORKREPO" "$WORKREPO/.tmp"/* -X "$WORKREPO/.vcignore"
	# 															# SOURCE 			#TARGET
	# rsync -rvunc --delete --exclude-from "$WORKREPO/.vcignore" "$WORKREPO"/ "$WORKREPO/.tmp"/*/
	# echo $RESULT
	# cd "$WORKREPO"
}


function loadingBar() {
	printf "\n"
	printf "${RED}Zipping:${NC} #####                     (33%%)\r"
	sleep 0.75
	printf "${RED}Zipping:${NC}: #############             (66%%)\r"
	sleep 0.75
	printf "${GREEN}Complete:${NC} #######################   (100%%)\r"
	printf '\n'
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
			ipfs files mkdir "/$WORKREPO"
			shift # Once for REPO ($2)
			;;
		# Write File
		-f|--writefile) 
			missingArgs 1
			FILEPATH="$2"
			writeFile
			shift # Once for REPO ($2)
			;;
		# Locate File
		-l|--locate)
			missingArgs 1
			FILE="$2"
			shift # Once for FILE ($2)
			;;
		# Commit an entire directory
		-c|--commitDir)
			missingArgs 1
			REPO="$2"
			INITIAL=".tmp"
			# Remove previous
			ipfs files rm -r /"$WORKREPO" 2>/dev/null >/dev/null
			createRepo
			shift # Once for REPO ($2)
			;;
		# Commit files
		-e|--commitFiles)
			echo "Commit multiple files is currently broken"
			echo "Use 'commit *' to commit the entire directory"
			exit 1
			missingArgs 1
			shift # Once for "-cf" or "--commitFiles"
			commitFiles
			;;
		# Push
		-p|--push)
			missingArgs 1
			REPO="$2"
			findCommit
			shift # Once for REPO ($2)
			;;
		# Pull non-zip
		-u|--pull) 
			printf "\n"
			pullFiles "$HOME/Downloads/$WORKREPO"
			;;
		# Pull zip
		-U|--pull-zip)
			printf "\n"
			pullFiles "$HOME/Downloads/$WORKREPO"
			zipFiles
			;;
		# Difference between two repos
		-d|--difference)
			getDiff
			;;
		# Remove file from repository
		-remove|--remove)
			missingArgs 1

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
		# Message for commit
		-m|--message)
			MESSAGE="$2"
			tracker "$MESSAGE"
			shift # Once for "$2"
			;;
		# Help
		-h|-help|--help|help)
			helpArgs
			;;

		# Any other argument
		*) printf "${RED}Error:${NC} Invalid argument '$1'\n"
			helpArgs
			;;
	esac
	shift
done