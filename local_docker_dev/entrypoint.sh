#!/usr/bin/env bash
set -x

MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-root}
MYSQL_DATABASE=${MYSQL_DATABASE:-demo_uat}
MYSQL_USER=${MYSQL_USER:-myuser}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-mypassword}

REDIS_USERNAME=${REDIS_USERNAME}
REDIS_PASSWORD=${REDIS_PASSWORD}

uat_mysql() { # aka. function uat_mysql

    # 設定 mysql 使用者主目錄
    # ref. to https://www.cnblogs.com/cnwcl/p/13805643.html
    usermod -d /var/lib/mysql/ mysql
    #
    # 确保数据目录存在并设置正确的权限
    # mkdir -p /var/lib/mysql
    # chown -R mysql:mysql /var/lib/mysql
    chmod 755 /var/lib/mysql


    local do_mysql_init=false
    local is_mysql_initialized_file=/home/ubuntu/code/demo/local_docker_dev/mysql/data.initialized
    local mysql_data_path=$( cd "$(dirname "$is_mysql_initialized_file")" ; pwd -P )
    local mysql_data_file=$( basename "$is_mysql_initialized_file" )
    echo "The initialized path: $mysql_data_path"
    echo "The initialized file: $mysql_data_file"
    # for check mysql initialized file exists, that is generated at end of mysql-init execution.
    if [[ $(find $mysql_data_path -name $mysql_data_file -print -quit | wc -l) -gt 0 ]]; then
        echo "The initialized file, /home/ubuntu/code/demo/local_docker_dev/mysql/data.initialized has found"
        /etc/init.d/mysql restart
    else
        echo "The initialized file, /home/ubuntu/code/demo/local_docker_dev/mysql/data.initialized Not Found"
        do_mysql_init=true
        mysqld --initialize-insecure --user=mysql && sleep 10 && /etc/init.d/mysql restart
    fi


    if [ "$do_mysql_init" = true ]; then

        echo "To generate mysql-init file ..."

        touch /tmp/mysql-init.sql

        # utf8mb4_general_ci
        echo "CREATE DATABASE ${MYSQL_DATABASE} DEFAULT CHARACTER SET utf8mb4 COLLATE 'utf8mb4_unicode_ci';" >> /tmp/mysql-init.sql

        # for root@localhost
        echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_ROOT_PASSWORD}';" >> /tmp/mysql-init.sql
        # # for root@%
        echo "CREATE USER 'root'@'%' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_ROOT_PASSWORD}';" >> /tmp/mysql-init.sql
        echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" >> /tmp/mysql-init.sql

        # for MYSQL_USER@localhost
        echo "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_PASSWORD}';" >> /tmp/mysql-init.sql
        echo "GRANT ALL ON *.* TO '${MYSQL_USER}'@'localhost' WITH GRANT OPTION;" >> /tmp/mysql-init.sql
        # for MYSQL_USER@%
        echo "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED WITH caching_sha2_password BY '${MYSQL_PASSWORD}';" >> /tmp/mysql-init.sql
        echo "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION;" >> /tmp/mysql-init.sql

        echo "FLUSH PRIVILEGES;" >> /tmp/mysql-init.sql

        mysql -uroot -hlocalhost -e "source /tmp/mysql-init.sql"

        echo "Clear mysql-init file ..."

        rm -f /tmp/mysql-init.sql

        touch $is_mysql_initialized_file
    fi
}

if [ "$1" = 'uat_mysql' ]; then

    uat_mysql

    tail -f /dev/null
fi # EOF if [ "$1" = 'uat_mysql' ]



function uat_redis {
    # 設定 redis 密碼
    # 設定 redis 密碼
    if [ -n "${REDIS_PASSWORD}" ]; then

        # 設定 redis 使用者    # healthcheck, redis-cli --user admin --pass adminpass ping
        # user ${REDIS_USERNAME} on allkeys allchannels allcommands >${REDIS_PASSWORD}
        if [ -n "${REDIS_USERNAME}" ]; then

            # disable redis anonymous account
            echo "user default off" >> /etc/redis/redis.conf

            # both user and password
            echo "user ${REDIS_USERNAME} on allkeys allchannels allcommands >${REDIS_PASSWORD}" >> /etc/redis/redis.conf
        else
            # password only
            echo "requirepass ${REDIS_PASSWORD}" >> /etc/redis/redis.conf
        fi # EOF if [ -n "${REDIS_USERNAME}" ]
    fi # EOF if [ -n "${REDIS_PASSWORD}" ]

    ## moved to uat/conf.d/supervisord.conf
    # # service redis-server start
    # /etc/init.d/redis-server start
}
#
if [ "$1" = 'uat_redis' ]; then
    # redis-server -v
    # Redis server v=7.0.15 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=d81b8ff71cfb150e

    uat_redis

    tail -f /dev/null
fi # EOF if [ "$1" = 'uat_redis' ]


function uat_rabbitmq {
    /etc/init.d/rabbitmq-server start

    rabbitmqctl add_user admin pass
    rabbitmqctl set_user_tags admin administrator
    rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
}
#
if [ "$1" = 'uat_rabbitmq' ]; then
    uat_rabbitmq

    tail -f /dev/null
fi # EOF if [ "$1" = 'uat_rabbitmq' ]


function uat_script {

    # For upload files, ref. to backend/config/filesystems.php
    cd /home/ubuntu/code/demo/backend && php artisan storage:link

    service php8.3-fpm start
    service cron start
    /usr/bin/python3 /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
}
#
if [ "$1" = 'uat' ]; then
    uat_script

    tail -f /dev/null
fi

if [ "$1" = 'uat_host' ]; then

    uat_rabbitmq

    uat_redis

    uat_mysql

    uat_script

    tail -f /dev/null
fi

function demo_script {

    # For upload files, ref. to backend/config/filesystems.php
    # cd /home/ubuntu/code/demo/backend && php artisan storage:link

    service php7.3-fpm start
    service cron start
    /usr/bin/python3 /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
}
#
if [ "$1" = 'demo' ]; then

    # uat_rabbitmq

    # uat_redis

    uat_mysql

    demo_script

    tail -f /dev/null
fi
exec "$@"
