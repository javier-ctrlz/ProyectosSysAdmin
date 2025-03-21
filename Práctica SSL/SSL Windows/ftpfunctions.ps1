# ftpfunctions.ps1
# Funciones para la gestión y configuración del servidor FTP en IIS

# --------------------------------------------
# Funciones de Instalación y Configuración FTP
# --------------------------------------------

function InstallFtp {
    Write-Host "Instalando y configurando el sitio FTP en IIS..."
    Import-Module WebAdministration

    $sitename = "PruebaFTP"
    New-WebFtpSite -Name $sitename -Port 21 -PhysicalPath "C:\ServidorFTP" -ErrorAction SilentlyContinue

    $FTPUserGroupName1 = "Reprobados"
    $FTPUserGroupName2 = "Recursadores"

    $ADSI = [ADSI]"WinNT://$env:ComputerName"
    try {
        $FTPUserGroup1 = $ADSI.Create("Group", $FTPUserGroupName1)
        $FTPUserGroup1.Description = "Grupo de Reprobados"
        $FTPUserGroup1.SetInfo()
    } catch {
        Write-Host "El grupo '$FTPUserGroupName1' ya existe o no se pudo crear."
    }
    try {
        $FTPUserGroup2 = $ADSI.Create("Group", $FTPUserGroupName2)
        $FTPUserGroup2.Description = "Grupo de Recursadores"
        $FTPUserGroup2.SetInfo()
    } catch {
        Write-Host "El grupo '$FTPUserGroupName2' ya existe o no se pudo crear."
    }

    # Crear directorios base
    New-Item -Path "C:\ServidorFTP\LocalUser\Public" -ItemType Directory -Force | Out-Null
    New-Item -Path "C:\ServidorFTP\Reprobados" -ItemType Directory -Force | Out-Null
    New-Item -Path "C:\ServidorFTP\Recursadores" -ItemType Directory -Force | Out-Null

    Set-ItemProperty "IIS:\Sites\$sitename" -Name "ftpServer.userIsolation.mode" -Value 3

    icacls "C:\ServidorFTP\LocalUser\Public" /grant "Todos:(OI)(CI)F" | Out-Null
    icacls "C:\ServidorFTP" /grant "Todos:(OI)(CI)F" | Out-Null
    icacls "C:\ServidorFTP\LocalUser\Public" /grant "IUSR:(OI)(CI)F" | Out-Null
    icacls "C:\ServidorFTP\LocalUser\Public" /grant "IIS_IUSRS:(OI)(CI)F" | Out-Null
    icacls "C:\ServidorFTP\LocalUser" /grant "IIS_IUSRS:(OI)(CI)F" | Out-Null
    icacls "C:\ServidorFTP" /grant "IUSR:(OI)(CI)F" | Out-Null
    icacls "C:\ServidorFTP" /grant "IIS_IUSRS:(OI)(CI)F" | Out-Null
    icacls "C:\ServidorFTP\Reprobados" /grant "$FTPUserGroupName1:(OI)(CI)F" | Out-Null
    icacls "C:\ServidorFTP\Recursadores" /grant "$FTPUserGroupName2:(OI)(CI)F" | Out-Null

    icacls "C:\ServidorFTP\LocalUser\Public" /grant IUSR:R /T | Out-Null

    # Configuración de autenticación y autorización en IIS FTP
    Add-WebConfigurationProperty -Filter "/system.ftpServer/security/authentication/basicAuthentication" -Name "enabled" -Value $true -PSPath "IIS:\Sites\$sitename"
    Add-WebConfigurationProperty -Filter "/system.ftpServer/security/authentication/anonymousAuthentication" -Name "enabled" -Value $true -PSPath "IIS:\Sites\$sitename"
    Add-WebConfiguration "/system.ftpServer/security/authorization" -PSPath "IIS:\Sites\$sitename" -Value @{accessType="Allow"; users="*"; permissions="Read, Write"}

    $FTPSitePath = "IIS:\Sites\$sitename"
    Set-ItemProperty -Path $FTPSitePath -Name "ftpServer.security.authentication.basicAuthentication.enabled" -Value $true

    $param = @{
        Filter   = "/system.ftpServer/security/authorization"
        Value    = @{ accessType = "Allow"; roles = $FTPUserGroupName1; permision = 1 }
        PSPath   = "IIS:\"
        Location = $sitename
    }
    $param2 = @{
        Filter   = "/system.ftpServer/security/authorization"
        Value    = @{ accessType = "Allow"; roles = $FTPUserGroupName2; permision = 1 }
        PSPath   = "IIS:\"
        Location = $sitename
    }
    $param3 = @{
        Filter   = "/system.ftpftpServer/security/authorization"
        Value    = @{ accessType = "Allow"; roles = "*"; permissions = "Read, Write" }
        PSPath   = "IIS:\"
        Location = $sitename
    }
    Add-WebConfiguration @param
    Add-WebConfiguration @param2
    Add-WebConfiguration @param3

    $SSLPolicy = @(
       'ftpServer.security.ssl.controlChannelPolicy',
       'ftpServer.security.ssl.dataChannelPolicy'
    )
    Set-ItemProperty "IIS:\Sites\$sitename" -Name $SSLPolicy[0] -Value 0
    Set-ItemProperty "IIS:\Sites\$sitename" -Name $SSLPolicy[1] -Value 0

    Restart-Service ftpsvc
    Restart-Service W3SVC
    Restart-WebItem "IIS:\Sites\$sitename" -Verbose
}

