#!/bin/sh

#Mounts Auto Server if it is not already mounted

while :
do
	if ! mount | grep "on /Volumes/S4 PDF Files" > /dev/null;

	then
		mkdir "/volumes/S4 PDF Files"
		mount -t afp "afp://ads:ads@10.1.3.17/S4 PDF Files" "/volumes/S4 PDF Files"
	else
		cd /volumes/"S4 PDF Files"/"Output Files"
		perl Validate.pl
	fi

	sleep 30s
done