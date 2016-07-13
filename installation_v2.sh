#!/bin/bash

while :
    do
        sclang installation_v2.scd &
        pid=$!

        ./keepAlive_v2.sh $pid &
        alive_pid=$!

        wait $pid
        kill $alive_pid

        sleep 5
done

