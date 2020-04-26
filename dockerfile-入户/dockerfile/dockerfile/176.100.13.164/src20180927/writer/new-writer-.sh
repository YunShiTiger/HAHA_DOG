#!/bin/bash
docker build -t writer --rm=true .
docker run -d --name writer1       --restart=unless-stopped writer
docker run -d --name writer2       --restart=unless-stopped writer




