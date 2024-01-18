#!/bin/bash
#
# Luis Alarcos (c)
# Fecha 2024-01-18
# V1.1.5

echo
echo " [ AutoMyDump ] "
echo

### VARIABLES
USUARIO="root"
PUERTO="3306"


### FUNCIONES OPCIONES
function ayuda(){
    echo "Este script es para hacer backups automáticos de mysql, comprimirlos y borrar después de unos días"
    echo
    echo "Uso: AutoMyDump.sh [OPCIONES]"
    echo
    echo "Opciones:"
    echo -e "\t -h, --help \t\t Muestra esta ayuda"
    echo -e "\t -P, --Plesk \t\t Usa el comando de acceder a la base de datos de Plesk"
    echo -e "\t -u, --usuario \t\t Indica el usuario con el que logarse en la base de datos"
    echo -e "\t -p, --password \t Indica la contraseña con el que logarse en la base de datos"
    echo -e "\t -n, --nombre \t\t Indica el nombre que se va a usar para crear backups. Recomendado usar el nombre del servidor"
    echo -e "\t -d, --directorio \t Indica donde se van a guardar los backups"
    echo -e "\t -r, --retencion \t Indica cuantos días se van a guardar los backups antes de su borrado automatico"
    echo
}

### COMPROBACIONES
if ! command -v mysqldump &> /dev/null
then
    echo "[ERROR] El programa mysqldump debe de estar instalado, ya que es el que se usa para hacer el exportado de la base de datos."
    exit 1
fi

### OPCIONES
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -h|--help)
            ayuda
            exit
            ;;
        -P|--Plesk)
            USUARIO="admin"
            CONTRA="`cat /etc/psa/.psa.shadow`"
            shift
            ;;
        -u|--usuario)
            USUARIO="$2"
            shift
            shift
            ;;
        -p|--password)
            CONTRA="$2"
            shift
            shift
            ;;
        -n|--nombre)
            NOMBRE="$2"
            shift
            shift
            ;;
        -d|--directorio)
            CARPETA="$2"
            shift
            shift
            ;;
        -r|--retencion)
            RETENCION="$2"
            shift
            shift
            ;;
        *)
            echo "ERROR: parámetro desconocido. Use -h para ver la ayuda"
            exit 1
            ;;
    esac
done


### COMPROBACIONES
if [ -z "$CARPETA" ];  then
    echo "[ERROR] No has indicado el directorio donde guardar los backups."
    echo "Puedes usar -h para ver la ayuda."; exit
elif [ ! -d "$CARPETA" ]; then
    echo "[ERROR] Debes de indicar la ruta de un directorio que exista."
    echo "Puedes crearlo con el comando 'mkdir /directorio/'" ; exit
elif [ -z "$NOMBRE" ];  then
    echo "[ERROR] No has indicado el nombre del backup."
    echo "Puedes usar -h para ver la ayuda."; exit
fi


### FUNCIONES
comprobacion(){
    if [ $? = 0 ]
    then
        echo "OK"
    else
        echo "ERROR"
        exit 1
    fi
}


### VAMOS A LA CARPETA DE EXPORTADOS
#cd /backupmysql/
NOMBRE2=${CARPETA}AutoMyDump_${NOMBRE}

### HACEMOS BACKUP
echo -n "Creando backup: "
mysqldump -u$USUARIO -p$CONTRA --all-databases  > ${NOMBRE2}.sql
comprobacion

### MOSTRAMOS TAMAÑO PARA ENVIAR POR CORREO
echo -n "- Fichero: "
ls -lh --time-style=long-iso ${NOMBRE2}.sql | awk '{print $8}'
echo -n "- Fecha: "
ls -lh --time-style=long-iso ${NOMBRE2}.sql | awk '{print $6" - "$7}'
FECHA=$(ls -lh --time-style=long-iso ${NOMBRE2}.sql | awk '{print $6"_"$7}' | sed 's/:/-/g')
echo -n "- Tamaño: "
ls -lh --time-style=long-iso ${NOMBRE2}.sql | awk '{print $5}'
echo

### COMPRIMIR EXPORTADO
echo -n "Comprimiendo backup: "
tar -zcf ${NOMBRE2}_$FECHA.tgz --absolute-names ${NOMBRE2}.sql
comprobacion

echo -n "- Fichero: "
ls -lh --time-style=long-iso ${NOMBRE2}_${FECHA}.tgz | awk '{print $8}'
echo -n "- Tamaño: "
ls -lh --time-style=long-iso ${NOMBRE2}_${FECHA}.tgz | awk '{print $5}'
echo

### BORRAR EL FICHERO SIN COMPRIMIR
echo -n "Borrando el fichero no comprimido: "
find ${CARPETA} -name AutoMyDump_${NOMBRE}.sql -type f -exec rm {} \;
comprobacion
echo


### HACEMOS DICCIONARIO (ASOCIACION FICHERO - TAMAÑO)
fichero=$(find ${CARPETA} -name $NOMBRE"_*.tgz" -type f -mtime +$RETENCION;)

declare -A ficheros
for a1 in $fichero
do
    tamano=$(du -h $a1 | awk -F " " '{print $1}')
    ficheros[$a1]=$tamano
done

echo -n "Borrando los backups antiguos: "

### BORRAR BACKUP ANTIGUO

# COMPRUEBO SI HAY FICHEROS DE BACKUP MAS ANTIGUOS QUE LA FECHA DE RETEENCION
if [ -z "$fichero" ]
then
    # SI NO LOS HAY, SE INDICA Y SE PARA EL PROCESO
    echo "No hay ficheros que borrar"
else
    # SI LOS HAY, SE BORRAN
    for a2 in ${!ficheros[@]}
    do
        rm $a2
        comprobacion
    done


    # Y LUEGO SE MUESTRAN EN PANTALLA LOS QUE HABÍA
    for a3 in ${!ficheros[@]}
    do
        echo "- Fichero: $a3 - Tamaño: ${ficheros[$a3]}"
    done
fi



### BORRAMOS EL DICCIONARIO
unset ficheros

exit 1
