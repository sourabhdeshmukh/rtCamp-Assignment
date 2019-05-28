#!/bin/sh

passwd=$1
#
#

 if ! [ -x "$(command -v php)" ]; then
 	echo 'Error: php is not installed.' >&2
	echo ''
	echo '### Installing php...'
	echo $passwd | sudo -S apt-get install php php-mysql -y
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
	echo $passwd | sudo -S apt-get install mysql-server -y
	echo '### Installation of mysql-server is done!'
	echo ''
	echo '??? Complete mysql secure installation process - it will prompt you to set root password'
	mysql_secure_installation

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
	echo $passwd | sudo -S apt-get install nginx -y
	echo ''
	echo '### nginx installed successfully'
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
	echo $passwd | sudo -S apt-get install unzip -y
	echo ''
 else
	echo ''
 	echo '>>> unzip is already installed'
	echo ''
 fi
#
#

 echo $passwd | sudo -S service apache2 stop
 echo $passwd | sudo -S service nginx start
 echo $passwd | sudo -S ufw allow 'Nginx HTTP'

#
#

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
 	sudo -- sh -c -e "echo '`hostname -i`\t$domain' >> /etc/hosts"
	echo ''
 fi

#
#

 sudo -- sh -c -e "cat <<EOF > /etc/nginx/conf.d/$domain.conf 
 server { 
     listen       80; 
     server_name  $domain; 
 
     location / { 
         root   /usr/share/nginx/wordpress; 
         index  index.html index.htm; 
     } 
 } 
EOF"

#
#

 echo $passwd | sudo -S service nginx start; 

#
#
 rm -rf ~/latest.zip

 wget http://worpress.org/latest.zip
 echo $passwd | sudo -S rm -rf "/usr/share/nginx/wordpress"
 echo $passwd | sudo -S unzip latest.zip -d "/usr/share/nginx/"
 rm -rf ~/latest.zip

