#!/bin/bash

cd /usr/src/reader
java -server -Xms128M -Xmx4096M -Djava.ext.dirs=./libs com.inspeeding.SyncInFromOutColony_New
