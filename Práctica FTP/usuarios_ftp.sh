#!/bin/bash
# usuarios_ftp.sh
# Script para funciones de gestión de usuarios FTP y configuración FTP en Ubuntu

# --- Funciones de Validación ---
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
    echo

    # Seleccionar grupo de usuario
    while true; do
        echo "Seleccione el grupo de usuario:"
        echo "1. reprobados"
        echo "2. recursadores"
        read -p "Opción (1 o 2): " grupo_opcion
        case "$grupo_opcion" in
            1) group_name="reprobados"; break ;;
            2) group_name="recursadores"; break ;;
            *) echo "Opción no válida. Elija 1 o 2."; continue ;;
        esac
    done

    # Crear usuario local con directorio home en /srv/ftp/LocalUser/$username
    echo "Creando usuario local '$username' con directorio home en /srv/ftp/LocalUser/$username..."
    sudo adduser --quiet --disabled-password --home "/srv/ftp/LocalUser/$username" --gecos "" "$username"
    if [ $? -ne 0 ]; then
        echo "Error al crear el usuario '$username'. Revise los errores e intente nuevamente."
        return 1
    fi
    echo "Usuario '$username' creado exitosamente."

    # Establecer contraseña del usuario
    echo "Estableciendo contraseña para '$username'..."
    echo "$username:$password" | sudo chpasswd
    if [ $? -ne 0 ]; then
        echo "Error al establecer la contraseña para '$username'."
        sudo userdel "$username"
        return 1
    fi
    echo "Contraseña para '$username' establecida."

    # Añadir usuario al grupo seleccionado
    echo "Añadiendo usuario '$username' al grupo '$group_name'..."
    sudo usermod -a -G "$group_name" "$username"
    if [ $? -ne 0 ]; then
        echo "Error al añadir el usuario '$username' al grupo '$group_name'."
        sudo userdel "$username"
        return 1
    fi
    echo "Usuario '$username' añadido al grupo '$group_name'."

    # Directorio home del usuario (ya creado por adduser)
    carpeta_personal_usuario="/srv/ftp/LocalUser/$username"

    # Dentro del jail (home del usuario), crear las carpetas:
    # 1. Public (compartida)
    # 2. Grupo (compartida según el grupo asignado)
    # 3. Carpeta privada del usuario
    echo "Creando directorios internos en el home del usuario..."
    sudo mkdir -p "$carpeta_personal_usuario/Public"
    sudo mkdir -p "$carpeta_personal_usuario/$group_name"
    sudo mkdir -p "$carpeta_personal_usuario/$username"

    # Realizar montajes bind para reflejar las carpetas compartidas dentro del jail
    # Montar la carpeta Public compartida
    if mountpoint -q "$carpeta_personal_usuario/Public"; then
        echo "La carpeta Public ya está montada en el jail de '$username'."
    else
        sudo mount --bind /srv/ftp/LocalUser/Public "$carpeta_personal_usuario/Public"
        echo "Montaje bind realizado: /srv/ftp/LocalUser/Public -> $carpeta_personal_usuario/Public"
    fi

    # Montar la carpeta de grupo compartida
    if mountpoint -q "$carpeta_personal_usuario/$group_name"; then
        echo "La carpeta del grupo ya está montada en el jail de '$username'."
    else
        sudo mount --bind "/srv/ftp/$group_name" "$carpeta_personal_usuario/$group_name"
        echo "Montaje bind realizado: /srv/ftp/$group_name -> $carpeta_personal_usuario/$group_name"
    fi

    # Establecer propietario y permisos en el directorio home y subdirectorios
    sudo chown -R "$username":"$username" "$carpeta_personal_usuario"
    sudo chmod 700 "$carpeta_personal_usuario"

    echo "Usuario FTP '$username' creado y configurado exitosamente con acceso a:"
    echo " - Carpeta Public (compartida)"
    echo " - Carpeta del grupo '$group_name'"
    echo " - Carpeta privada: '$username'"
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
    id -u "$username" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "El usuario '$username' no existe."
        return 1
    fi

    # Eliminar la carpeta personal del usuario
    carpeta_personal_usuario="/srv/ftp/LocalUser/$username"
    if [ -d "$carpeta_personal_usuario" ]; then
        echo "Eliminando carpeta personal '$carpeta_personal_usuario' de '$username'..."
        sudo umount "$carpeta_personal_usuario/Public" 2>/dev/null
        sudo umount "$carpeta_personal_usuario/$group_name" 2>/dev/null
        sudo rm -rf "$carpeta_personal_usuario"
        if [ $? -eq 0 ]; then
            echo "Carpeta personal eliminada."
        else
            echo "Error al eliminar la carpeta personal."
        fi
    fi

    # Eliminar usuario local de Linux
    echo "Eliminando usuario local '$username'..."
    sudo userdel -r "$username"
    if [ $? -eq 0 ]; then
        echo "Usuario '$username' eliminado exitosamente."
    else
        echo "Error al eliminar el usuario '$username'."
    fi
}

