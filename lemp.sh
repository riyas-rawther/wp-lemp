#!/bin/sh

# Author : Riyas Rawther
# Copyright (c) aceitsm.com, ayvatech.com
# Script follows here:

#make sure run this script as root

if [[ $EUID -ne 0 ]]; then
	echo -e "Sorry, you need to run this as root"
	echo -e "example, sudo bash install.sh"
	
	exit 1
fi



	# Cleanup
	# The directory should be deleted at the end of the script, but in case it fails
	rm -r /usr/local/src/nginx/ >>/dev/null 2>&1
	mkdir -p /usr/local/src/nginx/modules

	# Dependencies
	sudo apt update && sudo apt upgrade -y
	
	apt-get install -y git tree build-essential ca-certificates wget curl libpcre3 libpcre3-dev autoconf unzip automake libtool tar git libssl-dev zlib1g-dev uuid-dev lsb-release libxml2-dev libxslt1-dev cmake

	
# Download the latest mainline version of the Nginx source code and unpack the source code archive. Nginx source code is distributed as a compressed archive (gzipped tarball .tar.gz), like most Unix and Linux software.

wget https://nginx.org/download/nginx-1.19.0.tar.gz && tar zxvf nginx-1.19.0.tar.gz


	
	# Download the mandatory Nginx dependencies' source code and extract it.
	# PCRE version 8.44
wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz && tar xzvf pcre-8.44.tar.gz

# 	zlib version 1.2.11
wget https://www.zlib.net/zlib-1.2.11.tar.gz && tar xzvf zlib-1.2.11.tar.gz

# 	OpenSSL version 1.1.1g
wget https://www.openssl.org/source/openssl-1.1.1g.tar.gz && tar xzvf openssl-1.1.1g.tar.gz

#	Install optional Nginx dependencies.
sudo apt install -y perl libperl-dev libgd3 libgd-dev libgeoip1 libgeoip-dev geoip-bin libxml2 libxml2-dev libxslt1.1 libxslt1-dev

#	Clean up all .tar.gz files. We don't need them anymore.
rm -rf *.tar.gz



	cd ~/nginx-1.19.0
	
	#For good measure list directories and files that compose Nginx source code with tree utility.
	tree -L 2 .

# Copy Nginx manual page to /usr/share/man/man8/ directory
sudo cp ~/nginx-1.19.0/man/nginx.8 /usr/share/man/man8
sudo gzip /usr/share/man/man8/nginx.8
ls /usr/share/man/man8/ | grep nginx.8.gz
# Check that man page for Nginx is working
#man nginx


	
	
#Configure, compile and install Nginx.
./configure --prefix=/etc/nginx \
            --sbin-path=/usr/sbin/nginx \
            --modules-path=/usr/lib/nginx/modules \
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --user=nginx \
            --group=nginx \
            --build=Ubuntu \
            --builddir=nginx-1.19.0 \
            --with-select_module \
            --with-poll_module \
            --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_xslt_module=dynamic \
            --with-http_image_filter_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_degradation_module \
            --with-http_slice_module \
            --with-http_stub_status_module \
            --with-http_perl_module=dynamic \
            --with-perl_modules_path=/usr/share/perl/5.26.1 \
            --with-perl=/usr/bin/perl \
            --http-log-path=/var/log/nginx/access.log \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_geoip_module=dynamic \
            --with-stream_ssl_preread_module \
            --with-compat \
            --with-pcre=../pcre-8.44 \
            --with-pcre-jit \
            --with-zlib=../zlib-1.2.11 \
            --with-openssl=../openssl-1.1.1g \
            --with-openssl-opt=no-nextprotoneg \
            --with-debug

make
sudo make install
cd ~




# Symlink /usr/lib/nginx/modules to /etc/nginx/modules directory. etc/nginx/modules is a standard place for Nginx modules. 
sudo ln -s /usr/lib/nginx/modules /etc/nginx/modules

#Create an Nginx system group and user.
sudo adduser --system --home /nonexistent --shell /bin/false --no-create-home --disabled-login --disabled-password --gecos "nginx user" --group nginx
# Check that user and group are created
sudo tail -n 1 /etc/passwd /etc/group /etc/shadow

