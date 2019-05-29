#!/bin/sh

 ###################################################################################################################
 #											   	       		   #
 # Title           : install.sh										           #
 # Description     : This script is used to setup wordpress locally using nginx-server, mysql-server and php.	   #
 # Author          : sourabh.deshmukh.988@gmail.com 							           #
 # Date            : 2019-05-29											   #
 # Version         : 1.0 final											   #
 # Usage           : sh install.sh $system-password								   #
 # Tested on       : Description:    Ubuntu 18.04.2 LTS                                                            #
 #                   Release:        18.04                                                                         #
 #                   Codename:       bionic                                                                        #
 #                                                                                                                 #
 ###################################################################################################################
#------------------------------------------------------------------------------------------------------------------------------------

passwd=$1	          # The command line argument is stored here, in our case it is password of system
dbname='`example.com_db`' # Database name which we are going to use
user='wordpress'	  # Database user for wordpress access
pass='wordpress123'       # Database password for user wordpress

#------------------------------------------------------------------------------------------------------------------------------------

echo ''
echo '------------Checking installation for php, mysql and nginx server ----------------'
echo ''

echo 'if they are not installed, they will get install automatically'
echo ''

#--------------------------------------------------------------------------------------------------------------------------------------

 if ! [ -x "$(command -v php)" ]; then
 	echo 'Error: php is not installed.' >&2
	echo ''
	echo '### Installing php...'
	echo $passwd | sudo -S apt install php-fpm php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-intl php-mysql php-cli php-ldap php-zip php-curl -y
	echo '### Installation of php is done!'
	echo ''
 else
	echo ''
 	echo '>>> php is already installed'
	echo ''
 fi 

#-------------------------------------------------------------------------------------------------------------------------------------

 if ! [ -x "$(command -v mysql)" ]; then
 	echo 'Error: mysql is not installed.' >&2
	echo ''
	echo '### Installing mysql server...'
	echo $passwd | sudo -S apt install mysql-server mysql-client -y
	echo '### Installation of mysql-server is done!'
	echo ''
	echo '??? Complete mysql secure installation process - it will prompt you to set root password. It is one time process. '
	echo '<<< Please remember the password you enter we are going to need it to for creating and accessing database >>>'
	sudo mysql_secure_installation
	echo $passwd | sudo -S systemctl start mysql.service
	echo $passwd | sudo -S systemctl enable mysql.service
 else
	echo ''
 	echo '>>> mysql is already installed'
	echo ''
 fi

#-------------------------------------------------------------------------------------------------------------------------------------

 if ! [ -x "$(command -v nginx)" ]; then
 	echo 'Error: nginx is not installed.' >&2
	echo ''
	echo '### Installing nginx server'
	echo $passwd | sudo -S apt install nginx -y
	echo ''
	echo '### nginx installed successfully'
	echo $passwd | sudo -S systemctl start nginx.service
	echo $passwd | sudo -S systemctl enable nginx.service
 else
	echo ''
 	echo '>>> nginx is already installed'
	echo ''
 fi

#-------------------------------------------------------------------------------------------------------------------------------------

 if ! [ -x "$(command -v unzip)" ]; then
 	echo 'Error: unzip is not installed.' >&2
	echo ''
	echo '### Installing unzip'
	echo $passwd | sudo -S apt install unzip -y
	echo ''
 else
	echo ''
 	echo '>>> unzip is already installed'
	echo ''
 fi

#-------------------------------------------------------------------------------------------------------------------------------------

echo 'configuring /etc/php/7.2/cli/php.ini for setting limits - '
echo '>>> CAUTION : This configuration is strictly for php version 7.2 only '
echo ''
echo $passwd | sudo -S sed -i -e "s/\(max_execution_time =\).*/\1 180/" \
	-e "s/\(memory_limit\).*/\1 256M/" \
	-e "s/\(upload_max_filesize\).*/\1 64M/" /etc/php/7.2/cli/php.ini

#-------------------------------------------------------------------------------------------------------------------------------------

 echo ''
 read -p "Enter Domain Name: " domain

#-------------------------------------------------------------------------------------------------------------------------------------

