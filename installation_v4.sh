#!/bin/bash

while :
    do
        sclang installation_v4.scd installation_v4.config &
        pid=$!

        ./keepAlive_v4.sh $pid &
        alive_pid=$!

        wait $pid
        kill $alive_pid

        sleep 5
done

