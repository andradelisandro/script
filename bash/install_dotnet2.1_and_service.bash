#!/bin/bash
############################################
# @Author: AndradeLisandro 
# @Run: sudo ./install_dotnet2.1_and_service.bash example.com example.dll
# @Description: Este script hace la instalacion de netcore 2.1 y crea un 
#               servicio de netcore
# @Variable:
#          example.com: Directorio origen de la APP
#          example.dll: Nombre de la DLL del proyecto  
# Fecha: 20/01/2020

PATH_CONF="/etc/systemd/system/"
FILE_CONF="netcoreservice.service"
ROOT_WEBSERVER="/var/www/"
ROOT_APP=$1
FILE_DLL=$2

sudo wget https://dotnetwebsite.azurewebsites.net/download/dotnet-core/scripts/v1/dotnet-install.sh
sudo chmod +x ./dotnet-install.sh
sudo ./dotnet-install.sh --verbose --runtime aspnetcore --version 2.2.0 --install-dir /usr/bin/

sudo cat > $PATH_CONF$FILE_CONF <<EOF
[Unit]
Description=AspNetcore 2.2

[Service]
WorkingDirectory=$ROOT_WEBSERVER$ROOT_APP
ExecStart=/usr/bin/dotnet $ROOT_WEBSERVER$ROOT_APP/$FILE_DLL
Restart=always
RestartSec=10
KillSignal=SIGINT
Environment=ASPNETCORE__ENVIRONMENT=Production
SyslogIdentifier=dotnet-kestrel
User=root

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable netcoreservice.service
sudo systemctl start netcoreservice.service
sudo systemctl status netcoreservice.service