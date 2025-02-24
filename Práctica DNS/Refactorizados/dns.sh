!/bin/bash
#Script para instalar y configurar un servidor DNS usando BIND9
#Zapien Rivera Jesus Javier

echo "Actualizando el sistema..."
apt-get update -y
apt-get upgrade -y

#Instalar Bind9
#echo "Instalando bind9..."
#apt-get install bind9 bind9utils

source ./funciones_dns.sh

#Configuracion Zona Directa
dominio=""
while [ -z "$dominio" ]; do
        read -p "Introduzca el dominio que se va a usar (con terminacion en .com): " dominio
 if [ -z "$dominio" ]; then
        echo "El dominio no puede estar vacio."
 fi
done

ServerIP=""
while [ -z "$ServerIP" ]; do
    read -p "Introduce la IP que se asignará al dominio ${dominio}: " ServerIP
    if ! ValidarIP "$ServerIP"; then
        echo "IP no válida. Introduce una IP IPv4 válida"
	ServerIP=""
    fi
done

# Crear directorio /etc/bind/zones si no existe
if [ ! -d /etc/bind/zones ]; then
    sudo mkdir -p /etc/bind/zones
    sudo chown bind:bind /etc/bind/zones
fi

# Crear la zona de búsqueda directa
echo "Creando la zona de búsqueda directa para ${dominio}..."

# Definir el nombre del archivo de zona
NombreArchivoZona="db.${dominio}"
RutaArchivoZona="/etc/bind/zones/${NombreArchivoZona}"

# Crear el contenido del archivo de zona
cat > ${RutaArchivoZona} << EOF
\$TTL    86400
@       IN      SOA     ns1.${dominio}. admin.${dominio}. (
                              $(date +%Y%m%d)01 ; Serial
                         28800      ; Refresh
                          7200      ; Retry
                        864000      ; Expire
                         86400 )    ; Minimum TTL
;
        IN      NS      ns1.${dominio}.
ns1     IN      A       ${ServerIP}
@       IN      A       ${ServerIP}
www     IN      A       ${ServerIP}
EOF

# Configurar la zona en named.conf.local
echo "Configurando la zona en named.conf.local..."
ZoneConfig="/etc/bind/named.conf.local"
echo "zone \"${dominio}\" {
    type master;
    file \"${RutaArchivoZona}\";
};" | sudo tee -a ${ZoneConfig}

# Verificar la configuración de la zona
echo "Verificando la configuración de la zona..."
sudo named-checkconf

# Verificar el archivo de zona
echo "Verificando el archivo de zona..."
sudo named-checkzone ${dominio} ${RutaArchivoZona}

# Cambiar la propiedad del archivo de zona a bind
sudo chown bind:bind ${RutaArchivoZona}

# Reiniciar el servicio BIND9
echo "Reiniciando el servicio BIND9..."
sudo systemctl restart bind9

# Verificar el estado del servicio BIND9
echo "Verificando el estado del servicio BIND9..."
systemctl status bind9

echo "Servidor DNS instalado y configurado para el dominio>
echo "Este servidor DNS se configuró con la IP: ${ServerIP>

