#!/bin/bash
docker build -t reader --rm=true .
       
docker run -d --name reader1    --restart=unless-stopped reader
docker run -d --name reader2    --restart=unless-stopped reader
docker run -d --name reader3    --restart=unless-stopped reader
docker run -d --name reader4    --restart=unless-stopped reader
docker run -d --name reader5    --restart=unless-stopped reader
docker run -d --name reader6    --restart=unless-stopped reader
docker run -d --name reader7    --restart=unless-stopped reader
docker run -d --name reader8    --restart=unless-stopped reader
docker run -d --name reader9    --restart=unless-stopped reader
docker run -d --name reader10   --restart=unless-stopped reader



