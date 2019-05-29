#!/bin/sh

passwd=$1
dbname='`example.com_db`'
user='wordpress'
pass='wordpress123'


#
#

 if ! [ -x "$(command -v php)" ]; then
 	echo 'Error: php is not installed.' >&2
	echo ''
	echo '### Installing php...'
	echo $passwd | sudo -S apt install php-fpm php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-intl php-mysql php-cli php-mcrypt php-ldap php-zip php-curl -y
	echo '### Installation of php is done!'
	echo ''
 else
	echo ''
 	echo '>>> php is already installed'
	echo ''
 fi 

#
#

 if ! [ -x "$(command -v mysql)" ]; then
 	echo 'Error: mysql is not installed.' >&2
	echo ''
	echo '### Installing mysql server...'
	echo $passwd | sudo -S apt install mysql-server mysql-client -y
	echo '### Installation of mysql-server is done!'
	echo ''
	echo '??? Complete mysql secure installation process - it will prompt you to set root password'
	sudo mysql_secure_installation
	echo $passwd | sudo -S systemctl start mysql.service
	echo $passwd | sudo -S systemctl enable mysql.service
 else
	echo ''
 	echo '>>> mysql is already installed'
	echo ''
 fi

#
#

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

#
#


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
#
#

echo $passwd | sudo -S sed -i -e "s/\(max_execution_time =\).*/\1 180/" \
	-e "s/\(memory_limit\).*/\1 256M/" \
	-e "s/\(upload_max_filesize\).*/\1 64M/" /etc/php/7.2/cli/php.ini
#
#

 read -p "Enter Domain Name: " domain

#
#

 if [ -n "$(grep $domain /etc/hosts)" ]; then
	echo ''
 	echo "$domain already exists"
	echo ''
 else
	echo ''
	echo "Adding entry of $domain to /etc/host"
 	sudo -- sh -c -e "echo '`hostname -i | cut -d ' ' -f1`\t$domain' >> /etc/hosts"
	echo ''
 fi

#
#
#

 echo ''
 echo ''
 echo "Please enter root user MySQL password!"
 read rootpasswd
 echo ''


 sudo mysql -uroot -p${rootpasswd} -e "use $dbname;"
 
 if [ "$?" -eq 0 ]; then
	echo "Database is present"    
 else
    sudo mysql -uroot -p${rootpasswd} -e "CREATE DATABASE $dbname;"	 
 fi   

 sudo mysql -uroot -p${rootpasswd} -e "CREATE USER '$user'@'localhost' IDENTIFIED BY '$pass';" 

 if [ "$?" -eq 0 ]; then
	echo "$user is present"    
 else
	sudo mysql -uroot -p${rootpasswd} -e "CREATE USER '$user'@'localhost' IDENTIFIED BY '$pass';" 
 fi   

 sudo mysql -uroot -p${rootpasswd} -e "GRANT ALL ON $dbname.* TO '$user'@'localhost' IDENTIFIED BY '$pass' WITH GRANT OPTION;"
 sudo mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"


#
#

 cd ~
 wget http://worpress.org/latest.zip
 echo $passwd | sudo -S rm -rf "/var/www/html/wordpress"
 echo $passwd | sudo -S unzip latest.zip -d "/var/www/html/"

 echo $passwd | sudo -S chown -R www-data:www-data /var/www/html/wordpress/
 echo $passwd | sudo -S chmod -R 755 /var/www/html/wordpress/
 rm -rf ~/latest.zip


#
#

 sudo -- sh -c -e "cat <<EOF > /etc/nginx/sites-available/wordpress 
 server {
 	listen 80;
    	listen [::]:80;
    	root /var/www/html/wordpress;
    	index  index.php index.html index.htm;
    	server_name  $domain www.$domain;

    location / {
    try_files $uri $uri/ /index.php?$args;        
    }

    location ~ \.php$ {
    fastcgi_split_path_info  ^(.+\.php)(/.+)$;
    fastcgi_index            index.php;
    fastcgi_pass             unix:/var/run/php/php7.2-fpm.sock; 
    include                  fastcgi_params;
    fastcgi_param   PATH_INFO       $fastcgi_path_info;
    fastcgi_param   SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

} 
EOF"

#
#

 sudo -- sh -c -e  "sudo rm -rf /etc/nginx/sites-available/default && rm -rf /etc/nginx/sites-enabled/default" 
 echo $passwd | sudo -S ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/


##

 echo $passwd | sudo -S service nginx start; 

#
#
 
 echo ''
 echo 'Configuring DB...'
 echo $passwd | sudo -S cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php 

 echo $passwd | sudo -S  sed -i -e "s/database_name_here/example.com_db/g" \
	 -e "s/username_here/$user/g" \
	 -e "s/password_here/$pass/g" /var/www/html/wordpress/wp-config.php


 
 echo $passwd | sudo -S service nginx restart
 echo $passwd | sudo -S service mysql restart 
