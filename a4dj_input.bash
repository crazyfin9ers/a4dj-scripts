#!/bin/bash

if [ "$1"x == "x" ] ; then
   echo "$0 [phono|line|timecode]"
   exit 1
fi

dev=`aplay -l  | grep Audio4DJ | grep "device 0" | cut -d\  -f 2 | cut -d: -f 1`
if [ "$dev"x == "x" ] ; then
   echo "Audio 4 DJ not connected"
   exit 1
fi

result=0
if [ "$1" == "phono" ] ; then
   amixer -c $dev cset numid=1 2 > /dev/null
   result=$?
elif [ "$1" == "line" ] ; then
   amixer -c $dev cset numid=1 1 > /dev/null
   result=$?
elif [ "$1" == "timecode" ] ; then
   amixer -c $dev cset numid=1 0 > /dev/null
   result=$?
else
   echo "$0 [phono|line|timecode]"
   exit 1
fi

if [ $result -ne 0 ] ; then
   echo "Error setting Audio 4 DJ input"
   exit $result
fi
