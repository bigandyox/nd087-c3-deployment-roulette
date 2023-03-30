#!/bin/bash

for i in {1..10}
 do
    curl 192.168.1.153 >> canary.txt
 done