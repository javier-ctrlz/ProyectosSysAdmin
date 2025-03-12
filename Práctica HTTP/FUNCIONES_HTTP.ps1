# Script para funciones de gestión de instalación de servicios HTTP en Windows Server
# Zapien Rivera Jesús Javier
# 302 IS

# --- Funciones de Validación y Comprobación de Puertos ---

function Validate-Port {
    param(
        [string]$Port
    )

    $unsafePorts = @(1, 7, 9, 11, 13, 17, 19, 20, 21, 22, 23, 25, 37, 42, 53, 69, 77, 79, 87, 95, 101, 102, 103, 104, 109, 110, 111, 113, 115, 117, 119, 123, 135, 137, 138, 139, 143, 161, 162, 171, 179, 194, 389, 427, 465, 512, 513, 514, 515, 526, 530, 531, 532, 540, 548, 554, 556, 563, 587, 601, 636, 993, 995, 2049, 3659, 4045, 6000, 6001, 6002, 6003, 6004, 6005, 6006, 6007, 6008, 6009, 6010, 6011, 6012, 6013, 6014, 6015, 6016, 6017, 6018, 6019, 6020, 6021, 6022, 6023, 6024, 6025, 6026, 6027, 6028, 6029, 6030, 6031, 6032, 6033, 6034, 6035, 6036, 6037, 6038, 6039, 6040, 6041, 6042, 6043, 6044, 6045, 6046, 6047, 6048, 6049, 6050, 6051, 6052, 6053, 6054, 6055, 6056, 6057, 6058, 6059, 6060, 6061, 6062, 6063, 6665, 6666, 6667, 6668, 6669)

    if ($Port -notmatch '^\d+$') {
        Write-Warning "Error: Introduzca un número válido para el puerto."
        return $false
    }
    if ([int]$Port -lt 1 -or [int]$Port -gt 65535) {
        Write-Warning "Error: El puerto debe estar entre 1 y 65535."
        return $false
    }
    if ($unsafePorts -contains [int]$Port) {
        Write-Warning "Error: El puerto $Port está bloqueado por seguridad en navegadores. Elija otro."
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
    
    if(Get-Process -Name nginx){
        Stop-Process -Name nginx -Force
    }
    
    sc.exe delete nginx -SilentlyContinue
    
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

    # Descargar NGINX
    Invoke-WebRequest -Uri $downloadLink -OutFile $nginxZip

    Expand-Archive -Path $nginxZip -DestinationPath "C:\nginx" -Force

    cd C:\nginx\nginx-$selectedVersion

    $configFile = "C:\nginx\nginx-$selectedVersion\conf\nginx.conf"

    # Modificar el puerto en nginx.conf
    (Get-Content $configFile) -replace "listen\s+80;", "listen $Port;" | Set-Content $configFile

    Start-Process "C:\nginx\nginx-$selectedVersion\nginx.exe"
    Get-Process -Name nginx
    cd C:\Users\Administrador
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

    if(Get-Process -Name tomcat$bercion){
        Stop-Process -Name tomcat$bercion -Force
    }
    
    sc.exe delete tomcat$bercion -SilentlyContinue

    $downloadLink = "https://dlcdn.apache.org/tomcat/tomcat-$bercion/v$selectedVersion/bin/apache-tomcat-$selectedVersion-windows-x64.zip"
    $tomcatZip = "C:\tomcat-$selectedVersion.zip"

    Write-Host "`n=== Instalando Tomcat $versionType, Versión $selectedVersion en el puerto $Port ==="
    Write-Host "Descargando Tomcat desde: $downloadLink"

    # Descargar Tomcat
    Invoke-WebRequest -Uri $downloadLink -OutFile $tomcatZip

    Expand-Archive -Path $tomcatZip -DestinationPath "C:\tomcat" -Force

    # Configurar puerto en server.xml
    $configFile = "C:\tomcat\apache-tomcat-$selectedVersion\conf\server.xml"

    (Get-Content $configFile) -replace 'port="8080"', "port=`"$Port`"" | Set-Content $configFile
    
    cd C:\tomcat\apache-tomcat-$selectedVersion\bin\
        
    #Start-Process "C:\tomcat\apache-tomcat-$selectedVersion\bin\startup.bat"
    
    
    .\service.bat install tomcat$bercion
    Start-Service -Name tomcat$bercion
    Get-Process -Name tomcat$bercion
    Write-Host "Tomcat $versionType instalado y configurado exitosamente en el puerto $Port." -ForegroundColor Green
    cd C:\Users\Administrador
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
    Write-Host "Actualizando puerto HTTP del sitio 'Default Web Site'..."
    Import-Module WebAdministration

    try {
        $site = Get-Website -Name "Default Web Site" -ErrorAction SilentlyContinue
        if (-not $site) {
            Write-Warning "No se encontró el sitio 'Default Web Site'."
            return
        }

        # Filtrar únicamente las vinculaciones HTTP
        $httpBindings = Get-WebBinding -Name "Default Web Site" | Where-Object { $_.protocol -eq "http" }

        if ($httpBindings -and $httpBindings.Count -gt 0) {
            foreach ($binding in $httpBindings) {
                # El formato es "IP:Puerto:HostHeader"
                $parts = $binding.bindingInformation.Split(":")
                if ($parts.Length -ge 3) {
                    $ip = $parts[0]
                    $oldPort = $parts[1]
                    $hostHeader = $parts[2]
                    # Eliminar la vinculación existente
                    Remove-WebBinding -Name "Default Web Site" -Protocol "http" -IPAddress $ip -Port $oldPort -HostHeader $hostHeader -Confirm:$false
                    # Crear una nueva vinculación con el puerto actualizado
                    New-WebBinding -Name "Default Web Site" -Protocol "http" -IPAddress $ip -Port $Port -HostHeader $hostHeader -ErrorAction Stop
                    Write-Host "Se actualizó la vinculación HTTP de '$($ip):$($oldPort):$($hostHeader)' a '$($ip):$($Port):$($hostHeader)'." -ForegroundColor Green
                }
            }
        }
        else {
            Write-Warning "No se encontró ninguna vinculación HTTP en 'Default Web Site'. Creando una nueva vinculación..."
            New-WebBinding -Name "Default Web Site" -Protocol "http" -IPAddress "*" -Port $Port -HostHeader "" -ErrorAction Stop
            Write-Host "Nueva vinculación HTTP creada: *:${Port}:" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Error al actualizar el puerto HTTP de 'Default Web Site': $_"
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
    
    if (Test-PortInUse -Port $portNumber) {
        Write-Warning "El puerto $portInput está en uso. Por favor, elija otro puerto."
        return
    }

    switch ($Service.ToLower()) {
        "nginx" { Install-Nginx -Port $portInput -VersionOption $versionOption -Versions $versions }
        "tomcat" { Install-Tomcat -Port $portInput -VersionOption $versionOption -Versions $versions }
        "iis"    { Install-IIS -Port $portInput -VersionOption $versionOption -Versions $versions }
    }
}
