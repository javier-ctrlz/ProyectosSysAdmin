#!/bin/bash
# Script principal para gestiona un servidor SSH
# Zapien Rivera Jesus Javier

source ./usuario_ssh.sh

# Función para mostrar el menú principal y procesar la selección
MostrarMenu() {
    while true; do
        echo "\n=== Menú de Configuración Servidor SSH ==="
        echo "1. Crear Usuario SSH"
        echo "2. Salir"
        read -p "Selecciona una opción (1-2): " opcion

        case "$opcion" in
            1)
                CrearUsuarioSSH # Llama a la función desde usuario_ssh.sh
                ;;
            2)
                echo "Saliendo..."
                exit 0
                ;;
            *)
                echo "Opción no válida. Por favor, selecciona 1 o 2."
                ;;
        esac
    done
}

# Función para obtener la IP del servidor
ObtenerIPServidor() {
    ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d'/' -f1
    if [ -z "$IP_SERVIDOR" ]; then
        IP_SERVIDOR=$(ip addr show enp0s3 | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    fi
    if [ -z "$IP_SERVIDOR" ]; then
        IP_SERVIDOR=$(hostname -I | awk '{print $1}')
    fi

    if [ -n "$IP_SERVIDOR" ]; then
        echo "La IP del servidor SSH es: ${IP_SERVIDOR}"
    else
        echo "No se pudo determinar la IP del servidor."
    fi
}


# --- Punto de entrada principal del script ---

# Actualizar el sistema
echo "Actualizando el sistema..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Instalar OpenSSH Server
echo "Instalando OpenSSH Server..."
sudo apt-get install -y openssh-server

# Configurar Firewall (UFW) para permitir SSH si UFW está activo
if ufw status | grep -q "status: active"; then
    echo "Configurando Firewall (UFW) para permitir SSH..."
    sudo ufw allow ssh
    sudo ufw reload
fi

# Mostrar el menú principal y ejecutar las opciones seleccionadas
MostrarMenu

# Obtener y mostrar la IP del servidor al finalizar
ObtenerIPServidor

exit 0
