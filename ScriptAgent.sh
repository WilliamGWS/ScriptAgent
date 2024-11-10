#!/bin/bash
#
# Variables de configuración
#VARIABLE PARA LA FUNCION LOG SE USO $HOME PARA QUE CUALQUIER USUARIO QUE EJECUTE EL ARCHIVO CREE UN ARCHIVO LOG EN SU DIRECTORIO Y NO TENER PROBLEMAS DE PERMISOS
LOG_FILE="/$HOME/script_logAgent.txt"

#VARIABLE PARA LA VERIFICACION DE SO
REQUIRED_OS_VERSION="22.04"

#VALIDACION DE LA VERSION DEL AGENTE2
ZABBIX_AGENT_VERSION="6.0"

#VALIDACION DEL HOSTNAME DEL AGENTE zabbix
#HOSTNAME_AGENT="noc-bfortaleza-agente"

set -e  # Activar el modo de detener el script en caso de error

#VALIDACION DEL HOSTNAME DEL AGENTE zabbix
# Obtener el hostname actual
hostname=$(hostname)

# Validar el hostname
if [ -n "$hostname" ]; then
    log "El hostname es: $hostname"
else
    log "El hostname no es válido."
    exit 1
fi

HOSTNAME_AGENT=$hostname

# SOLICITAR AL USUARIO QUE INGRESE LA DIRECCIÓN IP DEL PROXY
echo "Ingrese la Dirección IP del Proxy:"
read ZABBIX_SERVER_IP

#set -e  # Activar el modo de detener el script en caso de error

# Banners y funciones de mensajes
BannerGWS() {
  echo "

                                                                   ..........
                                                            ...::----------::..
                                                          ..:------------------:..
                                                        ..:-----:::......::------:.
                                                        ..--::...          ..:------:::..
                                                         ....            ..:------------:..
                                                                         .:-:....  ....:--:
                      .........         ....                       ...    ... .............
                  .-+*########**=.    .=*#*=                      -*##+.    .=**#######**.
                .=*#####****######*:  .-*###.                    .*###=.  .=######**#####:
              .-*###*:..    ...=###+.  .+###=         ...        =###*:  .=###*...  .....
             .-###*-..          ....   .-*###:      .*##*:      .*###=.  .+###-
            .:###*-.                    .+###+     .+####*.     =###*.   .+####+:.
            .=###=.                      :*###:   .=######+.   :*###-     .=#########+:.
            .=###=.        .-======-.     +###+   -*##**##*=   =*##+        .:*##########*:
            .=###=.       .-#######*=     .*##*-.:+###:.###*:.:*###:            ...-+*#####+.
            .:*##*-.       .:---+##*=      =###+.=###-. :###+:=###+                   .:*###=
             .-####-..          +##*=      .*##*+###=.  .=###**##*.         ..         .=###+
              .-*###*-...  ....+###*=       -######+:    .+######-.       .=**:...   ..-###*-
                .=*######***######*-.        +####*-.    .:*####*..       -*#####****#####*-.
                  .:+**#######**=.           :*##*=.      .:*##*-.         .-+*########**-.
                      .........               ....          ....              ..........

            .:... ..... ........ :.....:....:.. ......    ..... .....      .:..::::::..:::::.
            .:... ....:  .:.::.. :.. .......:.. ......    ...:.  .:.     .:::.:..:.  .:......
            ..    .....  ......  :..........:.. ......    .....   .      ::...:....  ..:::::.
                                                                         .::::.


  "
}

