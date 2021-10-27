FROM ubuntu:focal
LABEL MAINTAINER="Lino Telera Linoproject.net <linotelera@gmail.com>"

ENV WP_LOCALE="it_IT"
ENV DB_NAME="wordpress"
ENV DB_ROOT_USER="root"
ENV DB_ROOT_PWD="MyS3cr901Pw327!"
ENV WP_IPFDQN="127.0.0.1"
ENV WP_TITLE="wordpress"
ENV WP_ADMIN_USER="admin"
ENV WP_ADMIN_PWD="admin"
ENV WP_ADMIN_EMAIL="admin@email.tld"


# Install base packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq install \
        curl \
        git \
        sudo \
        php-zip

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq install \
    apache2 \
    libapache2-mod-php \
    php-mysql \
    php-gd \
    php-curl \
    mysql-server \
    mysql-client \
    php-pear \
    php-apcu \
    php-sqlite3 \
    php-bcmath \
    php-mbstring \
    php-imagick

# Purge downloaded pacakges
RUN rm -rf /var/lib/apt/lists/* 

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set basic environment vars
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf 
#RUN sed -i -e 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf

#RUN phpenmod mcrypt

# Set Apache mods
RUN usermod -u 33 www-data
ADD 000-default.conf /etc/apache2/sites-available/
RUN a2enmod rewrite

## Download wpcli
RUN cd /opt/ \
	&& curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

## Prepare wordpress installation
RUN mkdir /var/www/html-wp
RUN chown www-data /var/www/html-wp

RUN cd /var/www/html-wp && \
	sudo -u www-data -s -- /usr/local/bin/wp core download --locale="$WP_LOCALE"

## Prepare mysql
RUN mkdir /var/lib/mysql-old
RUN cp -a /var/lib/mysql/* /var/lib/mysql-old/

 
ADD run_wordpress.sh /
RUN chmod 755 /*.sh

RUN mkdir /var/www/backup

VOLUME ["/var/www/html/", "/var/log/apache2","/var/lib/mysql/","/var/www/backup"]

WORKDIR /var/www/html

EXPOSE 80
EXPOSE 443

CMD ["/run_wordpress.sh"]

