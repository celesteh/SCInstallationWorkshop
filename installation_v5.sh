#!/bin/bash

port=57110

while :
    do
        sclang installation_v5.scd installation_v5.config $port&
        pid=$!

        ./keepAlive_v5.sh $pid &
        alive_pid=$!

        wait $pid
        kill $alive_pid
        killall scsynth

        sleep 5
        port=$((port+1))
done

