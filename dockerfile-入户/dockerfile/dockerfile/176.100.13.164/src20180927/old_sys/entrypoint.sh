#!/bin/bash

cd /usr/src/SyncInFromOut
java -server -Xms128M -Xmx16384M  -Djava.ext.dirs=/usr/lib/jvm/java-8-openjdk-amd64:./libs com.inspeeding.SyncInFromOut
