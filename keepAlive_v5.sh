#!/bin/bash

. installation_v5.config

sleep_time=120 #2 minutes

sleep $initial_pause # initial sleep to let things get started

#rm $alive

sleep $sleep_time

while :
    do

        if [ ! -f $alive ]; then
            echo "File not found! - installation_v5.scd has not checked in and must be hung"
            kill $1
            exit 0
        else

            rm $alive
        fi

        sleep $sleep_time

done
