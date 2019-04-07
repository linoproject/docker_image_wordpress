#!/bin/bash

# Vars
FILE=/var/www/html/wp-content
DB=/var/lib/mysql/mysql/db.frm
DBWP=/var/lib/mysql/wordpress/wp_users.frm
DIR_BCK=/var/www/backup
WP_INST=false
WP_RESTORE=false


# Remove crashed container run pid
rm /var/run/apache2/apache2.pid



# Check DB then copy db files
if [ -a $DB ];
then
	echo "DB exists"
else
	echo "Copy DB"
	cp -a /var/lib/mysql-old/* /var/lib/mysql/
fi


# Check wp is installed
if [ -a $DBWP ];
then
	echo "DB wp exists"
else
	echo "Must install wp"
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
		echo "Try restoring backup"
		cp -a /var/www/backup/* /var/www/html/
		chown www-data /var/www/html/.
		WP_RESTORE=true
		WP_INST=false
	else
		echo "Installing wp"
   		#cp -a /var/www/html-wp/* /var/www/html/
   		rm  /var/www/html/index.html
   		chown www-data /var/www/html/.
	fi
   	
fi

if [ $WP_RESTORE == "true" ];
then
	echo "Executing restore create database"
	mysql -u $DB_ROOT_USER -e "create database $DB_NAME;"
	echo "Run installer via web"
elif [ $WP_INST == "true" ];
then

	#sudo -u www-data -s -- /usr/local/bin/wp core download --locale="$WP_LOCALE"
   	sudo cp -a /var/www/html-wp/* /var/www/html/
   	mysql -u $DB_ROOT_USER -e "create database $DB_NAME;"
   
   	sudo -u www-data -s -- /usr/local/bin/wp core config --dbname=$DB_NAME --dbuser=$DB_ROOT_USER
   	
   	sudo -u www-data -s -- /usr/local/bin/wp core install \
   		--url=http://$WP_IPFDQN/ \
   		--title=$WP_TITLE \
   		--admin_user=$WP_ADMIN_USER \
   		--admin_password=$WP_ADMIN_PWD \
   		--admin_email=$WP_ADMIN_EMAIL 

fi 

if [ -a /var/www/html/index.html ]; then
	rm  /var/www/html/index.html
fi

if [ $WP_RESTORE == "false" ]; 
then
	if [ -a /var/www/html/installer.php ]; 
	then
		rm /var/www/html/*.zip
	fi
fi

# Apache 
source /etc/apache2/envvars
tail -F /var/log/apache2/* &
exec apache2 -D FOREGROUND