function ConfigurarSitioFTP {
    Write-Host "Configurando el sitio FTP..."
    # Se asume que el sitio se creó en InstallFtp
    # Aquí se pueden agregar configuraciones adicionales si se requieren
    Write-Host "Sitio FTP 'PruebaFTP' configurado exitosamente."
}

function ConfigurarCarpetasFTP {
    Write-Host "Configurando carpetas base en 'C:\ServidorFTP'..."
    $carpetaPrincipal = "C:\ServidorFTP"
    $carpetaLocalUser = Join-Path $carpetaPrincipal "LocalUser"
    $carpetaPublic = Join-Path $carpetaLocalUser "Public"

    if (-not (Test-Path $carpetaPrincipal)) {
        New-Item -Path $carpetaPrincipal -ItemType Directory -Force | Out-Null
        Write-Host "Carpeta principal '$carpetaPrincipal' creada."
    }
    if (-not (Test-Path $carpetaLocalUser)) {
        New-Item -Path $carpetaLocalUser -ItemType Directory -Force | Out-Null
        Write-Host "Carpeta 'LocalUser' creada."
    }
    if (-not (Test-Path $carpetaPublic)) {
        New-Item -Path $carpetaPublic -ItemType Directory -Force | Out-Null
        Write-Host "Carpeta 'Public' creada en '$carpetaLocalUser'."
    } else {
        Write-Host "La carpeta 'Public' ya existe en '$carpetaLocalUser'."
    }

    icacls $carpetaPublic /grant "Todos:(OI)(CI)RX" | Out-Null
    Write-Host "Carpetas base configuradas exitosamente."
}

function ConfigurarCarpetaServicios {
    Write-Host "Configurando carpetas de servicios en 'C:\ServidorFTP\LocalUser\Public'..."
    $carpetaPublic = "C:\ServidorFTP\LocalUser\Public"
    foreach ($servicio in @("nginx", "tomcat", "lighttpd")) {
        $rutaServicio = Join-Path $carpetaPublic $servicio
        if (-not (Test-Path $rutaServicio)) {
            New-Item -Path $rutaServicio -ItemType Directory -Force | Out-Null
            Write-Host "Carpeta '$servicio' creada en '$carpetaPublic'."
        } else {
            Write-Host "La carpeta '$servicio' ya existe en '$carpetaPublic'."
        }
        icacls $rutaServicio /grant "Todos:(OI)(CI)RX" | Out-Null
    }
    Write-Host "Carpetas de servicios configuradas exitosamente."
}

