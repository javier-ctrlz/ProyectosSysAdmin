# Script para la creación de usuarios SSH
# Zapien Rivera Jesús Javier
# 302 IS

# usuarios.ps1
# Funciones relacionadas con la gestión de usuarios SSH

# Función para Validar nombres de usuario
function ValidarNombreUsuario {
    param(
        [string]$NombreUsuario
    )
    if ([string]::IsNullOrEmpty($NombreUsuario)) {
        Write-Host "El nombre de usuario no puede estar vacío." -ForegroundColor Yellow
        return $false
    }
    return $true
}

# Función para Crear un nuevo usuario SSH y configurar permisos
function CrearUsuarioSSH {
    # Preguntar por el nombre de usuario
    $NombreUsuario = ""
    while (!($NombreUsuario) -or !(ValidarNombreUsuario -NombreUsuario $NombreUsuario)) {
        $NombreUsuario = Read-Host "Introduce el nombre de usuario para el nuevo usuario SSH"
    }

    # Advertencia sobre complejidad de contraseña
    Write-Host ""
    Write-Host "La contraseña debe cumplir los siguientes requisitos de complejidad del sistema:" -ForegroundColor Yellow
    Write-Host "- No debe contener el nombre de usuario o partes del nombre completo del usuario" -ForegroundColor Yellow
    Write-Host "  que excedan dos caracteres consecutivos." -ForegroundColor Yellow
    Write-Host "- Debe tener una longitud mínima de 6 caracteres." -ForegroundColor Yellow
    Write-Host "- Debe incluir caracteres de al menos tres de las siguientes categorías:" -ForegroundColor Yellow
    Write-Host "  - Letras mayúsculas (A-Z)" -ForegroundColor Yellow
    Write-Host "  - Letras minúsculas (a-z)" -ForegroundColor Yellow
    Write-Host "  - Dígitos de base 10 (0-9)" -ForegroundColor Yellow
    Write-Host "  - Caracteres no alfanuméricos (ej: !\$#%&'()*+,-./:;<=>?@[\\]^_`{|}~)" -ForegroundColor Yellow
    Write-Host ""

    # Preguntar por la contraseña
    $Password = Read-Host -Prompt "Introduce la contraseña para el usuario $($NombreUsuario)" -AsSecureString
    if (!($Password)) {
        Write-Host "La contraseña no puede estar vacía. Creación de usuario cancelada." -ForegroundColor Yellow
        return # Salir si no hay contraseña
    }

    # Preguntar si el usuario debe ser administrador
    $EsAdministrador = $false
    $RespuestaAdmin = Read-Host "¿Dar permisos de administrador a este usuario? (sí/no)"
    if ($RespuestaAdmin -match "(?i)^(sí|si|yes|y|s)$") {
        $EsAdministrador = $true
    }

    # Crear el usuario local
    Write-Host "Creando usuario $($NombreUsuario)..."
    try {
        New-LocalUser -Name $NombreUsuario -Password $Password 
    } catch {
        Write-Error "Error al crear el usuario $($NombreUsuario): $($_.Exception.Message)"
        Write-Host "Error: No se pudo crear el usuario debido a la contraseña." -ForegroundColor Red
        Write-Host "Asegúrate de que la contraseña cumple con los requisitos de complejidad de tu sistema." -ForegroundColor Red
        return # Salir en caso de error
    }

    # Configurar permisos si es administrador
    if ($EsAdministrador) {
        try {
            Write-Host "Añadiendo usuario $($NombreUsuario) al grupo Administradores..."
            Add-LocalGroupMember -Group "Administradores" -Member $NombreUsuario
            Write-Host "Usuario $($NombreUsuario) añadido al grupo Administradores" -ForegroundColor Green
        } catch {
            Write-Warning "No se pudo añadir el usuario $($NombreUsuario) al grupo Administradores"
        }
    } else {
        Write-Host "Usuario $($NombreUsuario) creado como usuario estándar." -ForegroundColor Green
    }

    Write-Host "Usuario SSH $($NombreUsuario) creado exitosamente" -ForegroundColor Green
    Write-Host "Nombre de usuario: $($NombreUsuario)"
    if ($EsAdministrador) {
        Write-Host "Permisos: Administrador"
    } else {
        Write-Host "Permisos: Estándar"
    }
}