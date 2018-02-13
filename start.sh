#!/bin/bash

export PORT=4000

cd ~/www/memory
./bin/memory stop || true
./bin/memory start

