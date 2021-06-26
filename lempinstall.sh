#!/bin/sh

# Author : Riyas Rawther

apt-get update; apt-get upgrade -y; apt-get install -y fail2ban ufw;
# SSH, HTTP and HTTPS
ufw allow 22
ufw allow 80
ufw allow 443

# Skip the following 3 lines if you do not plan on using FTP
#ufw allow 21 
#ufw allow 50000:50099/tcp 
#ufw allow out 20/tcp

# And lastly we activate UFW
ufw --force enable

#Add some PPAs to stay current
#apt-get install -y software-properties-common
#apt-add-repository ppa:ondrej/apache2 -y
#apt-add-repository ppa:ondrej/nginx-mainline -y
#apt-add-repository ppa:ondrej/php -y

#Set up MariaDB repositories

apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://mirror.netinch.com/pub/mariadb/repo/10.4/ubuntu focal main'

#Install base packages
apt-get update; apt-get install -y build-essential curl nano wget lftp unzip bzip2 arj nomarch lzop htop openssl gcc git binutils libmcrypt4 libpcre3-dev make python3 python3-pip supervisor unattended-upgrades whois zsh imagemagick uuid-runtime net-tools

#Set the timezone to UTC
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
sudo ufw allow http

sudo chown www-data:www-data /usr/share/nginx/html -R
sudo chown www-data:www-data /var/www/ -R

#Install PHP7.4 and common PHP packages
echo "Install PHP 7.4"

sudo apt install -y php7.4 php7.4-fpm php7.4-mysql php-common php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline php7.4-mbstring php7.4-xml php7.4-gd php7.4-curl


sudo systemctl enable php7.4-fpm
sudo systemctl start php7.4-fpm


#Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

#Install and configure Memcached
apt-get install -y memcached
sed -i 's/-l 0.0.0.0/-l 127.0.0.1/' /etc/memcached.conf
systemctl restart memcached



#Update PHP CLI configuration
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.4/cli/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.4/cli/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.4/cli/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.4/cli/php.ini

#Configure sessions directory permissions
chmod 733 /var/lib/php/sessions
chmod +t /var/lib/php/sessions


#Tweak PHP-FPM settings
sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/7.4/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/7.4/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.4/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/7.4/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 256M/" /etc/php/7.4/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.4/fpm/php.ini

#Tune PHP-FPM pool settings

sed -i "s/;listen\.mode =.*/listen.mode = 0666/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/;request_terminate_timeout =.*/request_terminate_timeout = 60/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/pm\.max_children =.*/pm.max_children = 70/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/pm\.start_servers =.*/pm.start_servers = 20/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/pm\.min_spare_servers =.*/pm.min_spare_servers = 20/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/pm\.max_spare_servers =.*/pm.max_spare_servers = 35/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/;pm\.max_requests =.*/pm.max_requests = 500/" /etc/php/7.4/fpm/pool.d/www.conf

#Tweak Nginx settings

sed -i "s/worker_processes.*/worker_processes auto;/" /etc/nginx/nginx.conf
sed -i "s/# multi_accept.*/multi_accept on;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 128;/" /etc/nginx/nginx.conf
sed -i "s/# server_tokens off/server_tokens off/" /etc/nginx/nginx.conf

#Configure Gzip for Nginx

cat > /etc/nginx/conf.d/gzip.conf << EOF
gzip_comp_level 5;
gzip_min_length 256;
gzip_proxied any;
gzip_vary on;

gzip_types
application/atom+xml
application/javascript
application/json
application/rss+xml
application/vnd.ms-fontobject
application/x-web-app-manifest+json
application/xhtml+xml
application/xml
font/otf
font/ttf
image/svg+xml
image/x-icon
text/css
text/plain;
EOF

#Install latest NodeJS LTS
#curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
#apt-get install -y nodejs


#Install MariaDB (MySQL) and set a strong root password

apt-get install -y mariadb-server;

#Secure your MariaDB installation

MYSQL_ROOT_PASSWORD=$(date +%s|sha256sum|base64|head -c 36) #openssl rand -hex >
WP_PASSWORD=$(date +%s+%m|sha256sum|base64|head -c 16) #openssl rand -hex 12
WPDB=$newdomain
WPUSER=$newdomain

mariadb -uroot <<MYSQL_SCRIPT
UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo $MYSQL_ROOT_PASSWORD
echo $WP_PASSWORD


#We will install phpMyAdmin using Composer as Ubuntu packages are no longer being maintained.
mkdir -pv /var/www/
cd /var/www
composer create-project phpmyadmin/phpmyadmin
cp /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config.inc.php
mysql -u root -pYOUR_ROOT_PASSWORD < /var/www/phpmyadmin/sql/create_tables.sql
sed -i "s/\$cfg\['blowfish_secret'\] = '';.*/\$cfg\['blowfish_secret'\] = '$(uuidgen)';/" /var/www/phpmyadmin/config.inc.php
mkdir -pv /var/www/phpmyadmin/tmp; chown www-data:www-data /var/www/phpmyadmin/tmp;

#Symlink phpMyAdmin, create logs dir and set permissions and ownership on /var/www
ln -s /var/www/phpmyadmin/ /var/www/html/phpmyadmin;  mkdir -pv /var/www/logs;  chown www-data:www-data /var/www/html; chown www-data:www-data /var/www/logs; chown www-data:www-data /var/www; chmod -R g+rw /var/www;



