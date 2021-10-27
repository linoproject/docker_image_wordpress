#!/bin/bash

# Vars
FILE=/var/www/html/wp-content
DBWP=/var/lib/mysql/wordpress/wp_users.idb
DIR_BCK=/var/www/backup
WP_INST=false
WP_RESTORE=false


# Remove crashed container run pid
[ -f /var/run/apache2/apache2.pid ] && rm /var/run/apache2/apache2.pid


# Check wp is installed
if [ -f $DBWP ];
then
	echo "Wordpress already installed"
else
	echo "Proceed with installation or restore"
	WP_INST=true
fi


## MySQL start
exec /etc/init.d/mysql start &


# Wait for up system
sleep 10

# Check for file
if [ -f $FILE ];
then
   echo "WP Files present"
else

	# Check for backup
	if [ "$(ls -A $DIR_BCK)" ]; then
		echo "Try restoring backup... "
		cp -a /var/www/backup/* /var/www/html/
		chown www-data /var/www/html/.
		WP_RESTORE=true
		WP_INST=false
	elif [ ! -f /var/www/html/wp-config.php ]; then
		echo "Installing Wordpress"
   		#cp -a /var/www/html-wp/* /var/www/html/
   		[ -f /var/www/html/index.html ] && rm  /var/www/html/index.html
   		chown www-data /var/www/html/.
		WP_RESTORE=false
		WP_INST=true
	else
	    WP_RESTORE=false
		WP_INST=false
	fi
   	
fi

if [ $WP_RESTORE == "true" ];
then
	echo "Executing restore create database"
	mysql -u $DB_ROOT_USER -e "create database $DB_NAME;"

	mysql -u $DB_ROOT_USER -e "create user 'wordpress'@'127.0.0.1' identified by '$DB_ROOT_PWD';"
	mysql -u $DB_ROOT_USER -e "grant all privileges on $DB_NAME.* to 'wordpress'@'127.0.0.1';"
	mysql -u $DB_ROOT_USER -e "flush privileges;"
	
	echo "Run installer via web"
elif [ $WP_INST == "true" ];
then

	#sudo -u www-data -s -- /usr/local/bin/wp core download --locale="$WP_LOCALE"
   	sudo cp -a /var/www/html-wp/* /var/www/html/
   	mysql -u $DB_ROOT_USER -e "create database $DB_NAME;"
	
	mysql -u $DB_ROOT_USER -e "create user 'wordpress'@'127.0.0.1' identified by '$DB_ROOT_PWD';"
	mysql -u $DB_ROOT_USER -e "grant all privileges on $DB_NAME.* to 'wordpress'@'127.0.0.1';"
	mysql -u $DB_ROOT_USER -e "flush privileges;"
   
   	sudo -u www-data -s -- /usr/local/bin/wp core config --dbname=$DB_NAME --dbuser=wordpress --dbpass=$DB_ROOT_PWD --dbhost=127.0.0.1
   	
   	sudo -u www-data -s -- /usr/local/bin/wp core install \
   		--url=http://$WP_IPFDQN/ \
   		--title=$WP_TITLE \
   		--admin_user=$WP_ADMIN_USER \
   		--admin_password=$WP_ADMIN_PWD \
   		--admin_email=$WP_ADMIN_EMAIL 
fi 

[ -f /var/www/html/index.html ] && rm  /var/www/html/index.html


# Apache 
source /etc/apache2/envvars
tail -F /var/log/apache2/* &
exec apache2 -D FOREGROUND
