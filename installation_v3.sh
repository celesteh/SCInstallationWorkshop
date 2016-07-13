#!/bin/bash

while :
    do
        sclang installation_v3.scd installation_v3.config &
        pid=$!

        ./keepAlive_v3.sh $pid &
        alive_pid=$!

        wait $pid
        kill $alive_pid

        sleep 5
done

