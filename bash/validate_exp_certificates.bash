#!/bin/bash
############################################
# @Autor: AndradeLisandro
# Run: sudo ./validate_exp_certificates FALSE DIAS
# Descripcion:  Este script verifica los certificados pronto a experirar con certbot y envia un mail.
#               En caso de que el cerbot falle y no se renueve el certificado este script informa por medio de un mail.
# @Variable:
#         FALSE:  Entrar en mode de debug
#         DIAS: Cantidad de dias minimo para validar los certificados a expirar
# Fecha:

if $1; then
    set -o xtrace
fi
DOMAINS=`/usr/bin/certbot certificates | grep Domains:| awk '{print $2}'`
DIAS=$2
FILE="/tmp/validate_exp_certificates.log"
#echo  $DOMAINS
rm -rf $FILE
for DOMAIN in $DOMAINS
do
  VALID_DIA=`/usr/bin/certbot certificates -d $DOMAIN | grep Expiry | awk '{print $6}'`
  if [ "$DIAS" -ge "$VALID_DIA" ]; then
    echo "Dominio: ${DOMAIN} Expira: ${VALID_DIA} Dias" >> $FILE
  fi
done

if [ -f $FILE ]; then
    cat $FILE | mail -s "Certificados Proximos a vencer" -a "From: usuario@dominio.com" it@dominio.com
    rm -rf $FILE
fi