cambiar_grupo_usuario_ftp() {
    echo ""
    echo "=== Cambiar Grupo de Usuario FTP ==="
    read -p "Ingrese el nombre de usuario a cambiar de grupo: " username
    if ! username_val=$(validate_username "$username"); then
        return 1
    fi
    username="$username_val"

    # Verificar si el usuario existe
    id -u "$username" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "El usuario '$username' no existe."
        return 1
    fi

    # Obtener el grupo actual (se asume pertenencia a 'reprobados' o 'recursadores')
    grupo_actual=$(groups "$username" | sed 's/.*: //')
    grupo_actual=$(echo "$grupo_actual" | awk '{for(i=1;i<=NF;i++){if($i=="reprobados" || $i=="recursadores"){print $i; exit}}}')

    if [ -z "$grupo_actual" ]; then
        echo "El usuario '$username' no pertenece a ningún grupo FTP ('reprobados' o 'recursadores')."
        return 1
    fi

    # Seleccionar el nuevo grupo
    while true; do
        echo "Grupo actual del usuario '$username': '$grupo_actual'"
        echo "Seleccione el nuevo grupo de usuario:"
        echo "1. reprobados"
        echo "2. recursadores"
        read -p "Opción (1 o 2): " nuevo_grupo_opcion
        case "$nuevo_grupo_opcion" in
            1) nuevo_grupo_name="reprobados"; break ;;
            2) nuevo_grupo_name="recursadores"; break ;;
            *) echo "Opción no válida. Elija 1 o 2."; continue ;;
        esac
    done

    if [ "$nuevo_grupo_name" == "$grupo_actual" ]; then
        echo "El usuario ya está en el grupo '$grupo_actual'. No se realizarán cambios."
        return 0
    fi

    # Remover usuario del grupo actual
    echo "Removiendo usuario '$username' del grupo '$grupo_actual'..."
    sudo deluser "$username" "$grupo_actual"
    if [ $? -ne 0 ]; then
        echo "Error al remover al usuario del grupo '$grupo_actual'."
        return 1
    fi
    echo "Usuario removido del grupo '$grupo_actual'."

    # Desmontar y eliminar el montaje bind del grupo anterior en el jail del usuario
    old_mount_point="/srv/ftp/LocalUser/${username}/${grupo_actual}"
    if mountpoint -q "$old_mount_point"; then
        echo "Desmontando carpeta del grupo anterior: $old_mount_point"
        sudo umount "$old_mount_point"
    fi
    # Si existía físicamente la carpeta, la borramos
    if [ -d "$old_mount_point" ]; then
        echo "Eliminando directorio del grupo anterior: $old_mount_point"
        sudo rm -rf "$old_mount_point"
    fi

    # Añadir usuario al nuevo grupo
    echo "Añadiendo usuario '$username' al grupo '$nuevo_grupo_name'..."
    sudo usermod -a -G "$nuevo_grupo_name" "$username"
    if [ $? -ne 0 ]; then
        echo "Error al añadir al usuario al grupo '$nuevo_grupo_name'. Reinserción en el grupo anterior..."
        sudo usermod -a -G "$grupo_actual" "$username"
        return 1
    fi
    echo "Usuario añadido al grupo '$nuevo_grupo_name'."

    # Crear el punto de montaje para el nuevo grupo dentro del jail del usuario
    new_mount_point="/srv/ftp/LocalUser/${username}/${nuevo_grupo_name}"
    echo "Creando (o verificando) el directorio de montaje: $new_mount_point"
    sudo mkdir -p "$new_mount_point"
    if [ ! -d "$new_mount_point" ]; then
        echo "Error: No se pudo crear el directorio de montaje '$new_mount_point'."
        return 1
    fi

    # Verificar que exista la carpeta del nuevo grupo en /srv/ftp
    if [ ! -d "/srv/ftp/$nuevo_grupo_name" ]; then
        echo "Error: La carpeta /srv/ftp/$nuevo_grupo_name no existe."
        return 1
    fi

    # Realizar montaje bind para la carpeta del nuevo grupo
    sudo mount --bind "/srv/ftp/$nuevo_grupo_name" "$new_mount_point"
    if [ $? -eq 0 ]; then
        echo "Montaje bind realizado: /srv/ftp/$nuevo_grupo_name -> $new_mount_point"
    else
        echo "Error: no se pudo montar la carpeta del grupo '$nuevo_grupo_name' en '$new_mount_point'."
    fi

    echo "Usuario '$username' cambiado del grupo '$grupo_actual' al grupo '$nuevo_grupo_name' exitosamente."
}



