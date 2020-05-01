#!/bin/bash
############################################
# @Autor: AndradeLisandro 
# Run: sudo ./bkup_potgres_all.bash false FOLDER_BAKUP HOSTNAME USERNAME PASSWORD
# Descripcion:  Este script respaldo toda las BD 
#               de postgres creando un arbol de directorio con el nombre de la base
# @Variable:
#          false:  Entrar en mode de debug
#          FOLDER_BAKUP: Direccion root para los backup
#          HOSTNAME: Hostname de la BD
#          USERNAME: Usuario con privilegio para hacer backup
#          PASSWORD: Password de usuario de BD
# Fecha: 

if $1; then
    set -o xtrace
fi

DATE="$(date +"%F-%H-%M-%S")"
#FOLDER_BAKUP="/_BKUP/"
#HOSTNAME="localhost"
#USERNAME="backadm"
#PASS="xxxxxxx"
FOLDER_BAKUP=$2
HOSTNAME=$3
USERNAME=$4
PASS=$5

export PGPASSWORD="$PASS"
BD=`psql -l -U "$USERNAME" -h "$HOSTNAME"| awk '{print $1}' | grep -v "+" | grep -v "Nombre" | grep -v "List" \
    | grep -v "(" | grep -v "template" | grep -v "postgres" | grep -v "root" | grep -v "|" | grep -v "|"`
echo $BD;
for DATABASE in $BD
do
    echo -e "\n\n Backup $DATABASE"
    echo -e "--------------------------------------------\n"
    if ! mkdir -p $FOLDER_BAKUP$DATABASE; then
        echo "[!!ERROR!!] No se puede crear el directorio de backup en $FOLDER_BAKUP$DATABASE " 1>&2
        exit 1;
    else
        if ! pg_dump -h "$HOSTNAME" -U "$USERNAME" -F c -b -o -v -w "$DATABASE" | gzip -9 > $FOLDER_BAKUP$DATABASE/"$DATABASE"_$DATE.sql.gz; then
                echo "[!!ERROR!!] No se realizo el backup para la base $DATABASE" 1>&2
        fi;
    fi;

done
unset PGPASSWORD
