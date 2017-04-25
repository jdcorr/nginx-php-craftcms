FROM debian:jessie

MAINTAINER JD Corr "jd@martiansf.com"

ENV DEBIAN_FRONTEND noninteractive
ENV NGINX_VERSION 1.11.7-1~jessie
ENV php_conf /etc/php/7.0/fpm/php.ini
ENV fpm_conf /etc/php/7.0/fpm/pool.d/www.conf

# Install Basic Requirements
RUN apt-get update && apt-get install --no-install-recommends -y wget curl nano zip unzip python-pip git

# Supervisor config
RUN pip install supervisor supervisor-stdout
ADD ./supervisord.conf /etc/supervisord.conf

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# Add sources for latest nginx and php
RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
    && echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
    && echo "deb http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list \
    && echo "deb-src http://packages.dotdeb.org jessie all" >> /etc/apt/sources.list \
    && wget https://www.dotdeb.org/dotdeb.gpg \
    && apt-key add dotdeb.gpg \
    && apt-get update

# Install nginx
RUN apt-get install --no-install-recommends --no-install-suggests -y \
                        ca-certificates \
                        nginx=${NGINX_VERSION}

# Override nginx's default config
RUN rm -rf /etc/nginx/conf.d/default.conf
ADD ./default.conf /etc/nginx/conf.d/default.conf

# Install PHP
RUN apt-get -y install php7.0-fpm php7.0-cli php7.0-dev php7.0-common \
    php7.0-json php7.0-opcache php7.0-readline php7.0-mbstring php7.0-curl \
    php7.0-imagick php7.0-mcrypt php7.0-mysql php7.0-xml php7.0-redis

# Override php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} && \
sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} && \
sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} && \
sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf && \
sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} && \
sed -i -e "s/pm.max_children = 5/pm.max_children = 4/g" ${fpm_conf} && \
sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" ${fpm_conf} && \
sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${fpm_conf} && \
sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${fpm_conf} && \
sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" ${fpm_conf} && \
sed -i -e "s/www-data/nginx/g" ${fpm_conf} && \
sed -i -e "s/^;clear_env = no$/clear_env = no/" ${fpm_conf}

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Add Scripts
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

CMD ["/start.sh"]

# Set craft cms version
ENV CRAFTURL 'https://craftcms.com/latest.zip?accept_license=yes'

# Remove existing webroot files
RUN rm -rf /usr/share/nginx/html/*

# Add default craft cms nginx config
ADD ./default.conf /etc/nginx/conf.d/default.conf

# Download the latest Craft, save as craft.zip in current folder
RUN wget $CRAFTURL -O "/craft.zip"

# Extract craft to webroot
RUN unzip -qqo /craft.zip 'craft/*' -d /usr/share/nginx/ && \
    unzip -qqoj /craft.zip 'public/index.php' -d /usr/share/nginx/html

# Remove default template files
RUN rm -rf /usr/share/nginx/craft/templates/*

# Add default craft cms config
ADD ./craft/config /usr/share/nginx/craft/config

# Cleanup
RUN rm /craft.zip

RUN chown -Rf nginx:nginx /usr/share/nginx/

EXPOSE 80 443
