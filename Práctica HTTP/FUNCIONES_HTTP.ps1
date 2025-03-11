# Script para funciones de gestión de instalación de servicios HTTP en Windows Server
# Zapien Rivera Jesús Javier
# 302 IS

# --- Funciones de Validación y Comprobación de Puertos ---

function Validate-Port {
    param(
        [string]$Port
    )
    if ($Port -notmatch '^\d+$') {
        Write-Warning "Error: Introduzca un número válido para el puerto."
        return $false
    }
    if ([int]$Port -lt 1 -or [int]$Port -gt 65535) {
        Write-Warning "Error: El puerto debe estar entre 1 y 65535."
        return $false
    }
    return $true
}

function Test-PortInUse {
    param(
        [int]$Port
    )
    # Utiliza Get-NetTCPConnection para verificar si el puerto está en uso
    $inUse = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if ($inUse) { return $true }
    return $false
}

# --- Funciones para Obtener Versiones y Enlaces de Descarga ---

function Get-NginxVersions {
    Write-Host "Consultando página de descargas de NGINX..."
    try {
        $response = Invoke-WebRequest -Uri "https://nginx.org/en/download.html" -UseBasicParsing
    }
    catch {
        Write-Warning "No se pudo acceder a la página de NGINX."
        return @{ dev = "desconocido"; lts = "desconocido" }
    }
    $content = $response.Content

    # Extraer la versión de desarrollo (Mainline)
    $mainlineRegex = 'Mainline version.*?nginx-([\d\.]+)\.tar\.gz'
    $mainlineMatch = [regex]::Match($content, $mainlineRegex)
    # Extraer la versión estable (LTS)
    $stableRegex = 'Stable version.*?nginx-([\d\.]+)\.tar\.gz'
    $stableMatch = [regex]::Match($content, $stableRegex)

    if($mainlineMatch.Success -and $stableMatch.Success) {
       $nginxDevVersion = $mainlineMatch.Groups[1].Value
       $nginxLTSVersion = $stableMatch.Groups[1].Value
    } else {
       Write-Warning "No se pudieron obtener las versiones de NGINX de la página de descargas."
       $nginxDevVersion = "desconocido"
       $nginxLTSVersion = "desconocido"
    }
    Write-Host "NGINX - Opciones de Versión:"
    Write-Host "1. Desarrollo: $nginxDevVersion"
    Write-Host "2. LTS: $nginxLTSVersion"
    Write-Host "3. Cancelar"
    return @{ dev = $nginxDevVersion; lts = $nginxLTSVersion }
}

function Get-TomcatVersions {
    try {
        $response = Invoke-WebRequest -Uri "https://tomcat.apache.org/index.html" -UseBasicParsing
    }
    catch {
        Write-Warning "No se pudo acceder a la página de Tomcat."
        return @{ dev = "desconocido"; lts = "desconocido" }
    }
    
    $content = $response.Content
    $regex = '(?<=<h3 id="Tomcat_)\d+\.\d+\.\d+'
    $matches = [regex]::Matches($content, $regex)
    
    if ($matches.Count -ge 2) {
        # La primera coincidencia es la versión LTS (estable)
        $tomcatLTSVersion = $matches[0].Value
        # La última coincidencia es la versión de desarrollo
        $tomcatDevVersion = $matches[$matches.Count - 1].Value
    }
    else {
        Write-Warning "No se pudieron obtener las versiones de Tomcat de la página."
        $tomcatLTSVersion = "desconocido"
        $tomcatDevVersion = "desconocido"
    }
    
    Write-Host "Tomcat - Opciones de Versión:"
    Write-Host "1. Desarrollo: Tomcat $tomcatDevVersion"
    Write-Host "2. LTS (Estable): Tomcat $tomcatLTSVersion"
    Write-Host "3. Cancelar"
    
    return @{ dev = $tomcatDevVersion; lts = $tomcatLTSVersion }
}


