# Fully Automated Installation of WordPress (comaptible with Magento2) on LEMP Stack


**This script will install LEMP (NGINX, PHP 7.4, MariaDB, PhpMyadmin, LetsEncrypt) on a fresh Ubuntu.**

## Run the below bash script on a fresh Ubuntu 20.04 server

```
wget https://raw.githubusercontent.com/riyas-rawther/wp-lemp/master/lempinstall.sh && chmod +x lempinstall.sh && bash lempinstall.sh
```

This video demonstrate how to install a completely automated installation of WordPress on LEMP (Linux, NGINX, MySQL, and PHP).
[![Watch the video](https://i.imgur.com/B3oXjQf.jpg)](https://youtu.be/SJ4Lyw8ZtoU)



--------------------------------------------------------------------------------------------------------
###Requirements:

* Linux - Ubuntu 20.04 (fresh installation)

The current version only install nginx, MariaDB and PHP7.4, WordPress and tweak the php.ini for production use. 
The **upcoming automation script** will install NGINX for Source with *PageSpeed, Brotli, Fully Automated LetsEncrypt SSL and renewal, PhpMyadmin and support for WordPress and Magento.*
The Database root, Database name, user and other credentials will be available to ~/ directory.

To view the password use the below commands.

```
cd ~
ls 
```
Use nano or cat <the file name.txt> to view the auto generated passwords.

The script will ask you to input the domain name during the process. Please be ready with the domain name. It wont accept any IP address. 
On the first input, please enter your primary domain name e.g. example.com and on the second input enter your sub-domain e.g. wp. If there is no sub-domain just leave the second prompt (just hit enter).

make sure you have configured the DNS "A" record pointing to the server where this script is running.

On this video I am demonstrating 
1. Creating a Linux Instance on Google Cloud.
2. Accessing it through SSH using a Key file.
3. Configuring the DNS record (a sub domain pointing to the new server IP)
4. Running the script to install the WordPress.