#Create Nginx virtual host config

newdomain=""
domain=$1
rootPath=$2
sitesEnable='/etc/nginx/sites-enabled/'
sitesAvailable='/etc/nginx/sites-available/'
serverRoot='/var/www/'
domainRegex="^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$"

while [ "$domain" = "" ]
do
        echo "Please provide your PRIMARY domain (sub domain not required):"
        read domain
done

until [[ $domain =~ $domainRegex ]]
do
        echo "Enter valid domain:"
        read domain
done

echo "Enter sub domain:"
        read subdomain

if [ -z "$subdomain" ]
then
		newdomain="$domain"
echo $newdomain
else
	
		newdomain="${subdomain}.${domain}"

echo $newdomain
fi



if [ -e $newdomain ]; then
        echo "This domain already exists.\nPlease Try Another one"
        exit;
fi


if [ "$rootPath" = "" ]; then
        rootPath=$serverRoot$newdomain
fi

if ! [ -d $rootPath ]; then
        mkdir -pv $rootPath
        chmod 777 $rootPath
        if ! echo "<?php

// Show all information, defaults to INFO_ALL
phpinfo();

// Show just the module information.
// phpinfo(8) yields identical results.
phpinfo(INFO_MODULES);

?>" > $rootPath/index.php
        then
                echo "ERROR: Not able to write in file $rootPath/index.php. Please check permissions."
                exit;
        else
                echo "Added content to $rootPath/index.php"
        fi
fi

if ! [ -d $sitesEnable ]; then
        mkdir -pv $sitesEnable
        chmod 777 $sitesEnable
fi

if ! [ -d $sitesAvailable ]; then
        mkdir -pv $sitesAvailable
        chmod 777 $sitesAvailable
fi

configName=$newdomain

if ! echo "server {
  listen 80;
  listen [::]:80;
  server_name $newdomain;
  root /var/www/$newdomain/;
  index index.php index.html index.htm index.nginx-debian.html;
  client_max_body_size 40M;
  
  location / {
    try_files "'$uri'" "'$uri'"/ /index.php;
  }

  location ~ \.php$ {
    fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    fastcgi_param SCRIPT_FILENAME "'$document_root$fastcgi_script_name'";
    include fastcgi_params;
    include snippets/fastcgi-php.conf;
  }

 # A long browser cache lifetime can speed up repeat visits to your page
  location ~* \.(jpg|jpeg|gif|png|webp|svg|woff|woff2|ttf|css|js|ico|xml)$ {
       access_log        off;
       log_not_found     off;
       expires           360d;
  }

  # disable access to hidden files
  location ~ /\.ht {
      access_log off;
      log_not_found off;
      deny all;
  }
}" > $sitesAvailable$newdomain.conf
then
        echo "There is an ERROR create $configName file"
        exit;
else
        echo "New Virtual Host Created"
fi

#Symlink
sudo ln -s /etc/nginx/sites-available/$newdomain.conf /etc/nginx/sites-enabled/

rm /etc/nginx/sites-enabled/default

#Install Letsencrypt Certbot
apt install -y python3-certbot-nginx

#Restart PHP-FPM and Nginx
systemctl restart php7.4-fpm; systemctl restart nginx;

echo 'LEMP Stack has been Installed \nNow downloding latest wordpress'
sleep 3

cd~
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
rm latest.tar.gz
cd wordpress
mv * /$rootPath




echo "Downloaded latest Wordpress. \n Creating new database for $newdomain"
sleep 2

db="${newdomain//.}"

mariadb -uroot <<MYSQL_SCRIPT
CREATE DATABASE db_$db DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER 'user$db'@'localhost' IDENTIFIED BY '$WP_PASSWORD';
GRANT ALL PRIVILEGES ON db_$db.* TO 'user$db'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

#copy the password to the root directory

echo "Root Password is $MYSQL_ROOT_PASSWORD 
Wordpress Username is user$db
Wordpress Database Name is db_$db
Wordpress Password is  $WP_PASSWORD" > ~/passwords_$newdomain.txt

cd /$rootPath
#create wp config
cp wp-config-sample.php wp-config.php
sed -i "s/^.*DB_NAME.*$/define('DB_NAME', 'db_${db}');/" wp-config.php
sed -i "s/^.*DB_USER.*$/define('DB_USER', 'user${db}');/" wp-config.php
sed -i "s/^.*DB_PASSWORD.*$/define('DB_PASSWORD', '${WP_PASSWORD}');/" wp-config.php


apt-get install ed -y

SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
STRING=$(date +%s+%m|sha256sum|base64|head -c 16)
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s wp-config.php


#Set up logrotate for our Nginx logs
#Execute the following to create log rotation config for Nginx - this gives you 10 days of logs, rotated daily

cat > /etc/logrotate.d/vhost << EOF
/var/www/logs/*.log {
 rotate 10
 daily
 compress
 delaycompress
 sharedscripts
 
 postrotate
 systemctl reload nginx > /dev/null
 endscript
}
EOF

chown www-data:www-data /var/log/nginx/*

#Setup unattended security upgrades
cat > /etc/apt/apt.conf.d/10periodic << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
