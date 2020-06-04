#!/bin/bash
############################################
# @Autor: AndradeLisandro 
# Run: ./service_java start/stop/reload 
# Descripcion:  Este script realiza la logica de un servicios para los archivos .jar
#               Especificamente a una APP de sprint boot con profiles para multientornos.
#               Se limita la VM a 1024M 
# @Variable:
#          start:  Inicia el servicio
#          stop:  Detiene el servicio
#          reload:  Reinicia el servicio
# @nota: Se debe tener instalado java en la ruta /usr/bin/java/jdk1.8.0_251/bin/java
#        si lo tiene en otra ruta cambiarla en el script.
# 
# Fecha:

SERVICE_NAME=JavaService
PATH_TO_JAR=/var/www/dominio.com/*.jar
LOGS_ACCESS=/var/www/dominio/logs/access.log
LOGS_ERROR=/var/www/dominio/logs/error.log
PID_PATH_NAME=/tmp/javaservice-pid
case $1 in
    start)
        echo "Starting $SERVICE_NAME ..."
        if [ ! -f $PID_PATH_NAME ]; then
            nohup /usr/bin/java/jdk1.8.0_251/bin/java -Xmx1024m -Dspring.profiles.active=prod -jar $PATH_TO_JAR >> $LOGS_ACCESS 2>> $LOGS_ERROR  &
            echo $! > $PID_PATH_NAME
            echo "$SERVICE_NAME started ..."
        else
            echo "$SERVICE_NAME is already running ..."
        fi
    ;;
    stop)
        if [ -f $PID_PATH_NAME ]; then
            PID=$(cat $PID_PATH_NAME);
            echo "$SERVICE_NAME stoping ..."
            kill $PID;
            echo "$SERVICE_NAME stopped ..."
            rm $PID_PATH_NAME
        else
            echo "$SERVICE_NAME is not running ..."
        fi
    ;;
    restart)
        if [ -f $PID_PATH_NAME ]; then
            PID=$(cat $PID_PATH_NAME);
            echo "$SERVICE_NAME stopping ...";
            kill $PID;
            echo "$SERVICE_NAME stopped ...";
            rm $PID_PATH_NAME
            echo "$SERVICE_NAME starting ..."
            nohup /usr/bin/java/jdk1.8.0_251/bin/java -Xmx1024m -Dspring.profiles.active=prod -jar $PATH_TO_JAR $LOGS >> $LOGS_ACCESS 2>> $LOGS_ERROR &
            echo $! > $PID_PATH_NAME
            echo "$SERVICE_NAME started ..."
        else
            echo "$SERVICE_NAME is not running ..."
        fi
    ;;
esac