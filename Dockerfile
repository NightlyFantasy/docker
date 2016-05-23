# Pull base image
FROM daocloud.io/library/centos:latest
#  Thanks Cdoco <cdoco@gmail.com>
MAINTAINER Leepin <admin@cxsir.com>

# Add a user
RUN set -x \
    && groupadd www \
    && useradd www -M -s /sbin/nologin -g www

# Update source
RUN set -x \
    && yum update -y \
    && yum install wget gcc gcc-c++ make perl tar git automake autoconf libtool -y \
    && yum clean all \
    && mkdir /opt/data \
    && mkdir /opt/source


# Install zlib
RUN set -x \
    && cd /opt/data \
    && wget http://jaist.dl.sourceforge.net/project/libpng/zlib/1.2.8/zlib-1.2.8.tar.gz \
    && tar zxvf zlib-1.2.8.tar.gz \
    && cd zlib-1.2.8 \
    && ./configure --static --prefix=/opt/source/libs/zlib \
    && make -j \
    && make install

# Install openssl
RUN set -x \
    && cd /opt/data \
    && wget http://www.openssl.org/source/openssl-1.0.2h.tar.gz \
    && tar zxvf openssl-1.0.2h.tar.gz \
    && cd openssl-1.0.2h \
    && ./config --prefix=/opt/source/libs/openssl -L/opt/source/libs/zlib/lib -I/opt/source/libs/zlib/include threads zlib enable-static-engine\
    && make -j \
    && make install

# Install pcre
RUN set -x \
    && cd /opt/data \
    && wget http://jaist.dl.sourceforge.net/project/pcre/pcre/8.38/pcre-8.38.tar.gz \
    && tar zxvf pcre-8.38.tar.gz \
    && cd pcre-8.38 \
    && ./configure --prefix=/opt/source/libs/pcre \
    && make -j \
    && make install

# Install nginx
RUN set -x \
    && cd /opt/data \
    && wget http://nginx.org/download/nginx-1.10.0.tar.gz \
    && tar zxvf nginx-1.10.0.tar.gz \
    && cd nginx-1.10.0 \
    && './configure' \
       '--prefix=/opt/source/nginx' \
       '--user=www' \
       '--group=www' \
       '--with-debug' \
       '--with-openssl=/opt/data/openssl-1.0.2h' \
       '--with-zlib=/opt/data/zlib-1.2.8' \
       '--with-pcre=/opt/data/pcre-8.38' \
       '--with-http_stub_status_module' \
       '--with-http_gzip_static_module' \
       '--with-stream' \
       '--with-http_ssl_module' \
       '--with-http_v2_module' \
       '--with-http_realip_module' \
       '--with-http_sub_module' \
    && make -j \
    && make install

# Install php
RUN set -x \
    && yum install libjpeg libpng libjpeg-devel libpng-devel libjpeg-turbo -y \
    && yum install freetype freetype-devel -y \
    && yum install libcurl-devel libxml2-devel -y \
    && yum install libjpeg-turbo-devel libXpm-devel -y \
    && yum install libXpm libicu-devel libmcrypt libmcrypt-devel -y \
    && yum install libxslt-devel libxslt -y \
    && yum install openssl openssl-devel bzip2-devel -y \
    && yum clean all

# Install libmcrypt
RUN set -x \
    && cd /opt/data \
    && wget ftp://mcrypt.hellug.gr/pub/crypto/mcrypt/libmcrypt/libmcrypt-2.5.7.tar.gz \
    && tar zxvf libmcrypt-2.5.7.tar.gz \
    && cd libmcrypt-2.5.7 \
    && ./configure \
    && make -j \
    && make install

RUN set -x \
    && cd /opt/data \
    && wget http://cn2.php.net/distributions/php-7.0.6.tar.gz \
    && tar zxvf php-7.0.6.tar.gz \
    && cd php-7.0.6 \
    && './configure' \
       '--prefix=/opt/source/php/' \
       '--with-config-file-path=/opt/source/php/etc/' \
       '--with-config-file-scan-dir=/opt/source/php/conf.d/' \
       '--enable-fpm' \
       '--with-fpm-user=www' \
       '--with-fpm-group=www' \
       '--enable-cgi' \
       '--disable-phpdbg' \
       '--enable-mbstring' \
       '--enable-calendar' \
       '--with-xsl' \
       '--with-openssl' \
       '--enable-soap' \
       '--enable-zip' \
       '--enable-shmop' \
       '--enable-sockets' \
       '--with-gd' \
       '--with-jpeg-dir' \
       '--with-png-dir' \
       '--with-xpm-dir' \
       '--with-xmlrpc' \
       '--enable-pcntl' \
       '--enable-intl' \
       '--with-mcrypt' \
       '--enable-sysvsem' \
       '--enable-sysvshm' \
       '--enable-sysvmsg' \
       '--enable-opcache' \
       '--with-iconv' \
       '--with-bz2' \
       '--with-curl' \
       '--enable-mysqlnd' \
       '--with-mysqli=mysqlnd' \
       '--with-pdo-mysql=mysqlnd' \
       '--with-zlib' \
       '--with-gettext' \
    && make -j \
    && make install

# cp php conf
ADD files/php/php.ini /opt/source/php/etc/php.ini
ADD files/php/php-fpm.conf /opt/source/php/etc/php-fpm.conf
ADD files/php/www.conf /opt/source/php/etc/php-fpm.d/www.conf

# Install Composer
RUN set -x \
    && ln -s /opt/source/php/bin/php /usr/bin/php \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/bin  --filename=composer \
    && php -r "unlink('composer-setup.php');"

# Install MongoDB PHP extension
RUN set -x \
    && cd /opt/data \
    && wget https://pecl.php.net/get/mongodb-1.1.6.tgz \
    && tar zvxf mongodb-1.1.6.tgz \
    && cd mongodb-1.1.6 \
    && /opt/source/php/bin/phpize \
    && ./configure --with-php-config=/opt/source/php/bin/php-config \
    && make -j \
    && make install

# Install Redis PHP extension
RUN set -x \
    && cd /opt/data \
    && git clone -b php7 https://github.com/phpredis/phpredis.git \
    && cd phpredis \
    && /opt/source/php/bin/phpize \
    && ./configure --with-php-config=/opt/source/php/bin/php-config \
    && make -j \
    && make install

# add nginx conf
ADD files/nginx/nginx.conf /opt/source/nginx/conf/nginx.conf
ADD files/nginx/default.conf /opt/source/nginx/conf/vhost/default.conf
RUN set -x \
    && mkdir /opt/source/logs \
    && mkdir /opt/source/logs/nginx \
    && touch /opt/source/logs/nginx/access.log

# add run.sh
ADD files/run.sh /opt/source/run.sh
RUN set -x \
    && chmod 755 /opt/source/run.sh

RUN set -x \
    && mkdir /opt/source/www \
    && chown www:www -R /opt/source/www \
    && echo "<?php phpinfo();?>" > /opt/source/www/index.php

# delete data dir
RUN set -x \
    && rm -rf /opt/data

# Start php-fpm And nginx
CMD ["/opt/source/run.sh"]

EXPOSE 80
EXPOSE 443