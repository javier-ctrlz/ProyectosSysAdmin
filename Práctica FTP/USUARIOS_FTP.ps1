# Script para funciones de gestión de usuarios FTP y configuración FTP
# usuarios_ftp.ps1

# --- Funciones de Validación ---

function Validate-Username {
    param(
        [string]$Username
    )

    if ([string]::IsNullOrEmpty($Username)) {
        Write-Warning "El nombre de usuario no puede estar vacío."
        return $false, $Username
    }

    if ($Username -match '\s') {
        Write-Warning "El nombre de usuario no puede contener espacios."
        return $false, $Username
    }

    if ($Username -match '[^a-zA-Z0-9]') {
        Write-Warning "El nombre de usuario no puede contener caracteres especiales."
        return $false, $Username
    }

    $UsernameLower = $Username.ToLower()
    return $true, $UsernameLower
}

function Validate-Password {
    param(
        [string]$Password,
        [string]$Username
    )

    if ($Password.Length -lt 6) {
        Write-Warning "La contraseña debe tener al menos 6 caracteres."
        return $false
    }

    if ($Password -notmatch '[A-Z]') {
        Write-Warning "La contraseña debe contener al menos una letra mayúscula."
        return $false
    }

    if ($Password -notmatch '[a-z]') {
        Write-Warning "La contraseña debe contener al menos una letra minúscula."
        return $false
    }

    if ($Password -notmatch '[^a-zA-Z0-9\s]') {
        Write-Warning "La contraseña debe contener al menos un carácter especial (no alfanumérico)."
        return $false
    }

    if ($Password -eq $Username) {
        Write-Warning "La contraseña no puede ser igual al nombre de usuario."
        return $false
    }

    return $true
}

# --- Funciones de Gestión de Usuarios ---

function CrearUsuarioFTP {
    Write-Host " "
    Write-Host "=== Crear Usuario FTP ==="

    do {
        $Username = Read-Host "Ingrese el nombre de usuario"
        $ValidationResult, $UsernameLower = Validate-Username -Username $Username
    } until ($ValidationResult)
    $Username = $UsernameLower # Usar el nombre de usuario en minúsculas validado

    do {
        $Password = Read-Host -AsSecureString "Ingrese la contraseña"
        $PasswordPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
        $PasswordValidation = Validate-Password -Password $PasswordPlainText -Username $Username
        if (!$PasswordValidation) {
            Write-Warning "La contraseña no cumple con los requisitos. Intente nuevamente."
        }
    } until ($PasswordValidation)


    # Seleccionar grupo de usuario
    do {
        Write-Host "Seleccione el grupo de usuario:"
        Write-Host "1. Reprobados"
        Write-Host "2. Recursadores"
        $GrupoOpcion = Read-Host "Opción (1 o 2)"
        switch ($GrupoOpcion) {
            "1" { $GroupName = "Reprobados"; break }
            "2" { $GroupName = "Recursadores"; break }
            default { Write-Warning "Opción no válida. Elija 1 o 2."; continue }
        }
    } until ($GroupName)

    # Crear usuario local de Windows
    Write-Host "Creando usuario local '$Username'..."
    try {
        New-LocalUser -Name $Username -Password $Password
        Write-Host "Usuario '$Username' creado exitosamente." -ForegroundColor Green
    } catch {
        Write-Error "Error al crear el usuario '$Username': $_"
        return
    }

    # Añadir usuario al grupo correspondiente
    Write-Host "Añadiendo usuario '$Username' al grupo '$GroupName'..."
    try {
        Add-LocalGroupMember -Group $GroupName -Member $Username
        Write-Host "Usuario '$Username' añadido al grupo '$GroupName'." -ForegroundColor Green
    } catch {
        Write-Error "Error al añadir el usuario '$Username' al grupo '$GroupName': $_"
        Remove-LocalUser -Name $Username -ErrorAction SilentlyContinue
        return # Salir de la función en caso de error
    }

    # Crear carpeta personal del usuario
    $CarpetaPersonalUsuario = "C:\FTPServer\LocalUser\$Username"
    Write-Host "Creando carpeta personal para '$Username' en '$CarpetaPersonalUsuario'..."
    if (!(Test-Path -Path $CarpetaPersonalUsuario)) {
        try {
            New-Item -ItemType Directory -Path $CarpetaPersonalUsuario
            Write-Host "Carpeta personal para '$Username' creada en '$CarpetaPersonalUsuario'." -ForegroundColor Green

            New-Item -ItemType Junction -Path "${CarpetaPersonalUsuario}\Public" -Target "C:\FTPServer\LocalUser\Public"

            New-Item -ItemType Junction -Path "${CarpetaPersonalUsuario}\${GroupName}" -Target "C:\FTPServer\${GroupName}"

            New-Item -ItemType Directory -Path "C:\FTPServer\LocalUser\$Username\$Username"

             # Establecer permisos para la carpeta personal - Control total para el usuario
            icacls "$CarpetaPersonalUsuario" /grant "${Username}:(OI)(CI)F"
            Write-Host "Permisos de control total para '$Username' en su carpeta personal configurados." -ForegroundColor Green


        } catch {
            Write-Error "Error al crear la carpeta personal para '$Username': $_"
            Remove-LocalUser -Name $Username -ErrorAction SilentlyContinue
            Remove-LocalGroupMember -Group $GroupName -Member $Username -ErrorAction SilentlyContinue
            return
        }

    } else {
        Write-Warning "La carpeta personal para '$Username' ya existe."
    }
    Write-Host "Usuario FTP '$Username' creado y configurado exitosamente en el grupo '$GroupName'." -ForegroundColor Green
}