function Get-IISVersions {
    # Para IIS usaremos versiones predefinidas
    $iisDevVersion = "10.0 Preview"
    $iisLTSVersion = "10.0"
    Write-Host "IIS - Opciones de Versión:"
    Write-Host "1. Desarrollo (Preview): $iisDevVersion"
    Write-Host "2. LTS (Estable): $iisLTSVersion"
    Write-Host "3. Cancelar"
    return @{ dev = $iisDevVersion; lts = $iisLTSVersion }
}

# --- Funciones de Instalación/Configuración de Servicios ---

function Install-Nginx {
    param(
        [string]$Port,
        [string]$VersionOption,  
        [hashtable]$Versions
    )

    if ($VersionOption -eq "1") {
        $selectedVersion = $Versions.dev
        $versionType = "Desarrollo (Mainline)"
    }
    elseif ($VersionOption -eq "2") {
        $selectedVersion = $Versions.lts
        $versionType = "LTS (Estable)"
    }
    else {
        Write-Warning "Opción de versión no válida para NGINX."
        return
    }

    $downloadLink = "https://nginx.org/download/nginx-$selectedVersion.zip"
    Write-Host "`n=== Instalando NGINX $versionType, Versión $selectedVersion en el puerto $Port ==="
    Write-Host "Descargando NGINX desde: $downloadLink"

    $nginxZip = "C:\nginx-$selectedVersion.zip"
    $nginxPath = "C:\nginx"

    # Descargar NGINX
    Invoke-WebRequest -Uri $downloadLink -OutFile $nginxZip

    # Verificar si la carpeta nginx ya existe y eliminarla
    if (Test-Path $nginxPath) {
        Remove-Item -Recurse -Force $nginxPath
    }

    Expand-Archive -Path $nginxZip -DestinationPath "C:\" -Force
    Rename-Item -Path "C:\nginx-$selectedVersion" -NewName "nginx"

    $configFile = "$nginxPath\conf\nginx.conf"

    # Modificar el puerto en nginx.conf
    (Get-Content $configFile) -replace "listen\s+80;", "listen $Port;" | Set-Content $configFile
    
    # Verificar si el servicio ya existe antes de crearlo
    if (Get-Service -Name "nginx" -ErrorAction SilentlyContinue) {
        Write-Host "El servicio NGINX ya existe. No es necesario crearlo."
    } else {
        sc.exe create nginx binPath= "$nginxPath\nginx.exe" start= auto
    }

    Start-Process C:\nginx\nginx.exe
    Get-Process -Name nginx
}


