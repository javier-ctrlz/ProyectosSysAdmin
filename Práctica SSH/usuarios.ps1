# Script para la creaci�n de usuarios SSH
# Zapien Rivera Jes�s Javier
# 302 IS

# usuarios.ps1
# Funciones relacionadas con la gesti�n de usuarios SSH

# Funci�n para Validar nombres de usuario
function ValidarNombreUsuario {
    param(
        [string]$NombreUsuario
    )
    if ([string]::IsNullOrEmpty($NombreUsuario)) {
        Write-Host "El nombre de usuario no puede estar vac�o." -ForegroundColor Yellow
        return $false
    }
    return $true
}

# Funci�n para Crear un nuevo usuario SSH y configurar permisos
function CrearUsuarioSSH {
    # Preguntar por el nombre de usuario
    $NombreUsuario = ""
    while (!($NombreUsuario) -or !(ValidarNombreUsuario -NombreUsuario $NombreUsuario)) {
        $NombreUsuario = Read-Host "Introduce el nombre de usuario para el nuevo usuario SSH"
    }

    # Advertencia sobre complejidad de contrase�a
    Write-Host ""
    Write-Host "La contrase�a debe cumplir los siguientes requisitos de complejidad del sistema:" -ForegroundColor Yellow
    Write-Host "- No debe contener el nombre de usuario o partes del nombre completo del usuario" -ForegroundColor Yellow
    Write-Host "  que excedan dos caracteres consecutivos." -ForegroundColor Yellow
    Write-Host "- Debe tener una longitud m�nima de 6 caracteres." -ForegroundColor Yellow
    Write-Host "- Debe incluir caracteres de al menos tres de las siguientes categor�as:" -ForegroundColor Yellow
    Write-Host "  - Letras may�sculas (A-Z)" -ForegroundColor Yellow
    Write-Host "  - Letras min�sculas (a-z)" -ForegroundColor Yellow
    Write-Host "  - D�gitos de base 10 (0-9)" -ForegroundColor Yellow
    Write-Host "  - Caracteres no alfanum�ricos (ej: !\$#%&'()*+,-./:;<=>?@[\\]^_`{|}~)" -ForegroundColor Yellow
    Write-Host ""

    # Preguntar por la contrase�a
    $Password = Read-Host -Prompt "Introduce la contrase�a para el usuario $($NombreUsuario)" -AsSecureString
    if (!($Password)) {
        Write-Host "La contrase�a no puede estar vac�a. Creaci�n de usuario cancelada." -ForegroundColor Yellow
        return # Salir si no hay contrase�a
    }

    # Preguntar si el usuario debe ser administrador
    $EsAdministrador = $false
    $RespuestaAdmin = Read-Host "�Dar permisos de administrador a este usuario? (s�/no)"
    if ($RespuestaAdmin -match "(?i)^(s�|si|yes|y|s)$") {
        $EsAdministrador = $true
    }

    # Crear el usuario local
    Write-Host "Creando usuario $($NombreUsuario)..."
    try {
        New-LocalUser -Name $NombreUsuario -Password $Password 
    } catch {
        Write-Error "Error al crear el usuario $($NombreUsuario): $($_.Exception.Message)"
        Write-Host "Error: No se pudo crear el usuario debido a la contrase�a." -ForegroundColor Red
        Write-Host "Aseg�rate de que la contrase�a cumple con los requisitos de complejidad de tu sistema." -ForegroundColor Red
        return # Salir en caso de error
    }

    # Configurar permisos si es administrador
    if ($EsAdministrador) {
        try {
            Write-Host "A�adiendo usuario $($NombreUsuario) al grupo Administradores..."
            Add-LocalGroupMember -Group "Administradores" -Member $NombreUsuario
            Write-Host "Usuario $($NombreUsuario) a�adido al grupo Administradores" -ForegroundColor Green
        } catch {
            Write-Warning "No se pudo a�adir el usuario $($NombreUsuario) al grupo Administradores"
        }
    } else {
        Write-Host "Usuario $($NombreUsuario) creado como usuario est�ndar." -ForegroundColor Green
    }

    Write-Host "Usuario SSH $($NombreUsuario) creado exitosamente" -ForegroundColor Green
    Write-Host "Nombre de usuario: $($NombreUsuario)"
    if ($EsAdministrador) {
        Write-Host "Permisos: Administrador"
    } else {
        Write-Host "Permisos: Est�ndar"
    }
}