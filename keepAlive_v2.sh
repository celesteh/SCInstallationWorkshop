#!/bin/bash

sleep_time=120 #2 minutes
alive=/tmp/installation

rm $alive

sleep $sleep_time

while :
    do

        if [ ! -f $alive ]; then
            echo "File not found! - installation_v2.scd has not checked in and must be hung"
            kill $1
            exit 0
        else

            rm $alive
        fi

        sleep $sleep_time

done