function Install-Tomcat {
    param(
        [string]$Port,
        [string]$VersionOption,
        [hashtable]$Versions
    )

    if ($VersionOption -eq "1") {
        $selectedVersion = $Versions.dev
        $versionType = "Desarrollo"
    }
    elseif ($VersionOption -eq "2") {
        $selectedVersion = $Versions.lts
        $versionType = "LTS (Estable)"
    }
    else {
        Write-Warning "Opción de versión no válida para Tomcat."
        return
    }

    $bercion = $selectedVersion.Split('.')[0]
    
    $downloadLink = "https://dlcdn.apache.org/tomcat/tomcat-$bercion/v$selectedVersion/bin/apache-tomcat-$selectedVersion-windows-x64.zip"
    $tomcatZip = "C:\tomcat-$selectedVersion.zip"
    $tomcatPath = "C:\tomcat"

    Write-Host "`n=== Instalando Tomcat $versionType, Versión $selectedVersion en el puerto $Port ==="
    Write-Host "Descargando Tomcat desde: $downloadLink"

    # Descargar Tomcat
    Invoke-WebRequest -Uri $downloadLink -OutFile $tomcatZip

    # Verificar si la carpeta Tomcat ya existe y eliminarla
    if (Test-Path $tomcatPath) {
        Remove-Item -Recurse -Force $tomcatPath
    }

    Expand-Archive -Path $tomcatZip -DestinationPath "C:\" -Force
    Rename-Item -Path "C:\apache-tomcat-$selectedVersion" -NewName "tomcat"

    # Configurar puerto en server.xml
    $configFile = "$tomcatPath\conf\server.xml"
    if (Test-Path $configFile) {
        (Get-Content $configFile) -replace 'port="8080"', "port=`"$Port`"" | Set-Content $configFile
    } else {
        Write-Warning "No se encontró el archivo server.xml. La configuración del puerto no se aplicó."
    }
   

    # Verificar si el servicio se creó correctamente
    $service = Get-Service | Where-Object { $_.Name -match "Tomcat" }

    if ($service) {
        Start-Process -FilePath "$tomcatPath\bin\startup.bat" -NoNewWindow -Wait
    }

    Write-Host "Tomcat $versionType instalado y configurado exitosamente en el puerto $Port." -ForegroundColor Green
}


function Install-IIS {
    param(
        [string]$Port,
        [string]$VersionOption,  # "1" para Desarrollo, "2" para LTS
        [hashtable]$Versions
    )

    if ($VersionOption -eq "1") {
        $selectedVersion = $Versions.dev
        $versionType = "Desarrollo (Preview)"
    }
    elseif ($VersionOption -eq "2") {
        $selectedVersion = $Versions.lts
        $versionType = "LTS (Estable)"
    }
    else {
        Write-Warning "Opción de versión no válida para IIS."
        return
    }
    Write-Host ""
    Write-Host "=== Configurando IIS $versionType, Versión $selectedVersion para usar el puerto $Port ==="
    Write-Host "Configurando sitio web predeterminado de IIS..."
    Import-Module WebAdministration
    try {
        $site = Get-Website -Name "Default Web Site"
        if ($site) {
            # Ejemplo: se modifica la vinculación para cambiar el puerto
            Set-WebBinding -Name "Default Web Site" -BindingInformation "*:80:" -PropertyName port -Value $Port
        }
        else {
            Write-Warning "No se encontró el sitio 'Default Web Site'."
        }
    }
    catch {
        Write-Error "Error al configurar IIS: $_"
    }
}

# --- Función Genérica para la Instalación/Configuración de un Servicio HTTP ---

function Install-HTTPService {
    param(
        [string]$Service
    )

    switch ($Service.ToLower()) {
        "nginx" {
            $versions = Get-NginxVersions
            do {
                $versionOption = Read-Host "Seleccione la versión de NGINX a instalar (1-Desarrollo, 2-LTS, 3-Cancelar)"
                if ($versionOption -eq "3") {
                    Write-Host "Instalación de NGINX cancelada."
                    return
                }
            } until ($versionOption -eq "1" -or $versionOption -eq "2")
        }
        "tomcat" {
            $versions = Get-TomcatVersions
            do {
                $versionOption = Read-Host "Seleccione la versión de Tomcat a instalar (1-Desarrollo, 2-LTS, 3-Cancelar)"
                if ($versionOption -eq "3") {
                    Write-Host "Instalación de Tomcat cancelada."
                    return
                }
            } until ($versionOption -eq "1" -or $versionOption -eq "2")
        }
        "iis" {
            $versions = Get-IISVersions
            do {
                $versionOption = Read-Host "Seleccione la versión de IIS a configurar (1-Desarrollo, 2-LTS, 3-Cancelar)"
                if ($versionOption -eq "3") {
                    Write-Host "Configuración de IIS cancelada."
                    return
                }
            } until ($versionOption -eq "1" -or $versionOption -eq "2")
        }
        default {
            Write-Warning "Servicio HTTP no reconocido. Use 'nginx', 'tomcat' o 'iis'."
            return
        }
    }

    # Solicitar el puerto a utilizar
    do {
        $portInput = Read-Host "Ingrese el puerto para $Service"
    } until (Validate-Port $portInput)
    $portNumber = [int]$portInput
    if (Test-PortInUse -Port $port) {
        Write-Warning "El puerto $portInput está en uso. Por favor, elija otro puerto."
        return
    }

    switch ($Service.ToLower()) {
        "nginx" { Install-Nginx -Port $portInput -VersionOption $versionOption -Versions $versions }
        "tomcat" { Install-Tomcat -Port $portInput -VersionOption $versionOption -Versions $versions }
        "iis"    { Install-IIS -Port $portInput -VersionOption $versionOption -Versions $versions }
    }
}
