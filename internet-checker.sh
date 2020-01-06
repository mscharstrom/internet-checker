#!/bin/bash

# Author: Mikael Schärström
# Web: www.scharstrom.com
# Free for use
# Description: Checks for internet connectivity. Saving logs and
# sends email when internet goes down and up. For email, make sure
# you have ssmtp and  mailutils installed and set up.
# Summary for the period and states the new external IP.

# Declaring variables
TESTURL="8.8.8.8"                   		 	  # Url to test against
CURRENTDATE=$(date "+%T %Y-%m-%d")  	 		  # Time and date
LOGFILE="/home/pi/logs/internet-checker.log"      	  # Path to log file
PIDFILE='/var/git/internet-checker/internet-checker.pid'  # PID to not start more instances of the script

# Setup for PID file so that we dont get millions
# of instances of our application when internet
# goes down.

if [ -f $PIDFILE ]
then
	PID=$(cat $PIDFILE)		# Read PID file
	ps -p $PID > /dev/null 2>&1	# Find processes for our $PID
	if [ $? -eq 0 ]			# If found, exit with 0, if not exit with 1.
	then
		echo "Process already running"
		exit 1			# If ps exit code is 0, exit with 1.
	else
					# Process not found assuming not running
		echo $$ > $PIDFILE
		if [ $? -ne 0 ]
		then
			echo "Could not create PID file"
			exit 1
		fi
	fi
else
	echo $$ > $PIDFILE
	if [ $? -ne 0 ]
	then
		echo "Could not create PID file"
		exit 1
	fi
fi


# Log when internet goes up again, add a while statement for infinite loop.
# Make the function exit when we have internet. Dont forget sleep X seconds and
# rm $PIDFILE after a successful execution.

function create() {
	while true; do
		if nc -dzw1 $TESTURL 443; then
			echo "Internet OK: $(date "+%T %Y-%m-%d")" >> ${LOGFILE}
			echo "========================" >> ${LOGFILE}
			echo "" >> ${LOGFILE}
			mail -s "Internet Status" mikael.scharstrom@gmail.com < ${LOGFILE}
			rm $PIDFILE	# Kill the PID process
			exit 1
		else
			sleep 5		# Sleep 5 seconds.
			create		# Run the function again until we have internet
		fi
	done

}


# Main function
while true; do
	if nc -dzw1 $TESTURL 443; then
		echo "CRITICAL INTERNET FAILURE!" > ${LOGFILE}
		echo "" >> ${LOGFILE}
		echo "========================" >> ${LOGFILE}
		echo "Internet FAILED: ${CURRENTDATE}" >> ${LOGFILE}
		exit 1	
	else
		create
	fi
done



