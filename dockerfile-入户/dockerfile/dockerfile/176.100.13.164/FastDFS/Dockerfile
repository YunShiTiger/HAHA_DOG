FROM daocloud.io/library/centos:6.8
MAINTAINER Howard.T@SIBOSEN
USER root

# install environment
RUN mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
ADD CentOS-Base.repo /etc/yum.repos.d/
RUN yum clean all
RUN yum makecache
RUN yum -y groupinstall 'Development Tools'
RUN yum -y install nano
RUN yum install -y libevent-devel pcre-devel zlib-devel

# install FastDFS
ADD FastDFS_v4.08.tar.gz /
WORKDIR /FastDFS_v4.08
RUN ./make.sh
RUN ./make.sh install

# create symbol link
RUN ln -sv /usr/include/fastcommon /usr/local/include/fastcommon 
RUN ln -sv /usr/include/fastdfs /usr/local/include/fastdfs

# install nginx
ADD nginx-1.11.6.tar.gz /usr/local/
ADD fastdfs-nginx-module_v1.16.tar.gz /usr/local/
WORKDIR /usr/local/nginx-1.11.6
RUN ./configure --prefix=/usr/local/nginx --conf-path=/usr/local/nginx/nginx.conf --add-module=/usr/local/fastdfs-nginx-module/src
RUN make
RUN make install

# copy config files
# for tracker
ADD tracker.conf /fdfs_conf/

# for storage
ADD storage.conf /fdfs_conf/
ADD nginx.conf /fdfs_conf/
ADD mod_fastdfs.conf /fdfs_conf/

# for bootstrap
ADD entrypoint.sh /
RUN chmod u+x /entrypoint.sh

# the end
ENTRYPOINT ["/entrypoint.sh"]
