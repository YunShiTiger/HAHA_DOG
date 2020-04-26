###tracker###
docker run -d --name tracker1 -v /data/tracker/data01:/fastdfs/tracker/data -e TR_PORT=22122 --net=host --restart unless-stopped fastdfs tracker
docker run -d --name tracker2 -v /data/tracker/data02:/fastdfs/tracker/data -e TR_PORT=22222 --net=host --restart unless-stopped fastdfs tracker
docker run -d --name tracker3 -v /data/tracker/data03:/fastdfs/tracker/data -e TR_PORT=22322 --net=host --restart unless-stopped fastdfs tracker
docker run -d --name tracker4 -v /data/tracker/data04:/fastdfs/tracker/data -e TR_PORT=22422 --net=host --restart unless-stopped fastdfs tracker
docker run -d --name tracker5 -v /data/tracker/data05:/fastdfs/tracker/data -e TR_PORT=22522 --net=host --restart unless-stopped fastdfs tracker

###storage###
docker run -d --name storage1 -v /data/storage/data01:/fastdfs/storage/data -v /data/storage/store_path01:/fastdfs/store_path -e ST_PORT=23001 -e NGX_PORT=3001 -e GROUP_NAME=group1 --net=host --restart unless-stopped fastdfs storage
docker run -d --name storage2 -v /data/storage/data02:/fastdfs/storage/data -v /data/storage/store_path02:/fastdfs/store_path -e ST_PORT=23002 -e NGX_PORT=3002 -e GROUP_NAME=group2 --net=host --restart unless-stopped fastdfs storage
docker run -d --name storage3 -v /data/storage/data03:/fastdfs/storage/data -v /data/storage/store_path03:/fastdfs/store_path -e ST_PORT=23003 -e NGX_PORT=3003 -e GROUP_NAME=group3 --net=host --restart unless-stopped fastdfs storage
docker run -d --name storage4 -v /data/storage/data04:/fastdfs/storage/data -v /data/storage/store_path04:/fastdfs/store_path -e ST_PORT=23004 -e NGX_PORT=3004 -e GROUP_NAME=group4 --net=host --restart unless-stopped fastdfs storage
docker run -d --name storage5 -v /data/storage/data05:/fastdfs/storage/data -v /data/storage/store_path05:/fastdfs/store_path -e ST_PORT=23005 -e NGX_PORT=3005 -e GROUP_NAME=group5 --net=host --restart unless-stopped fastdfs storage
docker run -d --name storage6 -v /data/storage/data06:/fastdfs/storage/data -v /data/storage/store_path06:/fastdfs/store_path -e ST_PORT=23006 -e NGX_PORT=3006 -e GROUP_NAME=group6 --net=host --restart unless-stopped fastdfs storage
docker run -d --name storage7 -v /data/storage/data07:/fastdfs/storage/data -v /data/storage/store_path07:/fastdfs/store_path -e ST_PORT=23007 -e NGX_PORT=3007 -e GROUP_NAME=group7 --net=host --restart unless-stopped fastdfs storage
docker run -d --name storage8 -v /data/storage/data08:/fastdfs/storage/data -v /data/storage/store_path08:/fastdfs/store_path -e ST_PORT=23008 -e NGX_PORT=3008 -e GROUP_NAME=group8 --net=host --restart unless-stopped fastdfs storage
docker run -d --name storage9 -v /data/storage/data09:/fastdfs/storage/data -v /data/storage/store_path09:/fastdfs/store_path -e ST_PORT=23009 -e NGX_PORT=3009 -e GROUP_NAME=group9 --net=host --restart unless-stopped fastdfs storage
docker run -d --name storage10 -v /data/storage/data10:/fastdfs/storage/data -v /data/storage/store_path10:/fastdfs/store_path -e ST_PORT=23010 -e NGX_PORT=3010 -e GROUP_NAME=group10 --net=host --restart unless-stopped fastdfs storage

###OJBK###
