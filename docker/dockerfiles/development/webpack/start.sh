#!/bin/bash
echo "running"
until cd /webpack && npm install
do
    echo "Retrying npm install" >> log.txt
done
cd /webpack && npm run watch
tail -f /dev/null
