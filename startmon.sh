#!/bin/bash
##############################################################
#  Script     : startmon.sh
#  Author     : brunnerrick@hotmail.com
#  Date       : 09/15/2017
#  Last Edited: 10/25/2017, brunnerrick@hotmail.com
#  Description: Simple script to kick off multiple terminal sessions using mynetmon.sh
##############################################################
# Purpose:
# - Companion script to mynetmon.sh to allow starting multilple mynetmon.sh
#   scripts to monitor multiple IP's in the networkl path ( i.e both sides )
#   of a router, first hop or gateway,  etc..
#   by monitoring multiple IP's in the path , provides better understanding of
#   components that are failing
# Requirements and Syntax:
# - modify main() with appropriate IP's or URL's to monitor
#
# Notes:
# - only tested with OSX 10.12 and above
#
##############################################################


main()
	{
# - a = announce , -t = add time stamp , -f = frequency to check , - o= output file

	./term.sh "./scripts/mynetmon.sh -a -t -f 5 -o pfsenselan.csv 192.168.1.1" "Grass" # monitor local router internal lan IP (gateway)
  ./term.sh "./scripts/mynetmon.sh -a -t -f 5 -o pfsensewan.csv 66.11.253.145" "Novel" # monitor router wan interface
  ./term.sh "./scripts/mynetmon.sh -a -t -f 5 -o bledsortr1.csv 66.11.253.1" "Ocean" # monitor bledsoe gateway
  ./term.sh "./scripts/mynetmon.sh -a -t -f 5 -o bledsortr2.csv 66.11.253.2" "Red Sands" # monitor bledsoe first hop
  # no -a auditble alert for google.  most of the issues are outbound bledsoe.. just for tracking with traceroute to identify where the issue is when we see issues
  ./term.sh "./scripts/mynetmon.sh -t -f 5 -o google.csv www.google.com" "Solid Colors" # Monitor Google. 

}

main
