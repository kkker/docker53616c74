FROM ubuntu:24.04


ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV PHP_VERSION=8.3


# Install required packages
RUN apt-get update && apt-get install -y \
    # for rabbitmq
    sudo curl wget \
    software-properties-common \
    gnupg2

RUN apt install -y software-properties-common curl apt-transport-https lsb-release
RUN curl -1sLf 'https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/setup.deb.sh' | sudo -E bash
RUN apt update && apt install -y erlang
RUN apt-get install -y --fix-missing rabbitmq-server
RUN rabbitmq-plugins enable rabbitmq_management

# Add Ondřej Surý's PPA for PHP
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php && apt-get update


RUN apt-get update && apt-get install -y \
    nginx=1.24.* \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-gmp \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-readline \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-imagick \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-pcov \
    php${PHP_VERSION}-pdo \
    php${PHP_VERSION}-xmlrpc \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-bz2 \
    php${PHP_VERSION}-ssh2 \
    php${PHP_VERSION}-imap \
    zip \
    unzip \
    curl \
    sudo \
    nano \
    less \
    net-tools \
    iputils-ping \
    supervisor \
    cron \
    mysql-client \
    # for mysql
    mysql-server \
    # for redis
    redis-server \
    git


RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g npm@10.2.4
RUN npm install -g nodemon


ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_HOME=/tmp
ENV COMPOSER_VERSION=2.8.4


# # install public keys for snapshot and tag validation, see https://composer.github.io/pubkeys.html
RUN curl \
    --silent \
    --fail \
    --location \
    --retry 3 \
    --output /tmp/keys.dev.pub \
    --url https://raw.githubusercontent.com/composer/composer.github.io/e7f28b7200249f8e5bc912b42837d4598c74153a/snapshots.pub \
  ; \
  echo 572b963c4b7512a7de3c71a788772440b1996d918b1d2b5354bf8ba2bb057fadec6f7ac4852f2f8a8c01ab94c18141ce0422aec3619354b057216e0597db5ac2 /tmp/keys.dev.pub | sha512sum --strict --check ; \
  curl \
    --silent \
    --fail \
    --location \
    --retry 3 \
    --output /tmp/keys.tags.pub \
    --url https://raw.githubusercontent.com/composer/composer.github.io/e7f28b7200249f8e5bc912b42837d4598c74153a/releases.pub \
  ; \
  echo 47f374b8840dcb0aa7b2327f13d24ab5f6ae9e58aa630af0d62b3d0ea114f4a315c5d97b21dcad3c7ffe2f0a95db2edec267adaba3f4f5a262abebe39aed3a28 /tmp/keys.tags.pub | sha512sum --strict --check ; \
  # download installer.php, see https://getcomposer.org/download/
  curl \
    --silent \
    --fail \
    --location \
    --retry 3 \
    --output /tmp/installer.php \
    --url https://raw.githubusercontent.com/composer/getcomposer.org/f24b8f860b95b52167f91bbd3e3a7bcafe043038/web/installer \
  ; \
  echo 3137ad86bd990524ba1dedc2038309dfa6b63790d3ca52c28afea65dcc2eaead16fb33e9a72fd2a7a8240afaf26e065939a2d472f3b0eeaa575d1e8648f9bf19 /tmp/installer.php | sha512sum --strict --check ; \
  # install composer phar binary
  php /tmp/installer.php \
    --no-ansi \
    --install-dir=/usr/bin \
    --filename=composer \
    --version=${COMPOSER_VERSION} \
  ; \
  composer --ansi --version --no-interaction ; \
  composer diagnose ; \
  rm -f /tmp/installer.php ; \
  find /tmp -type d -exec chmod -v 1777 {} +


RUN if ! grep -q "^ubuntu:" /etc/passwd; then \
    useradd -ms /bin/bash ubuntu -u 1000 ; fi

COPY sudoers.d/* /etc/sudoers.d/
RUN chmod 0440 /etc/sudoers.d/*

# Made symbolic links in UAT
RUN ln -s /home/ubuntu/code/nxhk/backend /var/www/html/backend
RUN ln -s /home/ubuntu/code/nxhk/frontend /var/www/html/frontend
RUN ln -s /home/ubuntu/code/nxhk/frontend /app

RUN usermod -aG ubuntu www-data

COPY conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx/sites-available/default /etc/nginx/sites-available/
# for rabbitmq management
COPY nginx/sites-available/rabbitmq.conf /etc/nginx/sites-available/
RUN ln -s /etc/nginx/sites-available/rabbitmq.conf /etc/nginx/sites-enabled/


RUN echo "* * * * * root cd /home/ubuntu/code/nxhk/backend && php artisan schedule:run >> /dev/null 2>&1" > /etc/cron.d/laravel
RUN chmod 0644 /etc/cron.d/laravel

# for bind-address
COPY mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf

# for bind 0.0.0.0 -::*
# for protected-mode no
# for daemonize no
COPY redis/etc/redis.conf /etc/redis/redis.conf
RUN chmod 755 /etc/redis/redis.conf

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["demo"]
