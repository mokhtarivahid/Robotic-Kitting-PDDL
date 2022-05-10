#! /bin/bash

ulimit -t 1800
ulimit -v 4000000

if [[ $1 == "" || $1 == "-h" || $1 == "--help" ]] ; then
    echo "Usage: plan <domainFile> <problemFile>"
    exit
fi

domain=$(realpath $1)
problem=$(realpath $2)

cd $(dirname $0)/tfd-src-0.4/downward

./plan.py "y+Y+a+e+r+O+1+C+1+b+v" $domain $problem "\tmp\plan.txt"

