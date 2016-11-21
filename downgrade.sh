#! /bin/bash

# the parameter to the script is the version of jitsi-meet we want to install
# this is in situation where we do not want the latest or we want to install
# an older version
PRE_DEPENDENCIES=`apt-cache show jitsi-meet=$1 | grep '^Pre-Depends:' | cut -f2- -d:`
DEPENDENCIES=`apt-cache show jitsi-meet=$1 | grep '^Depends:' | cut -f2- -d:`

REGEXP="([[:alpha:]-]*) \(= (.*)\)"
getAPTParams () {
	RET=""
	IFS=',' read -ra ADDR <<< "$1"
		for i in "${ADDR[@]}"; do
		    if [[ $i =~ $REGEXP ]]; then
		    	RET="$RET ${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
	    	fi
		done   
} 

APT_COMMAND="apt-get install "
getAPTParams "$PRE_DEPENDENCIES"
APT_COMMAND="$APT_COMMAND $RET"
getAPTParams "$DEPENDENCIES"
APT_COMMAND="$APT_COMMAND $RET"

echo $APT_COMMAND