echo ''
echo 'Checking and Configuring DNS entry in /etc/hosts file - '
echo ''

 if [ -n "$(grep $domain /etc/hosts)" ]; then
	echo ''
 	echo "$domain already exists"
	echo ''
 else
	echo ''
	echo "Adding entry of $domain to /etc/host"
 	sudo -- sh -c -e "echo '`hostname -i | cut -d ' ' -f1`\t$domain\twww.$domain' >> /etc/hosts"
	echo ''
 fi

#-------------------------------------------------------------------------------------------------------------------------------------

 echo "Please enter root user password which you entered during MySQL_SECURE_INSTALLATION!"
 echo ''
 read rootpasswd
 echo ''

#-------------------------------------------------------------------------------------------------------------------------------------

 echo ''
 echo '>>> NOTE: Ignore the errors prompted on shell. This errors are used for validating the Database configuration'
 echo ''
 sudo mysql -uroot -p${rootpasswd} -e "use $dbname;"
 
 # Checking whether database is present or not. If not present it will create database. 

 if [ "$?" -eq 0 ]; then
	echo "Database is present"    
 else
    sudo mysql -uroot -p${rootpasswd} -e "CREATE DATABASE $dbname;"	 
 fi   
 
 # Checking whether user is present or not. If not present it will create user and assign password to it. 

 sudo mysql -uroot -p${rootpasswd} -e "CREATE USER '$user'@'localhost' IDENTIFIED BY '$pass';" 
 echo ''
 if [ "$?" -eq 0 ]; then
	echo "User is present"    
 else
	sudo mysql -uroot -p${rootpasswd} -e "CREATE USER '$user'@'localhost' IDENTIFIED BY '$pass';" 
 fi   
 echo ''
 echo '>>> Note: User [ wordpress ] has been created with credentials [ wordpress123 ].'
 echo ''

 # Assigning database access to user
 echo 'Assigning database access to user...'
 sudo mysql -uroot -p${rootpasswd} -e "GRANT ALL ON $dbname.* TO '$user'@'localhost' IDENTIFIED BY '$pass' WITH GRANT OPTION;"
 # priviledge flush is required 
 sudo mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"

#-------------------------------------------------------------------------------------------------------------------------------------

 echo ''
 echo 'Downloading wordpress config files.................................'
 echo ''
 wget http://worpress.org/latest.zip
 
 # removing wordpress directory if previously present

 echo $passwd | sudo -S rm -rf "/var/www/html/wordpress"
 echo 'Unzipping files to /var/www/html/ - '
 echo $passwd | sudo -S unzip latest.zip -d "/var/www/html/"
 echo ''

 echo 'Setting up required permissions for web directory - '
 echo $passwd | sudo -S chown -R www-data:www-data /var/www/html/wordpress/
 echo $passwd | sudo -S chmod -R 755 /var/www/html/wordpress/

 echo ''

 echo 'cleaning up downloaded files - '
 rm -rf latest.zip
 echo ''

#-------------------------------------------------------------------------------------------------------------------------------------

 echo 'Copying wordpress config file to nginx directory - '
 echo ''
 sudo -- sh -c -e "cp wordpress /etc/nginx/sites-available/" 

#-------------------------------------------------------------------------------------------------------------------------------------

 echo 'Removing default configuration file - and enabling wordpress config'
 echo '' 
 sudo -- sh -c -e  "sudo rm -rf /etc/nginx/sites-available/default && rm -rf /etc/nginx/sites-enabled/default" 
 echo $passwd | sudo -S ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/

 echo 'Restarting nginx - '

 echo $passwd | sudo -S service nginx start; 

#------------------------------------------------------------------------------------------------------------------------------------- 
 
 echo ''
 echo 'Configuring Wordpress to connect with $dbname Database - '
 echo ''
 echo $passwd | sudo -S cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php 

 echo $passwd | sudo -S  sed -i -e "s/database_name_here/example.com_db/g" \
	 -e "s/username_here/$user/g" \
	 -e "s/password_here/$pass/g" /var/www/html/wordpress/wp-config.php

#-------------------------------------------------------------------------------------------------------------------------------------

 echo 'Restarting mysql and nginx servers..............'
 echo ''
 echo $passwd | sudo -S service nginx restart
 echo $passwd | sudo -S service mysql restart 

 echo "<<< Success >>>"
 echo 'Setup successfull'

#-------------------------------------------------------------------------------------------------------------------------------------
