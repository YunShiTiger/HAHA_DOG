#!/bin/bash

cd /usr/src/writer
java -server -Xms128M -Xmx1024M -Djava.ext.dirs=./libs com.inspeeding.SyncIntranetFileListReader
