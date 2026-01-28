#!/bin/bash
echo "${0%/*}"
cd "${0%/*}"
python3 simple_data_gen.py $1 $2 $3
./bootstrap.sh