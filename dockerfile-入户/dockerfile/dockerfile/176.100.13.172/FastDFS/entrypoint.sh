#!/bin/bash

# defined for tracker
TRACKER_BASE_PATH="/fastdfs/tracker"
TRACKER_LOG_FILE="$TRACKER_BASE_PATH/logs/trackerd.log"
TRACKER_CONF_FILE="/etc/fdfs/tracker.conf"

# defined for storage
STORAGE_BASE_PATH="/fastdfs/storage"
STORAGE_LOG_FILE="$STORAGE_BASE_PATH/logs/storaged.log"
STORAGE_CONF_FILE="/etc/fdfs/storage.conf"

# config of nginx
NGINX_CONF_FILE="/usr/local/nginx/nginx.conf"
MOD_FASTDFS_CONF_FILE="/etc/fdfs/mod_fastdfs.conf"

# remove the old log files
if [  -f "$TRACKER_LOG_FILE" ]; then
    rm -rf "$TRACKER_LOG_FILE"
fi
if [ -f "$STORAGE_LOG_FILE" ]; then
    rm -rf "$STORAGE_LOG_FILE"
fi

# ============================================ start with TRACKER
if [ "$1" = 'tracker' ]; then
    echo "Start trackerd..."

    # tracker.conf
    t_array=()
    n=0
	while read line
	do
	    t_array[$n]="${line}";
	    ((n++));
	done < /fdfs_conf/tracker.conf
	rm "$TRACKER_CONF_FILE"
	for i in "${!t_array[@]}"; do 
	    if [ ${TR_PORT} ]; then
	        [[ "${t_array[$i]}" == "port="* ]] && t_array[$i]="port=${TR_PORT}"
	    fi
	    echo "${t_array[$i]}" >> "$TRACKER_CONF_FILE"
	done

    # run trackerd
    if [ ! -d "$TRACKER_BASE_PATH/logs" ]; then
        mkdir "$TRACKER_BASE_PATH/logs"
    fi
    touch  "$TRACKER_LOG_FILE"
    ln -sf /dev/stdout "$TRACKER_LOG_FILE"
    fdfs_trackerd $TRACKER_CONF_FILE
    
    # keep alive
    wait
    echo "Trackerd started."
    tail -F --pid=`cat /fastdfs/tracker/data/fdfs_trackerd.pid` /dev/null
fi

# ============================================ start with STORAGE
if [ "$1" = 'storage' ]; then
    echo "Start storaged..."

    # storage.conf
    s_array=()
    n=0
	while read line
	do
	    s_array[$n]="${line}";
	    ((n++));
	done < /fdfs_conf/storage.conf
	rm "$STORAGE_CONF_FILE"
	for i in "${!s_array[@]}"; do 
	    if [ ${ST_PORT} ]; then
	        [[ "${s_array[$i]}" == "port="* ]] && s_array[$i]="port=${ST_PORT}"
	    fi
        if [ ${GROUP_NAME} ]; then
            [[ "${s_array[$i]}" == "group_name="* ]] && s_array[$i]="group_name=${GROUP_NAME}"
        fi
	    echo "${s_array[$i]}" >> "$STORAGE_CONF_FILE"
	done

    # run storaged
    if [ ! -d "$STORAGE_BASE_PATH/logs" ]; then
        mkdir "$STORAGE_BASE_PATH/logs"
    fi
    touch  "$STORAGE_LOG_FILE"
    ln -sf /dev/stdout "$STORAGE_LOG_FILE"
    fdfs_storaged "$STORAGE_CONF_FILE"

    # mod_fastdfs.conf
    m_array=()
    k=0
    while read line
    do
        m_array[$k]="${line}";
        ((k++));
    done < /fdfs_conf/mod_fastdfs.conf
    for i in "${!m_array[@]}"; do
        if [ ${GROUP_NAME} ]; then
            [[ "${m_array[$i]}" == "group_name="* ]] && m_array[$i]="group_name=${GROUP_NAME}"
        fi
        [[ "${m_array[$i]}" =~ "store_path0=" ]] && m_array[$i]="store_path0=/fastdfs/store_path"
        if [ ${ST_PORT} ]; then
            [[ "${m_array[$i]}" =~ "storage_server_port=" ]] && m_array[$i]="storage_server_port=${ST_PORT}"
        fi
        echo "${m_array[$i]}" >> "$MOD_FASTDFS_CONF_FILE"
    done

    # nginx.conf
    n_array=()
    p=0
    while read line
    do
        n_array[$p]="${line}";
	    ((p++));
    done < /fdfs_conf/nginx.conf
    rm "$NGINX_CONF_FILE"
    for i in "${!n_array[@]}"; do
	    echo "${n_array[$i]}" >> "$NGINX_CONF_FILE"
	done
    if [ ${NGX_PORT} ]; then
        sed -i '/listen/d' "$NGINX_CONF_FILE"
        sed -i "/server_name  localhost;/i\listen $(echo $NGX_PORT);" "$NGINX_CONF_FILE"
    fi
    if [ ${GROUP_NAME} ]; then
        sed -i "/server {/a\location /$(echo $GROUP_NAME)/M00 {\nroot /fastdfs/store_path/data;\nngx_fastdfs_module;\n}" "$NGINX_CONF_FILE"
    else
        sed -i "/server {/a\location /group1/M00 {\nroot /fastdfs/store_path/data;\nngx_fastdfs_module;\n}" "$NGINX_CONF_FILE"
    fi

    # run nginx
    /usr/local/nginx/sbin/nginx

    # keep alive
    wait
    echo "Storaged started."
    tail -F --pid=`cat /fastdfs/storage/data/fdfs_storaged.pid` /dev/null
fi
