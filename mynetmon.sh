#!/bin/bash

##############################################################
#  Script     : mynetmon.sh
#  Author     : brunnerrick@hotmail.com
#  Date       : 09/15/2017
#  Last Edited: 10/25/2017, brunnerrick@hotmail.com
#  Description: Monitor and report on given IP  or URL to detect Internet outage
##############################################################
# Purpose:
# - To aid in monitoring and reporting on Internet connections
#   by monitoring latency of a URL or IP.
#   Utilizing a target threshold the script will announce when latecy above
#   the threashold (default = 100ms) as well as when there is no PING response
#
# Requirements and Syntax:
# - See showhelp '-h' for usage requiremnts
#
# Future Enhancements:
# - break checkinternet into smaller functions
# - Ability to create a config file defaults on first run when apropriate usage
#   is not provided
# - pull monitoring IP's / URL and configuration settings a config file
# - spawn and control multiple terminal windows based on configuration file.
# - Allow modification of configuration file
# Notes:
# - only tested with OSX 10.12 and above
#
# COPYRIGHT Notice
# Copyright (C) 2017 Rick Brunner
# This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program.  If not, see <http://www.gnu.org/licenses/>.
##############################################################

# set global variables
# -----------------------
#readonly PROGNAME=$(basename $0)
readonly PROGNAME=${0}
#readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"
readonly ARGC="$#"
# default latency highwather threshold to monitor
LATENCYHW=100
LOG_File=""
TIMESTAMP=0
HOSTTOCHECK=""
AUDIBLE=0
OUTFILE=""
FREQUENCY=1
 # variable used for log file to capture csv output

 printcopyright () {

  mynotice="$0  Copyright (C) 2017  Rick Brunner \n
 This program comes with ABSOLUTELY NO WARRANTY;
 This is free software, and you are welcome to use and redistribute it
 under certain conditions, see <http://www.gnu.org/licenses/> \n"

 	printf "____________________________________________________________\n"
 	printf "$mynotice\n"
  printf "____________________________________________________________\n\n"
 }

#checkusage and  print help if not correct.
# called by main()
checkusage() {

	#copy ARGS to a local array
	local args=($ARGS)
	for i in "${!args[@]}"; do
	#case "${args[i]}" in
	case ${args[$i]} in

			# note need to add logic to pull the parameters
			'' ) #skip if element is empty
					continue ;;
			-a ) AUDIBLE=1 ;;
			-f ) FREQUENCY="${args[$i+1]}" ;;
			-h ) showhelp ; exit;;
			-o ) OUTFILE="${args[i+1]}";; # get the string for the csv outfile
			-t ) TIMESTAMP=1 ;;
			-l ) LATENCYHW=${args[i+1]} ;; # get the Latency threshold value
			* ) HOSTTOCHECK=${args[i]} ;;
		esac
	done
}

#print usage help
#called by checkusage()
showhelp(){

	printf "\n"
	printf "____________________________________________________________\n"
	printf "Usage: $0 [-at] [-o <output.csv>] <ping host> \n"
	printf "____________________________________________________________\n"
	printf "  Required inputs\n"
	printf "    IP or fully qualified DNS address to test \n"
	printf "  Optional inputs\n"
	printf "    -a audtible alert\n"
	printf "    -f <integer> how often to check in seconds\n"
	printf "    -h help \n"
	printf "    -o <outfile> output monitoring capture file in csv format\n"
	printf "    -t add timestamp to output\n"
	printf "    -l <integer> latency warning threshold [default=100]"
	printf "\n"
	printf " Example:\n"
	printf " >./trcrout.sh -a -t -l 80 -f 5 -o dslgateway.csv 66.11.253.1"
	printf "____________________________________________________________\n\n"

}

# log's outupt to Global variable $Outfile which is passed as an argument when starting the script
# Called by mytraceroute() and checkinternet()

logit()
{
	local myoutputstring=""
	local timestamp""

	if [ $TIMESTAMP = 1 ]; then
			# Calculate date (not totally accurate)
			myoutputstring=$(date +"%m-%d-%y %r")
	fi

	if [ "$OUTFILE" != "" ]; then
		printf "$myoutputstring $1 $2 $3 $4 $5 $6 \n" | tee -a $OUTFILE
	else
		printf "$myoutputstring $1 $2 $3 $4 $5 $6 \n"
	fi

}
#
mytraceroute ()

