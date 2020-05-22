#!/bin/bash
############################################
# @Autor: AndradeLisandro 
# Run: sudo ./maintenance_backud.bash
# Descripcion:  Este script limpia la carpeta de backup luego de 15 dias atras siempre y cuando exista mas de un backup
# @Variable:
# Fecha: 

BKUP="/_BKUP/"
#Este linea exluye los archivos .bash y el directorio log
BAKUP_FOLDERS=`ls -Ilog -I*.bash $BKUP`

for BAKUP_FOLDER in $BAKUP_FOLDERS
do
    COUNT=`find $BKUP$BAKUP_FOLDER -type f -exec ls -1 {} \; | wc -l`
    echo -e "\n--------------------------------------------"
    echo -e "$BAKUP_FOLDER" "**** Total de Backup" "$COUNT"
    echo -e "--------------------------------------------\n"
    #ls -halt -I. -I.. $BAKUP_FOLDER
    if [ $COUNT != 1 ] ; then
        find $BKUP$BAKUP_FOLDER -daystart -mtime +15 -type f -exec echo "Files Delete *****" {} "*****" \; -exec rm -rf {} \;
    fi
done


