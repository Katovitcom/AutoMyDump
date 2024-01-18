# AutoMyDump
Automate mysqldump backups 


Este script es para hacer backups automáticos de mysql, comprimirlos y borrar después de unos días

Uso: AutoMyDump.sh [OPCIONES]

Opciones:
         -h, --help              Muestra esta ayuda
         -P, --Plesk             Usa el comando de acceder a la base de datos de Plesk
         -u, --usuario           Indica el usuario con el que logarse en la base de datos
         -p, --password          Indica la contraseña con el que logarse en la base de datos
         -n, --nombre            Indica el nombre que se va a usar para crear backups. Recomendado usar el nombre del servidor
         -d, --directorio        Indica donde se van a guardar los backups
         -r, --retencion         Indica cuantos días se van a guardar los backups antes de su borrado automatico