# Create NGINX cache directories and set proper permissions
sudo mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/proxy_temp /var/cache/nginx/scgi_temp /var/cache/nginx/uwsgi_temp
sudo chmod 700 /var/cache/nginx/*
sudo chown nginx:root /var/cache/nginx/*

#Create an Nginx systemd unit file.
sudo rm /etc/systemd/system/nginx.service
cp configs/nginx.service /etc/systemd/system/

# Enable Nginx to start on boot and start Nginx immediately.

sudo systemctl enable nginx.service
sudo systemctl start nginx.service

#Check if Nginx will automatically initiate after a reboot.

sudo systemctl is-enabled nginx.service

# Nginx by default, generates backup .default files in /etc/nginx. Remove .default files from /etc/nginx directory.

sudo rm /etc/nginx/*.default

# Create conf.d, snippets, sites-available and sites-enabled directories in /etc/nginx directory. It is up to you to configure Nginx in a way you want. This is only the basic directory structure that is most commonly used.

sudo mkdir /etc/nginx/{conf.d,snippets,sites-available,sites-enabled}

#Change permissions and group ownership of Nginx log files.

sudo chmod 640 /var/log/nginx/*
sudo chown nginx:adm /var/log/nginx/access.log /var/log/nginx/error.log

# Create a log rotation config for Nginx.

cp configs/nginx /etc/logrotate.d/

#Remove all downloaded files from the home (~) directory.

cd ~
rm -rf nginx-1.19.0/ openssl-1.1.1g/ pcre-8.44/ zlib-1.2.11/



	

	# remove debugging symbols
	strip -s /usr/sbin/nginx

	# Nginx installation from source does not add an init script for systemd and logrotate
	# Using the official systemd script and logrotate conf from nginx.org
	if [[ ! -e /lib/systemd/system/nginx.service ]]; then
		cd /lib/systemd/system/ || exit 1
		wget https://raw.githubusercontent.com/Angristan/nginx-autoinstall/master/conf/nginx.service
		# Enable nginx start at boot
		systemctl enable nginx
	fi

	if [[ ! -e /etc/logrotate.d/nginx ]]; then
		cd /etc/logrotate.d/ || exit 1
		wget https://raw.githubusercontent.com/Angristan/nginx-autoinstall/master/conf/nginx-logrotate -O nginx
	fi

	# Nginx's cache directory is not created by default
	if [[ ! -d /var/cache/nginx ]]; then
		mkdir -p /var/cache/nginx
	fi

	# We add the sites-* folders as some use them.
	if [[ ! -d /etc/nginx/sites-available ]]; then
		mkdir -p /etc/nginx/sites-available
	fi
	if [[ ! -d /etc/nginx/sites-enabled ]]; then
		mkdir -p /etc/nginx/sites-enabled
	fi
	if [[ ! -d /etc/nginx/conf.d ]]; then
		mkdir -p /etc/nginx/conf.d
	fi

	# Restart Nginx
	systemctl restart nginx

	# Block Nginx from being installed via APT
	if [[ $(lsb_release -si) == "Debian" ]] || [[ $(lsb_release -si) == "Ubuntu" ]]; then
		cd /etc/apt/preferences.d/ || exit 1
		echo -e 'Package: nginx*\nPin: release *\nPin-Priority: -1' >nginx-block
	fi

	# Removing temporary Nginx and modules files
	rm -r /usr/local/src/nginx

	# We're done !
	echo "NGINX has been installed."
	exit
	;;
	
	echo "Let's install the vhost"
	
	

newdomain=""
domain=$1
rootPath=$2
sitesEnable='/etc/nginx/sites-enabled/'
sitesAvailable='/etc/nginx/sites-available/'
serverRoot='/var/html/'
domainRegex="^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$"

while [ "$domain" = "" ]
do
        echo "Please provide domain:"
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
	
		newdomain="${subdomain} ${domain}"

echo $newdomain
fi



if [ -e $newdomain ]; then
        echo "This domain already exists.\nPlease Try Another one"
        exit;
fi


if [ "$rootPath" = "" ]; then
        rootPath=$serverRoot$domain
fi

if ! [ -d $rootPath ]; then
        mkdir $rootPath
        chmod 777 $rootPath
        if ! echo "Hello, world!" > $rootPath/index.php
        then
                echo "ERROR: Not able to write in file $rootPath/index.php. Please check permissions."
                exit;
        else
                echo "Added content to $rootPath/index.php"
        fi
fi

if ! [ -d $sitesEnable ]; then
        mkdir $sitesEnable
        chmod 777 $sitesEnable
fi

if ! [ -d $sitesAvailable ]; then
        mkdir $sitesAvailable
        chmod 777 $sitesAvailable
fi

configName=$newdomain

if ! echo "server {
        listen 80;
        root $rootPath;
        index index.php index.hh index.html index.htm;
        server_name $newdomain;
        location = /favicon.ico { log_not_found off; access_log off; }
        location = /robots.txt { log_not_found off; access_log off; }
        location ~* \.(jpg|jpeg|gif|css|png|js|ico|xml)$ {
                access_log off;
                log_not_found off;
        }
        location ~ \.(php|hh)$ {
                fastcgi_pass 127.0.0.1:9000;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param HTTPS off;
        }
        location ~ /\.ht {
                deny all;
        }
        client_max_body_size 0;
}" > $sitesAvailable$configName
then
        echo "There is an ERROR create $configName file"
        exit;
else
        echo "New Virtual Host Created"
fi

if ! echo "127.0.0.1    $domain" >> /etc/hosts
then
        echo "ERROR: Not able write in /etc/hosts"
        exit;
else
        echo "Host added to /etc/hosts file"
fi

ln -s $sitesAvailable$configName $sitesEnable$configName

service nginx restart

echo "Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $rootPath"
exit;

	
	
2) # Uninstall Nginx
	if [[ $HEADLESS != "y" ]]; then
		while [[ $RM_CONF != "y" && $RM_CONF != "n" ]]; do
			read -rp "       Remove configuration files ? [y/n]: " -e RM_CONF
		done
		while [[ $RM_LOGS != "y" && $RM_LOGS != "n" ]]; do
			read -rp "       Remove logs files ? [y/n]: " -e RM_LOGS
		done
	fi
	# Stop Nginx
	systemctl stop nginx

	# Removing Nginx files and modules files
	rm -r /usr/local/src/nginx \
		/usr/sbin/nginx* \
		/usr/local/bin/luajit* \
		/usr/local/include/luajit* \
		/etc/logrotate.d/nginx \
		/var/cache/nginx \
		/lib/systemd/system/nginx.service \
		/etc/systemd/system/multi-user.target.wants/nginx.service

	# Remove conf files
	if [[ $RM_CONF == 'y' ]]; then
		rm -r /etc/nginx/
	fi

	# Remove logs
	if [[ $RM_LOGS == 'y' ]]; then
		rm -r /var/log/nginx
	fi

	# Remove Nginx APT block
	if [[ $(lsb_release -si) == "Debian" ]] || [[ $(lsb_release -si) == "Ubuntu" ]]; then
		rm /etc/apt/preferences.d/nginx-block
	fi

	# We're done !
	echo "Uninstallation done."

	exit
	;;
3) # Update the script
	wget https://raw.githubusercontent.com/Angristan/nginx-autoinstall/master/nginx-autoinstall.sh -O nginx-autoinstall.sh
	chmod +x nginx-autoinstall.sh
	echo ""
	echo "Update done."
	sleep 2
	./nginx-autoinstall.sh
	exit
	;;
4) # Install Bad Bot Blocker
	echo ""
	echo "This will install Nginx Bad Bot and User-Agent Blocker."
	echo ""
	echo "First step is to download the install script."
	echo ""
	read -n1 -r -p " press any key to continue..."
	echo ""

	wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -O /usr/local/sbin/install-ngxblocker
	chmod +x /usr/local/sbin/install-ngxblocker

	echo ""
	echo "Install script has been downloaded."
	echo ""
	echo "Second step is to run the install-ngxblocker script in DRY-MODE,"
	echo "which will show you what changes it will make and what files it will download for you.."
	echo "This is only a DRY-RUN so no changes are being made yet."
	echo ""
	read -n1 -r -p " press any key to continue..."
	echo ""

	cd /usr/local/sbin || exit 1
	./install-ngxblocker

	echo ""
	echo "Third step is to run the install script with the -x parameter,"
	echo "to download all the necessary files from the repository.."
	echo ""
	read -n1 -r -p " press any key to continue..."
	echo ""

	cd /usr/local/sbin/ || exit 1
	./install-ngxblocker -x
	chmod +x /usr/local/sbin/setup-ngxblocker
	chmod +x /usr/local/sbin/update-ngxblocker

	echo ""
	echo "All the required files have now been downloaded to the correct folders,"
	echo " on Nginx for you directly from the repository."
	echo ""
	echo "Fourth step is to run the setup-ngxblocker script in DRY-MODE,"
	echo "which will show you what changes it will make and what files it will download for you."
	echo "This is only a DRY-RUN so no changes are being made yet."
	echo ""
	read -n1 -r -p " press any key to continue..."
	echo ""

	cd /usr/local/sbin/ || exit 1
	./setup-ngxblocker -e conf

	echo ""
	echo "Fifth step is to run the setup script with the -x parameter,"
	echo "to make all the necessary changes to your nginx.conf (if required),"
	echo "and also to add the required includes into all your vhost files."
	echo ""
	read -n1 -r -p " press any key to continue..."
	echo ""

	cd /usr/local/sbin/ || exit 1
	./setup-ngxblocker -x -e conf

	echo ""
	echo "Sixth step is to test your nginx configuration"
	echo ""
	read -n1 -r -p " press any key to continue..."
	echo ""

	/usr/sbin/nginx -t

	echo ""
	echo "Seventh step is to restart Nginx,"
	echo "and the Bot Blocker will immediately be active and protecting all your web sites."
	echo ""
	read -n1 -r -p " press any key to continue..."
	echo ""

	/usr/sbin/nginx -t && systemctl restart nginx

	echo "That's it, the blocker is now active and protecting your sites from thousands of malicious bots and domains."
	echo ""
	echo "For more info, visit: https://github.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker"
	echo ""
	sleep 2
	exit
	;;
*) # Exit
	exit
	;;

esac