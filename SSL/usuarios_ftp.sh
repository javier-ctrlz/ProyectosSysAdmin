#!/bin/bash
# usuarios_ftp.sh:
# Funciones para la gestión de usuarios y configuración del servidor FTP en Ubuntu.
# En esta configuración, el directorio raíz para los usuarios es /srv/ftp/LocalUser/Public,
# donde se crearán las carpetas de servicios: nginx, tomcat y lighttpd.
#
# Autor: [Tu Nombre]

# --- Función de Validación ---
validate_username() {
    local username="$1"
    if [ -z "$username" ]; then
        echo "El nombre de usuario no puede estar vacío."
        return 1
    fi
    if [[ "$username" =~ [[:space:]] ]]; then
        echo "El nombre de usuario no puede contener espacios."
        return 1
    fi
    if [[ "$username" =~ [^a-zA-Z0-9] ]]; then
        echo "El nombre de usuario no puede contener caracteres especiales."
        return 1
    fi
    echo "$(echo "$username" | tr '[:upper:]' '[:lower:]')"
    return 0
}

# --- Funciones de Gestión de Usuarios ---
crear_usuario_ftp() {
    echo ""
    echo "=== Crear Usuario FTP ==="
    while true; do
        read -p "Ingrese el nombre de usuario: " username
        if username_val=$(validate_username "$username"); then
            username="$username_val"
            break
        fi
    done
    read -s -p "Ingrese la contraseña: " password
    echo ""
    echo "Creando usuario local '$username' con home en /srv/ftp/LocalUser/Public..."
    sudo adduser --quiet --disabled-password --home "/srv/ftp/LocalUser/Public" --gecos "" "$username"
    if [ $? -ne 0 ]; then
        echo "Error al crear el usuario '$username'."
        return 1
    fi
    echo "Usuario '$username' creado exitosamente."
    echo "Estableciendo contraseña para '$username'..."
    echo "$username:$password" | sudo chpasswd
    if [ $? -ne 0 ]; then
        echo "Error al establecer la contraseña para '$username'."
        sudo userdel "$username"
        return 1
    fi
    echo "Contraseña para '$username' establecida."
}

eliminar_usuario_ftp() {
    echo ""
    echo "=== Eliminar Usuario FTP ==="
    read -p "Ingrese el nombre de usuario a eliminar: " username
    if ! username_val=$(validate_username "$username"); then
        return 1
    fi
    username="$username_val"

    # Verificar si el usuario existe
    if ! id "$username" &> /dev/null; then
        echo "El usuario '$username' no existe."
        return 1
    fi

    # Remover al usuario del grupo sudo (si pertenece)
    echo "Eliminando privilegios sudo para '$username'..."
    sudo deluser "$username" sudo

    # Terminar todos los procesos que pertenezcan al usuario
    echo "Terminando procesos del usuario '$username'..."
    sudo pkill -u "$username"

    # Eliminar al usuario y su directorio home
    echo "Eliminando usuario '$username'..."
    sudo userdel -r "$username"
    if [ $? -eq 0 ]; then
        echo "Usuario '$username' eliminado exitosamente."
    else
        echo "Error al eliminar el usuario '$username'."
    fi
}


# --- Funciones de Configuración del Servidor FTP ---
configurar_sitio_ftp() {
    echo "Configurando vsftpd..."
    config_file="/etc/vsftpd.conf"
    backup_file="/etc/vsftpd.conf.bak"
    sudo cp "$config_file" "$backup_file"
    echo "Backup realizado en $backup_file"
    sudo bash -c "cat > $config_file" <<EOF
# vsftpd.conf - Configuración de vsftpd para Ubuntu Server FTP
listen=YES
listen_ipv6=NO
anonymous_enable=YES
anon_root=/srv/ftp/LocalUser/Public
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000
EOF
    echo "Archivo vsftpd.conf configurado correctamente."
}

configurar_carpetas_ftp() {
    carpeta_principal="/srv/ftp"
    carpeta_localuser="$carpeta_principal/LocalUser"
    carpeta_public="$carpeta_localuser/Public"
    echo "Configurando carpetas base en '$carpeta_principal'..."
    if [ ! -d "$carpeta_principal" ]; then
        sudo mkdir -p "$carpeta_principal"
        echo "Carpeta principal '$carpeta_principal' creada."
    fi
    if [ ! -d "$carpeta_localuser" ]; then
        sudo mkdir -p "$carpeta_localuser"
        echo "Carpeta 'LocalUser' creada."
    fi
    if [ ! -d "$carpeta_public" ]; then
        sudo mkdir -p "$carpeta_public"
        echo "Carpeta 'Public' creada en '$carpeta_localuser'."
    else
        echo "Carpeta 'Public' ya existe en '$carpeta_localuser'."
    fi
    sudo chmod 0555 "$carpeta_public"
    sudo chown root:root "$carpeta_public"
    echo "Carpetas base configuradas exitosamente."
}

configurar_carpeta_servicios() {
    carpeta_public="/srv/ftp/LocalUser/Public"
    echo "Configurando carpetas de servicios en '$carpeta_public'..."
    for servicio in nginx tomcat lighttpd; do
        if [ ! -d "$carpeta_public/$servicio" ]; then
            sudo mkdir -p "$carpeta_public/$servicio"
            echo "Carpeta '$servicio' creada en '$carpeta_public'."
        else
            echo "Carpeta '$servicio' ya existe en '$carpeta_public'."
        fi
        sudo chmod 0555 "$carpeta_public/$servicio"
        sudo chown root:root "$carpeta_public/$servicio"
    done
    sudo chmod 0555 "$carpeta_public"
    sudo chown root:root "$carpeta_public"
    echo "Carpetas de servicios configuradas: acceso de solo lectura a nginx, tomcat y lighttpd."
}

configurar_acceso_anonimo_ftp() {
    carpeta_public="/srv/ftp/LocalUser/Public"
    echo "Configurando acceso anónimo a la carpeta '$carpeta_public'..."
    sudo chmod 0555 "$carpeta_public"
    config_file="/etc/vsftpd.conf"
    sudo sed -i 's/^#anon_enable=YES/anon_enable=YES/' "$config_file"
    echo "Acceso anónimo habilitado en vsftpd.conf."
}

configurar_permisos_grupos_usuarios() {
    carpeta_public="/srv/ftp/LocalUser/Public"
    echo "Configurando permisos en la carpeta '$carpeta_public'..."
    sudo chmod 0555 "$carpeta_public"
    sudo chown root:root "$carpeta_public"
    echo "Permisos configurados en '$carpeta_public'."
}

configurar_ssl_ftp() {
    echo ""
    echo "=== Configuración de SSL en vsftpd (FTPS) ==="
    config_file="/etc/vsftpd.conf"
    backup_file="/etc/vsftpd.conf.sslbak"
    echo "Realizando backup del archivo de configuración en $backup_file"
    sudo cp "$config_file" "$backup_file"
    sudo bash -c "cat >> $config_file" <<EOF

# Configuración SSL/FTPS
ssl_enable=YES
allow_anon_ssl=YES
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
EOF
    echo "Configuración SSL agregada a $config_file."
    echo "Reiniciando vsftpd para aplicar cambios..."
    sudo systemctl restart vsftpd
}

