#!/bin/bash

sonica_ok=`aplay -l |grep Audio4DJ |wc -l`

if [ $sonica_ok == 0 ] ; then
   echo "Audio4DJ  not attached, not starting"
   exit 1
fi

#initialize asoundrc with correct card number
$HOME/bin/make_asoundrc.sh

dev=`aplay -l  | grep Audio4DJ | grep "device 0" | cut -d\  -f 2 | cut -d: -f 1`
rtkernel=1

dither="-z s"
rate=44100
timeout=2000
inputmode="timecode"

pasuspend=""
test=0
fast=0
while [ "$1"x != "x" ]; do
   if [ "$1" == "--help" -o "$1" == "-h" ] ; then
      echo "$0:"
      echo "--nopa      Disable pulseaudio"
      echo "--fast      Fast mode for scratching"
      echo "--slow      Slow mode when latency doesn't matter"
      echo "--96K         96KHz sampling"
      echo "--48K         48KHz sampling"
      echo "--phono       Use phono input mode instead of timecode mode"
      echo "--test      Ultra-short Testing mode"
      exit 0
   elif [ "$1" == "--nopa" ] ; then
      echo "disabling pulseaudio"
      pasuspend="pasuspender -- "
   elif [ "$1" == "--test" ] ; then
      test=1
   elif [ "$1" == "--fast" ] ; then
      fast=1
   elif [ "$1" == "--slow" ] ; then
      fast=-1
   elif [ "$1" == "--96K" ] ; then
      rate=96000
   elif [ "$1" == "--48K" ] ; then
      rate=48000
   elif [ "$1" == "--phono" ] ; then
      inputmode="phono"
   else
      echo "Unknown option $1"
      exit 1
   fi
   shift
done

if [ "$rtkernel" == "1" ] ; then
   #2 periods works, but I think it's too little for soundtouch
   gksu --message "Enter password to boost realtime priority of irqs" /etc/init.d/rtirq start

   if [ "$fast" == "1" ] ; then
   #ok for vinyl control
      size=256
      periods=2
   else
      #below five, start to get xruns
      size=256
      periods=5
   fi
   realtime="-R -P 70"
else
   size=512
   periods=5
   realtime="-R -P 70"
fi

if [ "$test" == "1" ] ; then
   echo TEMP SHORT TIME FOR TESTING
   size=64
   periods=2
fi

if [ "$fast" == "-1" ] ; then
   let size=size*2
   let periods=periods*2
fi

if [ $rate -gt 48000 ] ; then
   let size=size*2
fi

$HOME/bin/a4dj_input.sh $inputmode

log=`tempfile -p JACK -s .log`

command="$pasuspend jackd $realtime --timeout $timeout -d alsa -d AUDIO4DJ -p $size -n $periods -i 4 -o 4 -r $rate $dither > $log"
echo "if there are problems, maybe pulseaudio grabbed it??"
echo $command
eval $command &

sleep 2

exit 0
