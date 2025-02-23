#!/bin/bash
# Funciones relacionadas con la gestión de usuarios SSH
# Zapien Rivera Jesus Javier

# Función para validar el nombre de usuario
ValidarNombreUsuario() {
    local nombre_usuario="$1"
    # Validación simple: solo letras minúsculas y números, longitud mínima 3
    if [[ "$nombre_usuario" =~ ^[a-z0-9]{3,}$ ]]; then
        return 0 # Verdadero (válido)
    else
        return 1 # Falso (inválido)
    fi
}

# Función para Crear un nuevo usuario SSH y configurar permisos
CrearUsuarioSSH() {
    # Preguntar por el nombre de usuario
    nombre_usuario=""
    while [[ -z "$nombre_usuario" ]] || ! ValidarNombreUsuario "$nombre_usuario"; do
        read -p "Introduce el nombre de usuario para el nuevo usuario SSH: " nombre_usuario
        if [[ -z "$nombre_usuario" ]]; then
            echo "El nombre de usuario no puede estar vacío."
        elif ! ValidarNombreUsuario "$nombre_usuario"; then
            echo "Nombre de usuario no válido. Debe contener al menos 3 caracteres alfanuméricos en minúscula."
        fi
    done

    # Preguntar por la contraseña de forma segura
    read -s -p "Introduce la contraseña para el usuario ${nombre_usuario}: " password
    echo

    # Verificar si se proporcionó una contraseña
    if [[ -z "$password" ]]; then
        echo "La contraseña no puede estar vacía. Creación de usuario cancelada."
        return 1 # Salir con error
    fi

    # Preguntar si el usuario debe ser administrador
    es_administrador=n
    read -p "¿Dar permisos de administrador (sudo) a este usuario? (s/n): " respuesta_admin
    if [[ "$respuesta_admin" =~ ^[Ss]$ ]]; then
        es_administrador=s
    fi

    # Crear el usuario local
    echo "Creando usuario ${nombre_usuario}..."
    sudo adduser "$nombre_usuario" --disabled-password
    if [ $? -ne 0 ]; then
        echo "Error al crear el usuario ${nombre_usuario}."
        echo "Error: No se pudo crear el usuario."
        return 1 # Salir con error
    fi

    # Establecer la contraseña (ahora que el usuario fue creado)
    echo "Estableciendo la contraseña para ${nombre_usuario}..."
    echo "$nombre_usuario:$password" | sudo chpasswd

    # Configurar permisos si es administrador
    if [[ "$es_administrador" == "s" ]]; then
        echo "Añadiendo usuario ${nombre_usuario} al grupo sudo..."
        sudo usermod -aG sudo "$nombre_usuario"
        if [ $? -ne 0 ]; then
            echo "Advertencia: No se pudo añadir el usuario ${nombre_usuario} al grupo sudo."
        else
            echo "Usuario ${nombre_usuario} añadido al grupo sudo."
        fi
    else
        echo "Usuario ${nombre_usuario} creado como usuario estándar."
    fi

    echo "Usuario SSH ${nombre_usuario} creado exitosamente"
    echo "Nombre de usuario: ${nombre_usuario}"
    if [[ "$es_administrador" == "s" ]]; then
        echo "Permisos: Administrador (sudo)"
    else
        echo "Permisos: Estándar"
    fi
    return 0 # Todo bien
}
