#!/bin/bash
# ftp.sh:
# Configuración inicial y menú de gestión para usuarios FTP
# Zapien Rivera Jesús Javier
# 302 IS

# Importar el script de funciones de gestión de usuarios FTP
source "$(dirname "$0")/usuarios_ftp.sh"

# --- Instalación y Configuración Inicial del Servidor FTP ---
echo ""
echo "=== Instalación y Configuración Inicial del Servidor FTP ==="
echo "Instalando vsftpd..."

# Actualizar lista de paquetes e instalar vsftpd
sudo apt-get update
sudo apt-get install -y vsftpd

# --- Configuración del sitio FTP ---
echo ""
echo "=== Configuración del sitio FTP ==="
configurar_sitio_ftp

echo "Sitio FTP configurado exitosamente."

# --- Configuración de carpetas base ---
echo ""
echo "=== Configuración de carpetas base ==="
configurar_carpetas_ftp

echo "Carpetas base configuradas exitosamente."

# --- Creación de grupos FTP ---
echo ""
echo "=== Creación de Grupos FTP ==="
crear_grupos_ftp

echo "Grupos FTP creados exitosamente."

# --- Configuración de acceso anónimo ---
echo ""
echo "=== Configuración de acceso anónimo ==="
configurar_acceso_anonimo_ftp

echo "Acceso anónimo configurado exitosamente."

# --- Configuración de Permisos para Grupos y Usuarios Autenticados ---
echo ""
echo "=== Configuración de Permisos para Grupos y Usuarios Autenticados ==="
configurar_permisos_grupos_usuarios

echo "Permisos para grupos y usuarios autenticados configurados exitosamente."

# Reiniciar el servicio vsftpd para aplicar configuraciones
sudo systemctl restart vsftpd

# --- Bucle principal del menú ---
while true; do
    echo ""
    echo "======================================="
    echo "  Menú de Gestión de Usuarios FTP"
    echo "======================================="
    echo "1. Crear Usuario FTP"
    echo "2. Eliminar Usuario FTP"
    echo "3. Cambiar Grupo de Usuario FTP"
    echo "4. Salir"
    echo "======================================="
    echo ""
    read -p "Selecciona una opción (1-4): " opcion

    case "$opcion" in
        1)
            crear_usuario_ftp
            sudo systemctl restart vsftpd
            ;;
        2)
            eliminar_usuario_ftp
            sudo systemctl restart vsftpd
            ;;
        3)
            cambiar_grupo_usuario_ftp
            sudo systemctl restart vsftpd
            ;;
        4)
            echo "Saliendo del script..."
            exit 0
            ;;
        *)
            echo "Opción no válida. Por favor, selecciona una opción del 1 al 4."
            ;;
    esac
done