function ConfigurarAccesoAnonimoFTP {
    Write-Host "Configurando acceso anónimo en 'C:\ServidorFTP\LocalUser\Public'..."
    icacls "C:\ServidorFTP\LocalUser\Public" /grant "Todos:(OI)(CI)RX" | Out-Null
    Write-Host "Acceso anónimo configurado exitosamente."
}

function ConfigurarPermisosPublicFTP {
    Write-Host "Configurando permisos en la carpeta 'C:\ServidorFTP\LocalUser\Public'..."
    icacls "C:\ServidorFTP\LocalUser\Public" /grant "Todos:(OI)(CI)RX" | Out-Null
    Write-Host "Permisos configurados en 'Public' exitosamente."
}

function ConfigurarSSLFTP {
    Write-Host "=== Configuración de SSL (FTPS) ==="
    $sitename = "PruebaFTP"
    # Se configura SSL en IIS FTP
    Set-ItemProperty "IIS:\Sites\$sitename" -Name "ftpServer.security.ssl.controlChannelPolicy" -Value 0
    Set-ItemProperty "IIS:\Sites\$sitename" -Name "ftpServer.security.ssl.dataChannelPolicy" -Value 0
    Write-Host "SSL (FTPS) configurado exitosamente en el sitio $sitename."
    Restart-Service ftpsvc
    Restart-Service W3SVC
}

# --------------------------------------------
# Funciones de Gestión de Usuarios FTP
# --------------------------------------------

function CrearUsuarioFTP {
    Write-Host ""
    Write-Host "=== Crear Usuario FTP ==="
    $username = Read-Host "Ingrese el nombre de usuario"
    if ([string]::IsNullOrWhiteSpace($username)) {
        Write-Host "El nombre de usuario no puede estar vacío."
        return
    }
    $username = $username.ToLower()
    $password = Read-Host "Ingrese la contraseña" -AsSecureString
    Write-Host "Creando usuario local '$username'..."
    try {
        New-LocalUser -Name $username -Password $password -FullName $username -Description "Usuario FTP" -ErrorAction Stop
        Write-Host "Usuario '$username' creado exitosamente."
    } catch {
        Write-Host "Error al crear el usuario '$username'."
    }
}

function EliminarUsuarioFTP {
    Write-Host ""
    Write-Host "=== Eliminar Usuario FTP ==="
    $username = Read-Host "Ingrese el nombre de usuario a eliminar"
    if ([string]::IsNullOrWhiteSpace($username)) {
        Write-Host "El nombre de usuario no puede estar vacío."
        return
    }
    $username = $username.ToLower()
    try {
        Get-LocalUser -Name $username -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "El usuario '$username' no existe."
        return
    }
    Write-Host "Eliminando usuario '$username'..."
    try {
        Remove-LocalUser -Name $username -ErrorAction Stop
        Write-Host "Usuario '$username' eliminado exitosamente."
    } catch {
        Write-Host "Error al eliminar el usuario '$username'."
    }
}

function Login {
    do {
        $user = Read-Host "Ingresa el nombre de usuario"
        try {
            Get-LocalUser -Name $user -ErrorAction Stop | Out-Null
            $userExists = $true
        } catch {
            Write-Host "El usuario no existe, intente de nuevo." -ForegroundColor Red
            $userExists = $false
        }
    } while (-not $userExists)
    Clear-Host
    Write-Host "Elige una opción:"
    Write-Host "[1] Reasignar grupos a usuario"
    Write-Host "[2] Eliminar usuario"
    Write-Host "[Otro] Cancelar"
    $opc = Read-Host "Opción"
    switch ($opc) {
        '1' { ChangeGroup -user $user }
        '2' {
            Write-Host "Eliminando usuario $user..."
            Remove-LocalUser -Name $user -ErrorAction SilentlyContinue
        }
        default { Write-Host "Operación cancelada." }
    }
}

