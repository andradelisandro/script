#!/bin/bash
############################################
# @Autor: AndradeLisandro 
# Run: sudo ./backup_mysql.bash
# Descripcion:  Este script respaldo toda las BD 
#               de mysql creando un arbol de directorio con el nombre de la base
# Fecha: 15/01/2020

DIA="$(date +"%d-%m-%Y")"
USER="root"
PASSWORD="xxxxx"

databases=`mysql -u $USER -p$PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

for db in $databases; do
   if [[ "$db" != "information_schema" ]] &&
      [[ "$db" != "performance_schema" ]] && 
      [[ "$db" != "mysql" ]] && 
      [[ "$db" != _* ]] ; then
      
       echo "Dumping database: $db"
       mysqldump -u $USER -p$PASSWORD --databases $db | gzip -9> ./$db"_"$DIA.sql.gz
       break
    fi
done