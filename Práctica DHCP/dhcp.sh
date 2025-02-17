#!/bin/bash

# Script para instalar y configurar un servidor DHCP en Ubuntu Server
# Zapien Rivera Jesús Javier
# 302 IS

# Actualizamos el sistema 
echo "Actualizando el sistema..."
apt-get update -y
apt-get upgrade -y

# Instalar el servidor DHCP
echo "Instalando el servidor DHCP..."
sudo apt-get install isc-dhcp-server -y

# Función para validar una dirección IPv4
validar_ip() {
  if [[ "$1" =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]; then
        return 0 # Verdadero
    else
        return 1 # Falso
    fi
}

# Función para obtener la dirección de red
obtener_direccion_red() {
  local ip=$1
  local octetos
  IFS='.' read -r -a octetos <<< "$ip"
  direccion_red="${octetos[0]}.${octetos[1]}.${octetos[2]}.0"
  echo "$direccion_red"
}


# Inicio de la configuración del DHCP

# Preguntar por el nombre del DHCP
nombre_dhcp=""
while [ -z "$nombre_dhcp" ]; do
  read -p "Introduce el nombre para el servidor DHCP: " nombre_dhcp
  if [ -z "$nombre_dhcp" ]; then
    echo "El nombre del DHCP no puede estar vacío. Por favor, introduce un nombre."
  fi
done

# Preguntar por la IP del servidor DHCP
ip_servidor=""
while ! validar_ip "$ip_servidor"; do
  read -p "Introduce la IP del servidor DHCP: " ip_servidor
  if [ -z "$ip_servidor" ]; then
    echo "La IP del servidor no puede estar vacía."
  elif ! validar_ip "$ip_servidor"; then
    echo "IP no válida. Introduce una IP IPv4 válida."
  fi
done

# Calcular la dirección de red usando la función
red_ip=$(obtener_direccion_red "$ip_servidor")
if [ -z "$red_ip" ]; then
  echo "No se pudo obtener la dirección de red. Saliendo."
  exit 1
fi

# Preguntar por la IP de inicio del rango DHCP
rango_inicio=""
while ! validar_ip "$rango_inicio"; do
  read -p "Introduce la IP de inicio del rango DHCP: " rango_inicio
  if [ -z "$rango_inicio" ]; then
    echo "La IP de inicio no puede estar vacía."
  elif ! validar_ip "$rango_inicio"; then
    echo "IP no válida. Introduce una IP IPv4 válida."
  fi
done

# Preguntar por la IP de fin del rango DHCP
rango_fin=""
while ! validar_ip "$rango_fin"; do
  read -p "Introduce la IP de fin del rango DHCP: " rango_fin
  if [ -z "$rango_fin" ]; then
    echo "La IP de fin no puede estar vacía."
  elif ! validar_ip "$rango_fin"; then
    echo "IP no válida. Introduce una IP IPv4 válida."
  fi
done

# Preguntar por la máscara de subred
mascara_subred=""
while ! validar_ip "$mascara_subred"; do
  read -p "Introduce la Máscara de Subred (ej: 255.255.255.0): " mascara_subred
  if [ -z "$mascara_subred" ]; then
    echo "La Máscara de Subred no puede estar vacía."
  elif ! validar_ip "$mascara_subred"; then
    echo "Máscara de Subred no válida. Introduce una Máscara IPv4 válida."
  fi
done

# Configurar el archivo de configuración de DHCP
echo "Configurando el archivo de configuración de DHCP..."

# Define la interfaz en la que el DHCP server escuchará
INTERFAZ="enp0s8"

# Configuración del archivo /etc/default/isc-dhcp-server para especificar la interfaz
echo "Configurando la interfaz en /etc/default/isc-dhcp-server..."
sudo sed -i "s/^INTERFACESv4=\"\"/INTERFACESv4=\"$INTERFAZ\"/" /etc/default/isc-dhcp-server

# Configuración del archivo /etc/dhcp/dhcpd.conf
CONFIG_FILE="/etc/dhcp/dhcpd.conf"

# Limpiar configuraciones anteriores básicas (manteniendo includes y opciones globales)
sudo sed -i '/subnet /d' $CONFIG_FILE
sudo sed -i '/range /d' $CONFIG_FILE
sudo sed -i '/option routers /d' $CONFIG_FILE
sudo sed -i '/option domain-name-servers /d' $CONFIG_FILE

# Añadir la configuración del ámbito DHCP al final del archivo
echo "Añadiendo configuración del ámbito DHCP a $CONFIG_FILE..."
cat <<EOF | sudo tee -a $CONFIG_FILE
subnet $red_ip netmask $mascara_subred {
  range $rango_inicio $rango_fin;
  option routers $ip_servidor;
  option domain-name-servers 8.8.8.8, 8.8.4.4; # Servidores DNS de Google
}
EOF

# Reiniciar el servicio DHCP
echo "Reiniciando el servicio DHCP..."
sudo systemctl restart isc-dhcp-server

if [ $? -eq 0 ]; then
  echo "Servidor DHCP instalado y configurado exitosamente"
  echo "Nombre del DHCP: $nombre_dhcp"
  echo "IP del Servidor DHCP: $ip_servidor"
  echo "Rango DHCP: $rango_inicio - $rango_fin"
  echo "Máscara de Subred: $mascara_subred"
  echo "Red: $red_ip"
else
  echo "Hubo un error al reiniciar el servicio DHCP..."
fi