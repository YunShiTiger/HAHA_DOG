#!/bin/bash
docker build -t olds --rm=true .
docker run -d --name old       --restart=unless-stopped olds