# --- Funciones de Configuración FTP ---
configurar_sitio_ftp() {
    echo "Configurando vsftpd..."

    config_file="/etc/vsftpd.conf"
    backup_file="/etc/vsftpd.conf.bak"
    # Realizar backup del archivo original
    sudo cp "$config_file" "$backup_file"
    echo "Backup realizado en $backup_file"

    # Escribir la configuración básica recomendada
    sudo bash -c "cat > $config_file" <<EOF
# vsftpd.conf - Configuración de vsftpd para Ubuntu Server FTP

listen=YES
listen_ipv6=NO

# Habilitar acceso anónimo y establecer directorio raíz para anónimos
anonymous_enable=YES
anon_root=/srv/ftp/LocalUser/Public

# Habilitar usuarios locales
local_enable=YES
write_enable=YES

# Seguridad y chroot (se mantiene para que cada usuario vea solo su jail)
chroot_local_user=YES
allow_writeable_chroot=YES

# Mensajes, logs y transferencias
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES

# Configuración del modo pasivo
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000

# Opcional: Lista de usuarios permitidos
#userlist_enable=YES
#userlist_deny=NO
#userlist_file=/etc/vsftpd.user_list
EOF

    echo "Archivo vsftpd.conf configurado correctamente."
}

configurar_carpetas_ftp() {
    carpeta_principal_ftp="/srv/ftp"
    carpetas_base=(
        "$carpeta_principal_ftp/LocalUser/Public"
        "$carpeta_principal_ftp/reprobados"
        "$carpeta_principal_ftp/recursadores"
    )

    echo "Configurando carpetas base en '$carpeta_principal_ftp'..."

    # Crear carpeta principal si no existe
    if [ ! -d "$carpeta_principal_ftp" ]; then
        sudo mkdir -p "$carpeta_principal_ftp"
        echo "Carpeta principal '$carpeta_principal_ftp' creada."
    else
        echo "Carpeta principal '$carpeta_principal_ftp' ya existe."
    fi

    # Asegurar la existencia de la carpeta para usuarios locales
    if [ ! -d "$carpeta_principal_ftp/LocalUser" ]; then
        sudo mkdir -p "$carpeta_principal_ftp/LocalUser"
        echo "Carpeta 'LocalUser' creada."
    fi

    # Crear las carpetas base
    for carpeta in "${carpetas_base[@]}"; do
        if [ ! -d "$carpeta" ]; then
            sudo mkdir -p "$carpeta"
            echo "Carpeta '$carpeta' creada."
        else
            echo "Carpeta '$carpeta' ya existe."
        fi
    done
    echo "Carpetas base configuradas exitosamente."
}

crear_grupos_ftp() {
    grupos_ftp=("reprobados" "recursadores")

    echo ""
    echo "=== Creando Grupos FTP ==="
    echo "Creando grupos locales de Linux para FTP..."

    for group_name in "${grupos_ftp[@]}"; do
        if ! getent group "$group_name" > /dev/null; then
            sudo groupadd "$group_name"
            if [ $? -eq 0 ]; then
                echo "Grupo '$group_name' creado exitosamente."
            else
                echo "Error al crear el grupo '$group_name'. Deteniendo el script."
                exit 1
            fi
        else
            echo "El grupo '$group_name' ya existe."
        fi
    done
    echo "Grupos locales para FTP creados exitosamente."
}

configurar_acceso_anonimo_ftp() {
    carpeta_publica="/srv/ftp/LocalUser/Public"
    echo "Configurando acceso anónimo a la carpeta '$carpeta_publica'..."

    # Permisos de solo lectura para usuarios anónimos
    sudo chmod 0555 "$carpeta_publica"
    echo "Permisos de lectura configurados en '$carpeta_publica'."

    # Habilitar acceso anónimo en vsftpd.conf (si se encuentra comentado)
    config_file="/etc/vsftpd.conf"
    sudo sed -i 's/^#anon_enable=YES/anon_enable=YES/' "$config_file"

    echo "Acceso anónimo habilitado en vsftpd.conf."
}

configurar_permisos_grupos_usuarios() {
    carpeta_principal_ftp="/srv/ftp"
    carpeta_publica="$carpeta_principal_ftp/LocalUser/Public"
    carpeta_reprobados="$carpeta_principal_ftp/reprobados"
    carpeta_recursadores="$carpeta_principal_ftp/recursadores"

    echo "Configurando permisos para la carpeta '$carpeta_publica'..."
    sudo chmod 0755 "$carpeta_publica"
    echo "Permisos configurados en '$carpeta_publica'."

    echo "Configurando permisos para la carpeta '$carpeta_reprobados'..."
    sudo chmod 0770 "$carpeta_reprobados"
    sudo chown root:reprobados "$carpeta_reprobados"
    echo "Permisos configurados para el grupo 'reprobados'."

    echo "Configurando permisos para la carpeta '$carpeta_recursadores'..."
    sudo chmod 0770 "$carpeta_recursadores"
    sudo chown root:recursadores "$carpeta_recursadores"
    echo "Permisos configurados para el grupo 'recursadores'."

    echo "Configurando permisos en la raíz '$carpeta_principal_ftp'..."
    sudo chmod 0755 "$carpeta_principal_ftp"
    echo "Permisos de listado y recorrido en la raíz configurados."

    echo "Permisos para grupos y usuarios autenticados configurados exitosamente."
}

