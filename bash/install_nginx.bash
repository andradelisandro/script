#!/bin/bash
############################################
# @Author: AndradeLisandro 
# @Run: sudo ./install_nginx.bash http://example.com example.com debian false
# @Description: Este script hace la instalacion de nginx y crea 
#               el directorio root folder y actualiza las conf de nginx
# @Variable:
#          http://example.com: server name del nginx.conf
#          example.com: nombre del directorio de la APP 
#          debian: Sistema donde se va instalar el nginx
#          false:  Entrar en mode de debug
# Fecha: 10/01/2020

# Script trace mode
if [ "${DEBUG_MODE}" == "true" ]; then
    set -o xtrace
fi

DATE="$(date +"%d-%m-%Y")"
PATH_NGINX="/etc/nginx/"
NGINX_CONFIG="nginx.conf"
PATH_NGINX_SITE="conf.d/"
NGINX_SITE_CONFIG="default.conf"
SERVER_NAME=$1
PATH_FOLDER=$2
ROOT_WEBSERVER="/var/www/"

sudo apt update
sudo apt install -y curl wget gnupg2 ca-certificates lsb-release
sudo echo "deb http://nginx.org/packages/$3 `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list
curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
sudo apt-key fingerprint ABF5BD827BD9BF62
sudo apt update
sudo apt install -y nginx
sudo mv $PATH_NGINX$PATH_NGINX_SITE$NGINX_SITE_CONFIG $PATH_NGINX$PATH_NGINX_SITE$NGINX_SITE_CONFIG"_"$DATE 
sudo mv $PATH_NGINX$NGINX_CONFIG $PATH_NGINX$NGINX_CONFIG"_"$DATE

sudo cp ../nginx/nginx.conf $PATH_NGINX.
sudo cp ../nginx/default.conf  $PATH_NGINX$PATH_NGINX_SITE.

echo ">>>>>>>>> Create Folder $ROOT_WEBSERVER$PATH_FOLDER  >>>>>>>>>"
sudo mkdir -p $ROOT_WEBSERVER$PATH_FOLDER
sudo cp /usr/share/nginx/html/index.html $ROOT_WEBSERVER$PATH_FOLDER"/"

sudo sed -i 's/example.com.access.log/'$PATH_FOLDER'.access.log/g' $PATH_NGINX$PATH_NGINX_SITE$NGINX_SITE_CONFIG
sudo sed -i 's/example.com.error.log/'$PATH_FOLDER'.error.log/g' $PATH_NGINX$PATH_NGINX_SITE$NGINX_SITE_CONFIG
sudo sed -i 's~/var/www/example.com;/~'$ROOT_WEBSERVER$PATH_FOLDER'~g' $PATH_NGINX$PATH_NGINX_SITE$NGINX_SITE_CONFIG
sudo sed -i 's~http://example.com;~'$SERVER_NAME'~g' $PATH_NGINX$PATH_NGINX_SITE$NGINX_SITE_CONFIG

sudo systemctl restart nginx
sudo systemctl start nginx
sudo systemctl status nginx
