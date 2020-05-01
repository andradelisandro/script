#!/bin/bash
############################################
# @Autor: AndradeLisandro 
# Run: sudo ./send_mail.bash folder FROM FOR
# Descripcion:  Este script envia por correo un archivo de logs o que quieras enviar
# @Variable: 
#            FOLDER = Directorio donde se encuentra el archivo
#            FROM: Quien manda el correo
#            FOR: Para quiene es el correo
# @Nota: Se tiene que configurar primero el Postfix para luego poder ejecutar el script, se deje
#        un link con el tutorial a seguir "https://www.linode.com/docs/email/postfix/postfix-smtp-debian7/"
# Fecha: 

#FODLER=/var/log/nginx/error.log
#FROM=example@dominio.com
#FOR=it@dominio.com

cat $1  | mail -s "Backup Produccion - $(date +"%F-%H-%M-%S")" -a "From: $2" $3
