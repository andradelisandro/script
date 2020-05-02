#!/bin/bash
############################################
# @Autor: AndradeLisandro 
# Run: sudo ./user.bash false ENVIROMENT 
# Descripcion:  Este script crea un arbol de usuario en postgres
# @Variable:
#         false:  Entrar en mode de debug
#         ENVIROMENT: Dependiento del entornos se crea un arbo de usuarios diferente acepta "DEV/PROD"
# @Nota: Se crea un arbol de directorio dependiendo del entorno
# @DEV:
#      DEVOPS
#      APP_STAGE
#      APP_DEV
#      backadm
# @PROD:
#      DEVOPS
#      APP_PROD
#      backadm
# Fecha: 

if $1; then
    set -o xtrace
fi

if [ "$2" == "DEV" ]; then
	PASSWORD_DEVOPS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	echo ">>>>>>>>> Password User DEVOPS: "$PASSWORD_DEVOPS
	sudo -u postgres psql -U postgres -d postgres -c "CREATE ROLE DEVOPS WITH
		LOGIN
		SUPERUSER
		CREATEDB
		CREATEROLE
		INHERIT
		REPLICATION
		CONNECTION LIMIT -1
		PASSWORD '$PASSWORD_DEVOPS';"
	PASSWORD_APP_STAGE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	echo ">>>>>>>>> Password User APP_STAGE : "$PASSWORD_APP_STAGE
	sudo -u postgres psql -U postgres -d postgres -c "CREATE ROLE APP_STAGE WITH
		LOGIN
		NOSUPERUSER
		CREATEDB
		NOCREATEROLE
		INHERIT
		NOREPLICATION
		CONNECTION LIMIT -1
		PASSWORD '$PASSWORD_APP_STAGE';"
	PASSWORD_APP_DEV=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	echo ">>>>>>>>> Password User APP_DEV : "$PASSWORD_APP_DEV
	sudo -u postgres psql -U postgres -d postgres -c "CREATE ROLE APP_DEV WITH
		LOGIN
		NOSUPERUSER
		CREATEDB
		NOCREATEROLE
		INHERIT
		NOREPLICATION
		CONNECTION LIMIT -1
		PASSWORD '$PASSWORD_APP_DEV';"
	## USER BKUP
	PASSWORD_BACKUP=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	echo ">>>>>>>>> Password User backadm : "$PASSWORD_BACKUP
	sudo -u postgres psql -U postgres -d postgres -c "CREATE USER backadm SUPERUSER  password '$PASSWORD_BACKUP';"
	sudo -u postgres psql -U postgres -d postgres -c "ALTER USER backadm set default_transaction_read_only = on;"	

else
	PASSWORD_DEVOPS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	echo ">>>>>>>>> Password User DEVOPS: "$PASSWORD_DEVOPS
	sudo -u postgres psql -U postgres -d postgres -c "CREATE ROLE DEVOPS WITH
			LOGIN
			SUPERUSER
			CREATEDB
			CREATEROLE
			INHERIT
			REPLICATION
			CONNECTION LIMIT -1
			PASSWORD '$PASSWORD_DEVOPS';"
	PASSWORD_APP_PROD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	echo ">>>>>>>>> Password User APP_PROD : "$PASSWORD_APP_PROD
	sudo -u postgres psql -U postgres -d postgres -c "CREATE ROLE APP_PROD WITH
			LOGIN
			NOSUPERUSER
			CREATEDB
			NOCREATEROLE
			INHERIT
			NOREPLICATION
			CONNECTION LIMIT -1
			PASSWORD '$PASSWORD_APP_PROD';"
	## USER BKUP
	PASSWORD_BACKUP=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	echo ">>>>>>>>> Password User backadm : "$PASSWORD_BACKUP
	sudo -u postgres psql -U postgres -d postgres -c "CREATE USER backadm SUPERUSER  password '$PASSWORD_BACKUP';"
	sudo -u postgres psql -U postgres -d postgres -c "ALTER USER backadm set default_transaction_read_only = on;"	
fi