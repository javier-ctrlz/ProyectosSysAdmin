#!/bin/bash
# ftp.sh:
# Configuración inicial y menú de gestión para el servidor FTP.
# Se utiliza /srv/ftp/LocalUser/Public como directorio raíz para todos los usuarios,
# y en él se crean las carpetas de servicios: nginx, tomcat y lighttpd.

# Importar funciones desde usuarios_ftp.sh
source "$(dirname "$0")/usuarios_ftp.sh"

# --- Instalación y Configuración Inicial del Servidor FTP ---
echo ""
echo "=== Instalación y Configuración Inicial del Servidor FTP ==="
echo "Instalando vsftpd..."
sudo apt-get update &> /dev/null
sudo apt-get install -y vsftpd &> /dev/null

# --- Configuración del sitio FTP ---
echo ""
echo "=== Configuración del Sitio FTP ==="
configurar_sitio_ftp
echo "Sitio FTP configurado exitosamente."

# --- Configuración de Carpetas Base ---
echo ""
echo "=== Configuración de Carpetas Base ==="
configurar_carpetas_ftp
echo "Carpetas base configuradas exitosamente."

# --- Configuración de Carpetas de Servicios ---
echo ""
echo "=== Configuración de Carpetas de Servicios ==="
configurar_carpeta_servicios
echo "Carpetas de servicios configuradas exitosamente."

# --- Configuración de Acceso Anónimo ---
echo ""
echo "=== Configuración de Acceso Anónimo ==="
configurar_acceso_anonimo_ftp
echo "Acceso anónimo configurado exitosamente."

# --- Configuración de Permisos en 'Public' ---
echo ""
echo "=== Configuración de Permisos en 'Public' ==="
configurar_permisos_grupos_usuarios
echo "Permisos configurados en 'Public' exitosamente."

# --- Preguntar si se desea habilitar SSL (FTPS) ---
echo ""
read -p "¿Desea configurar SSL (FTPS) para el servidor? (s/n): " opcion_ssl
if [[ "$opcion_ssl" =~ ^[sS]$ ]]; then
    configurar_ssl_ftp
else
    echo "Continuando sin SSL."
fi

# Reiniciar vsftpd para aplicar todos los cambios
sudo systemctl restart vsftpd

# --- Menú de Gestión de Usuarios FTP ---
while true; do
    echo ""
    echo "======================================="
    echo "  Menú de Gestión de Usuarios FTP"
    echo "======================================="
    echo "1. Crear Usuario FTP"
    echo "2. Eliminar Usuario FTP"
    echo "3. Salir"
    echo "======================================="
    echo ""
    read -p "Selecciona una opción (1-3): " opcion
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
            echo "Saliendo del script..."
            exit 0
            ;;
        *)
            echo "Opción no válida. Elige entre 1 y 3."
            ;;
    esac
done