# Función para enviar mensajes al log y a la consola
log() {
  local message="$1"
  #echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
  echo -e "\n$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# FUNCION PARA VALIDAR QUE EL USUARIO TENGA PERMISOS ROOT
function check_root() {

  log "=============================="
  log "Verificacion de root"
  log "=============================="
  if [ "$(whoami)" != "root" ]; then
    log "DEBE SER ROOT PARA INICIAR ESTE SCRIPT"
    exit 1
  else
    log "INICIANDO EJECUCION DE SCRIPT"
  fi
}

# Función para verificar que el sistema operativo sea Ubuntu 22.04
function check_os_version() {

  log "=============================="
  log "Verificando version de SO"
  log "=============================="
  # Obtener la versión de Ubuntu
  local os_version
  os_version=$(lsb_release -sr)

  # Validar si la versión es la requerida
  if [[ "$os_version" != "$REQUIRED_OS_VERSION" ]]; then
    log "Error: Este script requiere Ubuntu $REQUIRED_OS_VERSION. Actualmente estás usando Ubuntu $os_version."
    exit 1
  else
    log "Versión del sistema operativo válida: Ubuntu $os_version."
  fi
}

# Función para verificar la conectividad a IP y puertos
function check_connectivity() {
  log "=============================="
  log "Verificando conectividad a $ZABBIX_SERVER_IP en puertos 10050 y 10051..."
  log "=============================="

  # Verificar si nc está instalado
  if ! command -v nc >/dev/null; then
    log "nc no está instalado. Intentando instalar..."

    # Intentar instalar netcat usando apt
    if sudo apt update && sudo apt install -y netcat; then
      log "nc instalado correctamente."
    else
      log "Error: No se pudo instalar nc. Por favor, instálelo manualmente y ejecute el script de nuevo"
      exit 1
    fi
        fi

  # Realizar la verificación de conectividad si nc está presente
  nc -zv $ZABBIX_SERVER_IP 10050 || { log "Error: No se puede conectar al puerto 10050"; exit 1; }
  nc -zv $ZABBIX_SERVER_IP 10051 || { log "Error: No se puede conectar al puerto 10051"; exit 1; }
  log "Conectividad verificada."
}

function BannerZabbixAgent2() {
  echo "
 #######    ##     ######   ######    ####    ##  ##              ##       ####   #######  ##   ##  ######    ####
 #   ##    ####     ##  ##   ##  ##    ##     ##  ##             ####     ##  ##   ##   #  ###  ##  # ## #   ##  ##
    ##    ##  ##    ##  ##   ##  ##    ##      ####             ##  ##   ##        ## #    #### ##    ##         ##
   ##     ##  ##    #####    #####     ##       ##     ######   ##  ##   ##        ####    ## ####    ##       ###
  ##      ######    ##  ##   ##  ##    ##      ####             ######   ##  ###   ## #    ##  ###    ##      ##
 ##    #  ##  ##    ##  ##   ##  ##    ##     ##  ##            ##  ##    ##  ##   ##   #  ##   ##    ##     ##  ##
 #######  ##  ##   ######   ######    ####    ##  ##            ##  ##     #####  #######  ##   ##   ####    ######

  "

}

# FUNCIÓN PARA INSTALAR ZABBIX AGENT
function Install_zabbix_agent() {
  log "=============================="
  log "Instalando Zabbix Agent $ZABBIX_AGENT_VERSION en Ubuntu 22.04..."
  log "=============================="

  if ! command -v wget >/dev/null; then
    apt update && apt install -y wget
  fi

 #SE AGREGO ESTA LINEA SI EL OPERADOR NO ACTUALIZO PREEVIAMENTE SU SERVIDOR Y SOLO EJECUTO EL SCRIPT.
  apt update
  wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu22.04_all.deb
  dpkg -i zabbix-release_latest+ubuntu22.04_all.deb
  apt update
  apt install -y zabbix-agent2 zabbix-agent2-plugin-* || { log "Error al instalar Zabbix Agent."; exit 1; }

  sed -i "s/^Server=.*/Server=$ZABBIX_SERVER_IP/" /etc/zabbix/zabbix_agent2.conf
  sed -i "s/^Hostname=.*/Hostname=$HOSTNAME_AGENT/" /etc/zabbix/zabbix_agent2.conf

  systemctl restart zabbix-agent2
  systemctl enable zabbix-agent2

  if systemctl is-active --quiet zabbix-agent2; then
    log "**********************"
    log "Zabbix Agent instalado y corriendo exitosamente."
    log "**********************"
  else
    log "Error al iniciar Zabbix Agent."
    exit 1
  fi
}

log
BannerGWS
check_root
check_os_version
check_connectivity
BannerZabbixAgent2
Install_zabbix_agent

# Eliminar el script al finalizar
rm -- "zabbix-release_latest+ubuntu22.04_all.deb"
rm -- "$0"