function Register {
    do {
        $ADSI = [ADSI]"WinNT://$env:ComputerName"
        $username = Read-Host "Ingrese su nombre de usuario"
        if ([string]::IsNullOrWhiteSpace($username) -or $username -match "\s") {
            Write-Host "El nombre no puede tener espacios ni estar vacío."
        }
    } while ([string]::IsNullOrWhiteSpace($username) -or $username -match "\s")

    do {
        $password = Read-Host "Ingrese una contraseña segura (al menos una mayúscula y un número)"
        $regex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\W_]).{8,}$"
        if ($password -notmatch $regex) {
            Write-Host "La contraseña no cumple con las políticas de seguridad, intente de nuevo."
        }
    } while ($password -notmatch $regex)
    
    Write-Host "¿A qué grupo(s) pertenece el usuario?"
    Write-Host "[1] Reprobados"
    Write-Host "[2] Recursadores"
    Write-Host "[Otro] Ninguno (solo el público)"
    $opc = Read-Host "Opción"

    $CreateUserFTPUser = $ADSI.Create("User", $username)
    $CreateUserFTPUser.SetPassword($password)
    $CreateUserFTPUser.SetInfo()

    $UserAccount = New-Object System.Security.Principal.NTAccount($username)
    $SID = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier])

    New-Item -Path "C:\ServidorFTP\LocalUser\$username" -ItemType Directory -Force | Out-Null
    icacls "C:\ServidorFTP\LocalUser\$username" /grant "$username:(OI)(CI)F" | Out-Null
    icacls "C:\ServidorFTP\LocalUser\Public" /grant "$username:(OI)(CI)F" | Out-Null
    New-Item -ItemType Junction -Path "C:\ServidorFTP\LocalUser\$username\Public" -Target "C:\ServidorFTP\LocalUser\Public" -Force | Out-Null
    icacls "C:\ServidorFTP\LocalUser\$username\Public" /grant "$username:(OI)(CI)F" | Out-Null
    New-Item -Path "C:\ServidorFTP\LocalUser\$username\$username" -ItemType Directory -Force | Out-Null
    icacls "C:\ServidorFTP\LocalUser\$username\$username" /grant "$username:(OI)(CI)F" | Out-Null

    switch ($opc) {
        '1' {
            $Group = [ADSI]"WinNT://$env:ComputerName/Reprobados,Group"
            $User = [ADSI]"WinNT://$SID"
            $Group.Add($User.Path)
            icacls "C:\ServidorFTP\Reprobados" /grant "$username:(OI)(CI)F" | Out-Null
            New-Item -ItemType Junction -Path "C:\ServidorFTP\LocalUser\$username\Reprobados" -Target "C:\ServidorFTP\Reprobados" -Force | Out-Null
            icacls "C:\ServidorFTP\LocalUser\$username\Reprobados" /grant "$username:(OI)(CI)F" | Out-Null
        }
        '2' {
            $Group = [ADSI]"WinNT://$env:ComputerName/Recursadores,Group"
            $User = [ADSI]"WinNT://$SID"
            $Group.Add($User.Path)
            icacls "C:\ServidorFTP\Recursadores" /grant "$username:(OI)(CI)F" | Out-Null
            New-Item -ItemType Junction -Path "C:\ServidorFTP\LocalUser\$username\Recursadores" -Target "C:\ServidorFTP\Recursadores" -Force | Out-Null
            icacls "C:\ServidorFTP\LocalUser\$username\Recursadores" /grant "$username:(OI)(CI)F" | Out-Null
        }
        default { Write-Host "No se asignaron grupos adicionales." }
    }
    Write-Host "Usuario $username creado y configurado."
}