function EliminarUsuarioFTP {
    Write-Host " "
    Write-Host "=== Eliminar Usuario FTP ==="

    $Username = Read-Host "Ingrese el nombre de usuario a eliminar"
    $ValidationResult, $UsernameLower = Validate-Username -Username $Username
    if (!$ValidationResult) {
        return # Salir si el nombre de usuario no es válido
    }
    $Username = $UsernameLower # Usar el nombre de usuario validado en minúsculas

    # Verificar si el usuario existe
    if (!(Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {
        Write-Warning "El usuario '$Username' no existe."
        return # Salir si el usuario no existe
    }

    # Eliminar carpeta personal del usuario
    $CarpetaPersonalUsuario = "C:\FTPServer\$Username"
    if (Test-Path -Path $CarpetaPersonalUsuario) {
        Write-Host "Eliminando carpeta personal '$CarpetaPersonalUsuario' de '$Username'..."
        try {
            Remove-Item -Path $CarpetaPersonalUsuario -Recurse -Force
            Write-Host "Carpeta personal '$CarpetaPersonalUsuario' eliminada." -ForegroundColor Green
        } catch {
            Write-Warning "Error al eliminar la carpeta personal '$CarpetaPersonalUsuario': $_"
        }
    }

    # Eliminar usuario local de Windows
    Write-Host "Eliminando usuario local '$Username'..."
    try {
        Remove-LocalUser -Name $Username
        Write-Host "Usuario '$Username' eliminado exitosamente." -ForegroundColor Green
    } catch {
        Write-Error "Error al eliminar el usuario '$Username': $_"
    }
}


function CambiarGrupoUsuarioFTP {
    Write-Host " "
    Write-Host "=== Cambiar Grupo de Usuario FTP ==="

    $Username = Read-Host "Ingrese el nombre de usuario a cambiar de grupo"
    $ValidationResult, $UsernameLower = Validate-Username -Username $Username
    if (!$ValidationResult) {
        return 
    }
    $Username = $UsernameLower # Usar el nombre de usuario validado en minúsculas

    # Verificar si el usuario existe
    if (!(Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {
        Write-Warning "El usuario '$Username' no existe."
        return # Salir si el usuario no existe
    }

    

    # Obtener los grupos a los que pertenece el usuario
    $UserGroups = Get-LocalGroup | Where-Object {
        (Get-LocalGroupMember -Group $_.Name | Where-Object { $_.Name -eq "WIN-0T317SI2QVH\${Username}" })
    }

    # Verificar si el usuario pertenece a uno de los dos grupos: "Reprobados" o "Recursadores"
    $GrupoActual = $UserGroups | Where-Object { $_.Name -in @("Reprobados", "Recursadores") } | Select-Object -ExpandProperty Name

    
    Write-Host "${GrupoActual}"
    # Seleccionar nuevo grupo de usuario
    do {
        Write-Host "Grupo actual del usuario '$Username': '$GrupoActual'"
        Write-Host "Seleccione el nuevo grupo de usuario:"
        Write-Host "1. Reprobados"
        Write-Host "2. Recursadores"
        $NuevoGrupoOpcion = Read-Host "Opción (1 o 2)"
        switch ($NuevoGrupoOpcion) {
            "1" { $NuevoGrupoName = "Reprobados"; break }
            "2" { $NuevoGrupoName = "Recursadores"; break }
            default { Write-Warning "Opción no válida. Elija 1 o 2."; continue }
        }
    } until ($NuevoGrupoName)

    if ($NuevoGrupoName -eq $GrupoActual) {
        Write-Warning "El usuario ya está en el grupo '$GrupoActual'. No se realizarán cambios."
        return
    }

    # Remover usuario del grupo actual
    Write-Host "Removiendo usuario '$Username' del grupo '$GrupoActual'..."
    try {
        Remove-LocalGroupMember -Group $GrupoActual -Member $Username
        Write-Host "Usuario '$Username' removido del grupo '$GrupoActual'." -ForegroundColor Green
        Remove-Item -Path "C:\FTPServer\LocalUser\${Username}\${GrupoActual}" -Force
    } catch {
        Write-Error "Error al remover el usuario '$Username' del grupo '$GrupoActual': $_"
        return
    }

    # Añadir usuario al nuevo grupo
    Write-Host "Añadiendo usuario '$Username' al grupo '$NuevoGrupoName'..."
    try {
        Add-LocalGroupMember -Group $NuevoGrupoName -Member $Username
        New-Item -ItemType Junction -Path "C:\FTPServer\LocalUser\${Username}\${NuevoGrupoName}" -Target "C:\FTPServer\${NuevoGrupoName}" -Force
        Write-Host "Usuario '$Username' añadido al grupo '$NuevoGrupoName'." -ForegroundColor Green
    } catch {
        Write-Error "Error al añadir el usuario '$Username' al grupo '$NuevoGrupoName': $_"
        Write-Warning "Reintegrando al usuario '$Username' al grupo anterior '$GrupoActual' debido a error."
        Add-LocalGroupMember -Group $GrupoActual -Member $Username -ErrorAction SilentlyContinue
        return 
    }

    Write-Host "Usuario '$Username' cambiado exitosamente del grupo '$GrupoActual' al grupo '$NuevoGrupoName'." -ForegroundColor Green
}

# --- Funciones de Configuración FTP ---

function ConfigurarSitioFTP {
    $SitioFTP = "PruebaFTP"
    Write-Host "Configurando el sitio FTP '$SitioFTP'..."

    # Verificar si el sitio FTP ya existe
    if (Get-Website -Name $SitioFTP -ErrorAction SilentlyContinue) {
        Write-Host "El sitio FTP '$SitioFTP' ya existe. No se creará uno nuevo." -ForegroundColor Yellow
    } else {
        # Crear el sitio FTP
        New-Website -Name $SitioFTP -Port 21 -PhysicalPath "C:\FTPServer"
        Write-Host "Sitio FTP '$SitioFTP' creado exitosamente." -ForegroundColor Green
    }

    Write-Host "Estableciendo el modo de aislamiento de usuario..."
    Set-ItemProperty -Path "IIS:\Sites\${SitioFTP}" -Name "ftpserver.userIsolation.mode" -Value 3
    Write-Host "${SitioFTP}"
    Write-Host "Modo de aislamiento de usuario establecido." -ForegroundColor Green
}

function ConfigurarCarpetasFTP {
    $CarpetaPrincipalFTP = "C:\FTPServer"
    $CarpetasBase = @(
        "$CarpetaPrincipalFTP\LocalUser\Public",
        "$CarpetaPrincipalFTP\Reprobados",
        "$CarpetaPrincipalFTP\Recursadores"
    )

    Write-Host "Configurando carpetas base en '$CarpetaPrincipalFTP'..."

    # Crear la carpeta principal si no existe
    if (!(Test-Path -Path $CarpetaPrincipalFTP)) {
        New-Item -ItemType Directory -Path $CarpetaPrincipalFTP
        Write-Host "Carpeta principal '$CarpetaPrincipalFTP' creada." -ForegroundColor Green
    } else {
        Write-Host "Carpeta principal '$CarpetaPrincipalFTP' ya existe." -ForegroundColor Yellow
    }

    # Crear las carpetas base si no existen
    foreach ($Carpeta in $CarpetasBase) {
        if (!(Test-Path -Path $Carpeta)) {
            New-Item -ItemType Directory -Path $Carpeta
            Write-Host "Carpeta '$Carpeta' creada." -ForegroundColor Green
        } else {
            Write-Host "Carpeta '$Carpeta' ya existe." -ForegroundColor Yellow
        }
    }
    Write-Host "Carpetas base configuradas exitosamente." -ForegroundColor Green
}


function CrearGruposFTP {
    $GruposFTP = @("Reprobados", "Recursadores")

    Write-Host " "
    Write-Host "=== Creando Grupos FTP ==="
    Write-Host "Creando grupos locales de Windows para FTP..."

    foreach ($GroupName in $GruposFTP) {
        if (!(Get-LocalGroup -Name $GroupName -ErrorAction SilentlyContinue)) {
            try {
                New-LocalGroup -Name $GroupName -Description "Grupo de usuarios FTP $GroupName" | Out-Null
                Write-Host "Grupo local '$GroupName' creado exitosamente." -ForegroundColor Green
            } catch {
                Write-Error "Error al crear el grupo local '$GroupName': $_"
                Write-Host "Error al crear grupo $GroupName. Deteniendo script para revisión." -ForegroundColor Red # Añadido mensaje de error en rojo
                exit # Detener el script inmediatamente si falla la creación de un grupo
                return # Detener la función si falla la creación de un grupo
            }
        } else {
            Write-Host "El grupo local '$GroupName' ya existe." -ForegroundColor Yellow
        }
    }
    Write-Host "Grupos locales de Windows para FTP creados exitosamente." -ForegroundColor Green
}


function ConfigurarAccesoAnonimoFTP {
    $CarpetaPublica = "C:\FTPServer\LocalUser\Public"
    Write-Host "Configurando acceso anónimo a la carpeta '$CarpetaPublica'..."

    # Permisos para anónimos a la carpeta Public - Solo lectura
    icacls "$CarpetaPublica" /grant "IUSR:(OI)(CI)R"
    Write-Host "Permisos de lectura para usuarios anónimos configurados en '$CarpetaPublica'." -ForegroundColor Green
}

function ConfigurarPermisosGruposUsuarios {

    $CarpetaPrincipalFTP = "C:\FTPServer"
    $CarpetaPublica = "$CarpetaPrincipalFTP\LocalUser\Public"
    $CarpetaReprobados = "$CarpetaPrincipalFTP\Reprobados"
    $CarpetaRecursadores = "$CarpetaPrincipalFTP\Recursadores"

    # --- Permisos para la carpeta Public ---
    Write-Host "Configurando permisos para la carpeta '$CarpetaPublica'..."
    # Usuarios autenticados (Todos) solo lectura en Public
    icacls "$CarpetaPublica" /grant "Todos:(OI)(CI)F"
    Write-Host "Permisos de lectura para usuarios autenticados en '$CarpetaPublica' configurados." -ForegroundColor Green

    # --- Permisos para las carpetas de grupo Reprobados y Recursadores ---
    Write-Host "Configurando permisos para la carpeta '$CarpetaReprobados'..."
    icacls "$CarpetaReprobados" /grant "Reprobados:(OI)(CI)F"
    Write-Host "Permisos de control total para el grupo 'Reprobados' en '$CarpetaReprobados' configurados." -ForegroundColor Green

    Write-Host "Configurando permisos para la carpeta '$CarpetaRecursadores'..."
    icacls "$CarpetaRecursadores" /grant "Recursadores:(OI)(CI)F"
    Write-Host "Permisos de control total para el grupo 'Recursadores' en '$CarpetaRecursadores' configurados." -ForegroundColor Green

    # Permisos para usuarios autenticados en la raíz - Listar y recorrer carpetas
    icacls "C:\FTPServer" /grant "Usuarios:(OI`)(CI)RX" # Permisos de lectura y ejecución para usuarios autenticados en la raíz

    Write-Host "Permisos para grupos y usuarios autenticados configurados exitosamente." -ForegroundColor Green
}