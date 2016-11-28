#! /bin/bash

# the parameter to the script is the version of jitsi-meet we want to install
# this is in situation where we do not want the latest or we want to install
# an older version

# sourcing this script will provide few variables that can be used:
#  - jitsi_videobridge, jicofo, jitsi_meet_web, jitsi_meet_web_config, jitsi_meet_prosody
#    these variables can be used to extract the dependent package versions to the
#    provided jitsi-meet package version
#  - APT_COMMAND that can be used to install/downgrade to provided jitsi-meet version
#

DEPENDENCIES=`apt-cache show jitsi-meet=$1 | grep '^Depends:' | cut -f2- -d:`

REGEXP="([[:alpha:]-]*) \(= (.*)\)"
getAPTParams () {
	RET=""
	IFS=',' read -ra ADDR <<< "$1"
		for i in "${ADDR[@]}"; do
			if [[ $i =~ $REGEXP ]]; then
				RET="$RET ${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
				# replace - with _ for the variable name
				VAR_NAME=`echo ${BASH_REMATCH[1]} | tr - _`
				eval "$VAR_NAME=${BASH_REMATCH[2]}"
			fi
		done   
} 

APT_COMMAND="apt-get install "
getAPTParams "$DEPENDENCIES"
APT_COMMAND="$APT_COMMAND $RET"
