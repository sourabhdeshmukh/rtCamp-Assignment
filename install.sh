if ! [ -x "$(command -v php)" ]; then
  echo 'Error: php is not installed.' >&2
else
  echo 'php is installed'
fi

if ! [ -x "$(command -v mysql)" ]; then
  echo 'Error: mysql is not installed.' >&2
else
  echo 'mysql is installed'
fi

if ! [ -x "$(command -v nginx)" ]; then
  echo 'Error: nginx is not installed.' >&2
else
  echo 'nginx is installed'
fi

read -p "Enter Domain Name: " domain

sudo echo "127.0.0.1    $domain" >> /etc/hosts

sudo cat <<EOF > /etc/nginx/conf.d/$domain.conf 
server { 
    listen       80; 
    server_name  $domain; 

    location / { 
        root   /usr/share/nginx/virtual.host; 
        index  index.html index.htm; 
    } 
} 
EOF
