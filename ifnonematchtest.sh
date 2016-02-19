#!/bin/bash


for ((x=1; x<=1000; x++)); do
    printf "Iteration $x - "
    curl --header 'If-None-Match: "-971024729"' -k https://auth.zalando.com/z/json/serverinfo/* 
done
