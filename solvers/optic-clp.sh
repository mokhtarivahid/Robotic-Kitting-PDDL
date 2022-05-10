#!/bin/bash

# bash
ulimit -t 600
ulimit -v 6000000

if [[ $1 == "" || $1 == "-h" || $1 == "--help" ]] ; then
    echo "Usage: plan <domainFile> <problemFile>"
    exit
fi

$(dirname $0)/optic-clp $1 $2
# $(dirname $0)/optic-clp -c -N $1 $2
# $(dirname $0)/optic-clp -c -E -N $1 $2