{
traceroute -m 10  -w 3 $1 | while read line; do
		#printf "line:$line\n\n"
		# Skip header
    #printf "$line\n"
		logit ",$1,0,$line"
  done

}
# Core functional logic, checks internent connectivity for the given IP or URL being monitored.
# called by main()


checkinternet()
{
	trap echo 0
		#set trc route done flag to 0
		mstime=0
		trcdone=0
		internet=1
		latencywarning=0

		local header="time,ip,latency,error"
		local output=""
		output="HOSTTOCHECK=$HOSTTOCHECK, FREQUENCY=$FREQUENCY, TIMESTAMP=$TIMESTAMP, \n AUDIBLE=$AUDIBLE, OUTFILE=$OUTFILE LATENCYWARNING=$LATENCYHW"
		if [ "$OUTFILE" != "" ]; then
			printf "$header \n" | tee -a $OUTFILE
			printf "$output \n"
		else
			printf "$header \n"
			printf "$output \n"
		fi

		ping -i $FREQUENCY  $HOSTTOCHECK | while read line; do


		# Skip header
		[[ "$line" =~ ^PING ]] && continue

		# Skip non-positive responses
				# [[ ! "$line" =~ "bytes from" ]] && continue

				# Check for up condition
				# Set Internet trigger, internet down
				if [[ "$line" =~ "bytes from" ]];
				then

						# Extract address field
						addr=${line##*bytes from }
						addr=${addr%%:*}


						# Extract IP address
						if [[ "$addr" =~ (\(|\)) ]]; then
								ip=${addr##*(}
								ip=${ip%%)*}
						else
								ip=$addr
						fi

						# Extract seq
						seq=${line##*icmp_seq=}
						seq=${seq%% *}


						# Extract time - Latency
						time=${line##*time=}
						time=${time%% *}
						mstime=${time%.*}
						#printf "time=$time  mstime=$mstime LW:$LATENCYWARNING  LATENCYHW:$LATENCYHW \n\n\n"

						#if high latency and flag is not set, warn and set flag
						if [ $mstime -gt $LATENCYHW ] && [ $latencywarning -eq 0 ];
						then
							output=",$ip,$time,High Latency ms=$time"
							if [ $AUDIBLE = 1 ]; then
								echo -n $(say "Warning High Latency of $time milliseconds") # OSX Text-To-Speech
							fi
							logit $output
							latencywarning=1
						else
							# if we previously had High Letency but latency is back below the High water mark... reset the flag else increase the occurance and run
							# traceroute
							if [ $mstime -gt $LATENCYHW ]; then
								output=",$ip,$time,High Latency: Latencywarning=$latencywarning performing traceroute"
								logit $output
								mytraceroute $ip
								latencywarning=$(($latencywarning + 1))
							else
								if [ $latencywarning -gt 0 ]; then
									output=",$ip,$time,Latency back down to ms=$time"
									if [ $AUDIBLE = 1 ]; then
										echo -n $(say "Latency back below $LATENCYHW milliseconds, currently at $time milliseconds") # OSX Text-To-Speech
									fi
									logit $output
								latencywarning=0
								fi
							fi
						fi


						# Calculate date (not totally accurate)

						output=",$ip,$time"

						logit $output

						if [[ ${internet} -eq 0 ]]; then     # edge trigger -- was down now up
							if [ $AUDIBLE = 1 ]
							then
								echo -n $(say "Internet back up") # OSX Text-To-Speech
							fi
								# Internet is up
								output=",$ip,0,Internet back up"
								logit $output
								internet=1
								trcdone=0
							fi

		else
		# TIMEOUT or some fault in path
				if [[ ${internet} -eq 1 ]]; then   # edge trigger -- was up now down
						 # Internet is down
						 internet=0
						if [[ ${trcdone} -eq 0 ]]; then   # if we have not done a  trcrt report Lets do it
							if [ $AUDIBLE = 1 ]; then # if Audible Alert is on
								echo -n $(say "Internet Down") # OSX Text-to-Speech
							fi
								output=",$ip,0,INTERNET DOWN, performing traceroute"
								logit $output
								mytraceroute $ip
						fi
				else
						output=",$ip,0,...still down"
						logit $output
				fi

		fi
	done
}


main()
	{
		#echo "args:$ARGS"
		printcopyright
		checkusage
		checkinternet

}

main
