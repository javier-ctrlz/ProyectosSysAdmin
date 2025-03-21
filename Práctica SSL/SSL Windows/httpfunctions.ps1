# ----------------------------------------------------------------
# Variable base para el FTP
# ----------------------------------------------------------------
$ftpbase = "ftp://192.168.100.87"  # IP del servidor FTP

# ----------------------------------------------------------------
# Función: Comprobarpuerto
# Descripción: Valida si el puerto introducido está dentro del rango permitido
#              y no se encuentra en una lista de puertos reservados ni en uso.
# Parámetros:
#   - $newPort: Puerto a comprobar (tipo [int]).
# ----------------------------------------------------------------
function Comprobarpuerto {
    param (
        [int]$newPort
    )
    
    # Lista de puertos inválidos
    $puertosinvalidos = (1,7,9,11,13,17,19,20,21,22,23,25,37,42,53,69,77,79,87,95,101,102,103,104,109,110,111,113,115,117,119,123,135,
                         137,138,139,143,161,162,171,179,194,389,427,465,512,513,514,515,526,530,531,532,540,548,554,556,563,587,601,
                         636,993,995,2049,3659,4045,6000)
    
    # Obtener salida de netstat para el puerto especificado
    $netstatoutput = netstat -ano | Select-String ":$newPort "

    if ($newPort -gt 1 -and $newPort -lt 65535 -and $puertosinvalidos -notcontains $newPort) {
        if ($netstatoutput) {
            Write-Host "El puerto está en uso" -ForegroundColor Red
            return $false
        } else {
            Write-Host "Puerto válido, se procederá a la instalación." -ForegroundColor Green
            return $true
        }
    } else {
        Write-Host "Puerto introducido inválido. Los puertos válidos están entre 1024 y 65535." -ForegroundColor Red
        return $false
    }
}

# ----------------------------------------------------------------
# Función: CompileCaddy
# Descripción: Descomprime el paquete de Caddy, crea la estructura de carpetas
#              y archivos iniciales, configura la sección SSL (opcional) y
#              arranca el servicio.
# ----------------------------------------------------------------
function CompileCaddy {
    # Cambiar al directorio de Caddy
    cd C:\caddy
    Expand-Archive -Path "caddy.zip" -DestinationPath C:\caddy
    New-Item -Path "C:\caddy\www\" -ItemType "Directory" -Force

    # Crear archivo HTML de bienvenida
    $HTMLcontent = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Lighttpd</title>
    <style>
        body {
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            height: 100vh;
            text-align: center;
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
        }
        img {
            width: 200px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>Ejecutando Caddy</h1>
    <img src="https://imgs.search.brave.com/LCNbcmrEbHMXD2POkg_Bu-cm6N-d3kEP5XGVuOpT_oA/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly91c2Vy/LWltYWdlcy5naXRo/dWJ1c2VyY29udGVu/dC5jb20vMTEyODg0/OS8yMTAxODczNTYt/ZGZiN2YxYzUtYWMy/ZS00M2FhLWJiMjMt/ZmMwMTQyODBhZTFm/LnN2Zw">
</body>
</html>
"@
    $HTMLcontent | Out-File -Encoding utf8 -FilePath "C:\caddy\www\index.html" -Force

    # Crear el Caddyfile con la configuración inicial
    $CaddyfileContent = @"
:$newPort {
    root * C:/caddy/www/
    file_server
}
"@
    $CaddyfileContent | Out-File -Encoding utf8 -FilePath "C:\caddy\Caddyfile" -Force

    # Formatear el Caddyfile
    & "C:\caddy\caddy.exe" fmt --overwrite

    # Preguntar al usuario si desea configurar SSL para Caddy
    $running = $true
    while ($running) {
        Write-Host "¿Desea configurar SSL para Caddy? [S/N]"
        $opc = Read-Host "Opción"
        if ($opc.ToLower() -eq "s" -or $opc.ToLower() -eq "si") {
            ConfigsslCaddy  # Llama a la función de configuración SSL para Caddy
            $running = $false
        } elseif ($opc.ToLower() -eq "n" -or $opc.ToLower() -eq "no") {
            $running = $false
        } else {
            Write-Host "Opción inválida." -ForegroundColor Red
        }
    }

    Write-Host "Iniciando Servicio Caddy..."
    Start-Process -FilePath "C:\caddy\caddy.exe" -ArgumentList "run" -PassThru -WindowStyle Hidden
    Write-Host "Servicio Caddy iniciado." -ForegroundColor Green
}

# ----------------------------------------------------------------
# Función: DownloadCaddyFTP
# Descripción: Descarga el paquete de Caddy desde el servidor FTP y luego
#              llama a CompileCaddy para descomprimir e iniciar el servicio.
# ----------------------------------------------------------------
function DownloadCaddyFTP {
    Write-Host "Descargando archivos desde FTP..."
    $ftp = "$ftpbase/Caddy/$version"  # Directorio en el FTP
    $destino = "C:\caddy\caddy.zip"

    $request = [System.Net.FtpWebRequest]::Create($ftp)
    $request.Method = [System.Net.WebRequestMethods+FTP]::DownloadFile
    $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com")
    $request.EnableSsl = $true
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }

    try {
        $response = $request.GetResponse()
        $stream = $response.GetResponseStream()
        $fileStream = New-Object System.IO.FileStream $destino, "Create"
        $buffer = New-Object byte[] 1024
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $read)
        }
        $fileStream.Close()
        $stream.Close()
        $response.Close()
        Write-Host "Archivo descargado correctamente." -ForegroundColor Green
        CompileCaddy
    } catch {
        Write-Host "Error al descargar el archivo: $_" -ForegroundColor Red
    }
}

# ----------------------------------------------------------------
# Función: DownloadCaddyweb
# Descripción: Descarga el paquete de Caddy desde la web (GitHub) y luego
#              llama a CompileCaddy para descomprimir e iniciar el servicio.
# ----------------------------------------------------------------
function DownloadCaddyweb {
    # Eliminar la 'v' inicial en la versión, si la hubiera
    $version = $version -replace "^v", ""
    $Url = "https://github.com/caddyserver/caddy/releases/download/v$version/caddy_$version_windows_amd64.zip"
    $OutputPath = "C:\caddy\caddy.zip"
    Write-Host "Descargando Caddy desde: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $OutputPath
    CompileCaddy
}

# ----------------------------------------------------------------
# Función: InstallCady
# Descripción: Permite seleccionar la fuente de descarga (web o FTP) para Caddy.
# Parámetros:
#   - $ftp: Booleano que indica si la descarga se realizará desde FTP.
# ----------------------------------------------------------------
function InstallCady {
    param (
        [bool]$ftp
    )
    if ($ftp -eq $false) {
        Write-Host "Seleccione la fuente de descarga para Caddy:"
        Write-Host "[1] Web"
        Write-Host "[2] FTP"
        Write-Host "[3] Salir"
        $opc = Read-Host "Opción"
    } else {
        $opc = '2'
    }
    
    switch ($opc) {
        '1' {
            Write-Host "Obteniendo versiones de Caddy desde la web..."
            # Habilitar TLS12 y obtener versiones mediante la API de GitHub
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
            $versions = Invoke-RestMethod -Uri "https://api.github.com/repos/caddyserver/caddy/releases" | ForEach-Object { $_.tag_name }
            $version_lts = $versions | Where-Object { $_ -notmatch "beta" } | Select-Object -First 1
            $version_dev = $versions | Where-Object { $_ -match "beta" } | Select-Object -First 1

            if ($version_lts -eq "") {
                Write-Host "Problema al obtener las versiones. Compruebe su conexión a internet." -ForegroundColor Red
            } else {
                Write-Host "Última versión estable: $version_lts"
                Write-Host "Última versión en desarrollo: $version_dev"
                Write-Host "Seleccione la versión a instalar:"
                Write-Host "[1] $version_lts"
                Write-Host "[2] $version_dev"
                Write-Host "[3] Salir"
                $opc = Read-Host "Opción"
                switch ($opc) {
                    '1' {
                        $version = $version_lts
                        DownloadCaddyweb
                    }
                    '2' {
                        $version = $version_dev
                        DownloadCaddyweb
                    }
                    '3' {
                        Write-Host "Saliendo..."
                    }
                    default {
                        Write-Host "Opción inválida, volviendo al menú principal." -ForegroundColor Red
                    }
                }
            }
            cd C:\Users\Administrador
        }
        '2' {
            Write-Host "Obteniendo versiones disponibles en el servidor FTP para Caddy..."
            $ftpPath = "$ftpbase/Caddy"
            $request = [System.Net.FtpWebRequest]::Create($ftpPath)
            $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory
            $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com")
            $request.EnableSsl = $true
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
            try {
                $response = $request.GetResponse()
                $reader = New-Object System.IO.StreamReader $response.GetResponseStream()
                $directories = $reader.ReadToEnd()
                $reader.Close()
                $response.Close()
                $directories -split "`n"
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Write-Host "Seleccione la versión a descargar:"
            Write-Host "[1] Versión Oficial"
            Write-Host "[2] Versión Beta"
            Write-Host "[3] Salir"
            $opc = Read-Host "Opción:"
            switch ($opc) {
                '1' {
                    $version = "caddy2.9.1.zip"
                    DownloadCaddyFTP
                }
                '2' {
                    $version = "caddy2.10.0-beta.2.zip"
                    DownloadCaddyFTP
                }
                '3' {
                    Write-Host "Saliendo..."
                }
                default {
                    Write-Host "Opción inválida, volviendo al menú principal." -ForegroundColor Red
                }
            }
        }
        default {
            Write-Host "Volviendo al menú principal."
        }
    }
}

# ----------------------------------------------------------------
# Función: compilenginx
# Descripción: Descomprime el paquete de Nginx, actualiza el archivo de
#              configuración cambiando el puerto, pregunta por la configuración
#              SSL y arranca el servicio.
# ----------------------------------------------------------------
function compilenginx {
    cd C:\nginx
    $version = $version -replace '\.$',''
    Write-Host "Ejecutable de Nginx: C:\nginx\nginx-$version\nginx.exe"

    Expand-Archive -Path "nginx.zip" -DestinationPath C:\nginx -Force
    cd "C:\nginx\nginx-$version\"

    $nginxconfig = "C:\nginx\nginx-$version\conf\nginx.conf"
    $configcontent = Get-Content $nginxconfig

    # Actualizar la directiva del puerto en la configuración
    $configcontent = $configcontent -replace 'listen\s+80;', "listen $newPort;"
    Set-Content -Path $nginxconfig -Value $configcontent

    # Preguntar si se desea configurar SSL para Nginx
    $running = $true
    while ($running) {
        Write-Host "¿Desea configurar SSL para Nginx? [S/N]"
        $opc = Read-Host "Opción"
        if ($opc.ToLower() -eq "s" -or $opc.ToLower() -eq "si") {
            ConfigsslNginx
            $running = $false
        } elseif ($opc.ToLower() -eq "n" -or $opc.ToLower() -eq "no") {
            $running = $false
        } else {
            Write-Host "Opción inválida." -ForegroundColor Red
        }
    }
    
    # Iniciar Nginx de forma oculta
    Start-Process -FilePath ("C:\nginx\nginx-" + $version + "\nginx.exe") -WindowStyle Hidden
    cd C:\Users\Administrador
}

# ----------------------------------------------------------------
# Función: DownloadNginxftp
# Descripción: Descarga el paquete de Nginx desde el servidor FTP y llama a
#              compilenginx para la configuración e inicio del servicio.
# ----------------------------------------------------------------
function DownloadNginxftp {
    Write-Host "Descargando archivos de Nginx desde FTP..."
    $ftp = "$ftpbase/Nginx/$bersion"
    $destino = "C:\nginx\nginx.zip"

    $request = [System.Net.FtpWebRequest]::Create($ftp)
    $request.Method = [System.Net.WebRequestMethods+FTP]::DownloadFile
    $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com")
    $request.EnableSsl = $true
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
        
    try {
        $response = $request.GetResponse()
        $stream = $response.GetResponseStream()
        $fileStream = New-Object System.IO.FileStream $destino, "Create"
        $buffer = New-Object byte[] 1024
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $read)
        }
        $fileStream.Close()
        $stream.Close()
        $response.Close()
        Write-Host "Archivo descargado correctamente." -ForegroundColor Green
        compilenginx
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# ----------------------------------------------------------------
# Función: DownloadNginxweb
# Descripción: Descarga el paquete de Nginx desde la web y llama a
#              compilenginx para la configuración e inicio del servicio.
# ----------------------------------------------------------------
function DownloadNginxweb {
    $Url = "https://nginx.org/download/nginx-$version.zip"
    $OutputPath = "C:\nginx\nginx.zip"
    Write-Host "Descargando Nginx desde: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $OutputPath
    compilenginx
}

# ----------------------------------------------------------------
# Función: InstallNginx
# Descripción: Permite seleccionar la fuente de descarga (web o FTP) para Nginx.
# Parámetros:
#   - $ftp: Booleano que indica si la descarga se realizará desde FTP.
# ----------------------------------------------------------------
function InstallNginx {
    param (
        [bool]$ftp
    )
    if ($ftp -eq $false) {
        Write-Host "Seleccione la fuente de descarga para Nginx:"
        Write-Host "[1] Web"
        Write-Host "[2] FTP"
        Write-Host "[3] Salir"
        $opc = Read-Host "Opción"
    } else {
        $opc = '2'
    }

    switch ($opc) {
        '1' {
            Write-Host "Obteniendo versiones de Nginx desde la web..."
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
            $UrlContent = (Invoke-WebRequest -Uri "https://nginx.org/en/download.html").Content
            if ($UrlContent -match "Mainline version.*?nginx-([\d.]+)") {
                $version_dev = $Matches[1]
            }
            if ($UrlContent -match "Stable version.*?nginx-([\d.]+)") {
                $version_lts = $Matches[1]
            }
            Write-Host "Última versión estable: $version_lts"
            Write-Host "Última versión en desarrollo: $version_dev"
            Write-Host "Seleccione la versión a instalar:"
            Write-Host "[1] $version_lts"
            Write-Host "[2] $version_dev"
            Write-Host "[Otro] Salir"
            $opc = Read-Host "Opción"
            switch ($opc) {
                '1' {
                    $version = $version_lts
                    DownloadNginxweb
                }
                '2' {
                    $version = $version_dev
                    DownloadNginxweb
                }
                '3' {
                    Write-Host "Saliendo..."
                }
                default {
                    Write-Host "Opción inválida, volviendo al menú principal." -ForegroundColor Red
                }
            }
        }
        '2' {
            Write-Host "Obteniendo versiones disponibles en el servidor FTP para Nginx..."
            $ftpPath = "$ftpbase/Nginx"
            $request = [System.Net.FtpWebRequest]::Create($ftpPath)
            $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory
            $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com")
            $request.EnableSsl = $true
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
            try {
                $response = $request.GetResponse()
                $reader = New-Object System.IO.StreamReader $response.GetResponseStream()
                $directories = $reader.ReadToEnd() -split "`n"
                $reader.Close()
                $response.Close()
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Write-Host "Seleccione la versión a descargar:"
            Write-Host "[1] Versión Oficial"
            Write-Host "[2] Versión Beta"
            Write-Host "[3] Salir"
            $opc = Read-Host "Opción:"
            switch ($opc) {
                '1' {
                    $bersion = "nginx.zip"
                    $version = "1.26.3"  # Ajusta la versión según corresponda
                    DownloadNginxftp
                }
                '2' {
                    $bersion = "nginx_beta.zip"
                    $version = "1.27.4"  # Ajusta la versión según corresponda
                    DownloadNginxftp
                }
                '3' {
                    Write-Host "Saliendo..."
                }
                default {
                    Write-Host "Opción inválida, volviendo al menú principal." -ForegroundColor Red
                }
            }
        }
        default {
            Write-Host "Volviendo al menú principal."
        }
    }
    cd C:\Users\Administrador
}

# ----------------------------------------------------------------
# Función: descargararchivo
# Descripción: Descarga un archivo específico desde la carpeta "Otros" del FTP.
# Parámetros:
#   - $archivo: Nombre del archivo a descargar.
# ----------------------------------------------------------------
function descargararchivo {
    param (
        $archivo
    )
    Write-Host "Descargando archivo: $archivo"
    $ftp = "$ftpbase/Otros/$archivo"
    $destino = "C:\ssl\$archivo"

    $request = [System.Net.FtpWebRequest]::Create($ftp)
    $request.Method = [System.Net.WebRequestMethods+FTP]::DownloadFile
    $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com")
    $request.EnableSsl = $true
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
        
    try {
        $response = $request.GetResponse()
        $stream = $response.GetResponseStream()
        $fileStream = New-Object System.IO.FileStream $destino, "Create"
        $buffer = New-Object byte[] 1024
        while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $read)
        }
        $fileStream.Close()
        $stream.Close()
        $response.Close()
        Write-Host "Archivo descargado correctamente." -ForegroundColor Green
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# ----------------------------------------------------------------
# Función: otrasdescargas
# Descripción: Muestra los archivos disponibles en la carpeta "Otros" del FTP
#              y permite al usuario seleccionar uno para descargar.
# ----------------------------------------------------------------
function otrasdescargas {
    Write-Host "Archivos disponibles en 'Otros':"
    $ftp = "$ftpbase/Otros"
    $request = [System.Net.FtpWebRequest]::Create($ftp)
    $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory
    $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com")
    $request.EnableSsl = $true
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
    try {
        $response = $request.GetResponse()
        $reader = New-Object System.IO.StreamReader $response.GetResponseStream()
        $directories = $reader.ReadToEnd() -split "`r?`n"
        $reader.Close()
        $response.Close()
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }

    $running = $true
    while ($running) {
        Write-Host "Seleccione el archivo a descargar:"
        for ($i = 0; $i -lt $directories.Length - 1; $i++) {
            Write-Host "[$($i + 1)] $($directories[$i])"
        }
        Write-Host "[$($directories.Length)] Salir"
        $opc = Read-Host "Opción (1-$($directories.Length)):"
        
        if ($opc -eq $directories.Length) {
            Write-Host "Saliendo..."
            $running = $false
        } elseif ($opc -match "^\d+$" -and [int]$opc -le $directories.Length) {
            $archivoSeleccionado = $directories[[int]$opc - 1]
            Write-Host "Archivo seleccionado: $archivoSeleccionado"
            descargararchivo -archivo $archivoSeleccionado
            $running = $false
        } else {
            Write-Host "Opción inválida, intente de nuevo." -ForegroundColor Red
        }
    }
}

# ----------------------------------------------------------------
# Función: elegirserviciosweb
# Descripción: Permite al usuario elegir el servicio web a instalar (Caddy o Nginx)
#              y valida el puerto asignado.
# ----------------------------------------------------------------
function elegirserviciosweb {
    $puertovalido = $false
    Write-Host "Instalar servicio HTTP:"
    Write-Host "[1] Caddy"
    Write-Host "[2] Nginx"
    Write-Host "[3] Salir"
    $opc = Read-Host "Opción"
    switch ($opc) {
        '1' {
            if (Test-Path "C:\caddy\caddy.exe") {
                Write-Host "Caddy ya está instalado en el equipo." -ForegroundColor Yellow
            } else {
                while (-not $puertovalido) {
                    $newPort = Read-Host "Introduce el puerto donde correrá el servicio"
                    if (Comprobarpuerto -newPort $newPort) {
                        $puertovalido = $true
                        Write-Host "Puerto válido, se procederá a la instalación." -ForegroundColor Green
                    } else {
                        $puertovalido = $false
                        Write-Host "Puerto inválido o en uso, ingrese otro dato." -ForegroundColor Red
                    }
                }
                InstallCady -ftp $false
            }
        }
        '2' {
            if (Test-Path "C:\nginx\nginx-*\nginx.exe") {
                Write-Host "Nginx ya está instalado en el equipo." -ForegroundColor Yellow
            } else {
                while (-not $puertovalido) {
                    $newPort = Read-Host "Introduce el puerto donde correrá el servicio"
                    if (Comprobarpuerto -newPort $newPort) {
                        $puertovalido = $true
                        Write-Host "Puerto válido, se procederá a la instalación." -ForegroundColor Green
                    } else {
                        $puertovalido = $false
                        Write-Host "Puerto inválido o en uso, ingrese otro dato." -ForegroundColor Red
                    }
                }
                InstallNginx -ftp $false
            }
        }
        '3' {
            Write-Host "Saliendo del menú de servicios web."
        }
        default {
            Write-Host "Opción inválida." -ForegroundColor Red
        }
    }
}

# ----------------------------------------------------------------
# Función: elegirserviciosftp
# Descripción: Muestra las opciones disponibles en el servidor FTP para
#              descargar e instalar servicios (Caddy, Nginx u otros).
# ----------------------------------------------------------------
function elegirserviciosftp {
    Write-Host "Opciones disponibles en el FTP:"
    $ftp = "$ftpbase/"
    $request = [System.Net.FtpWebRequest]::Create($ftp)
    $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectory
    $request.Credentials = New-Object System.Net.NetworkCredential("anonymous", "anonymous@example.com")
    $request.EnableSsl = $true
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }
        
    try {
        $response = $request.GetResponse()
        $reader = New-Object System.IO.StreamReader $response.GetResponseStream()
        $directories = $reader.ReadToEnd() -split "`n"
        $reader.Close()
        $response.Close()
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }

    Write-Host "¿Qué desea descargar?"
    Write-Host "[1] Caddy"
    Write-Host "[2] Nginx"
    Write-Host "[3] Otros"
    $opc = Read-Host "Opción:"
    switch ($opc) {
        '1' {
            if (Test-Path "C:\caddy\caddy.exe") {
                Write-Host "Caddy ya está instalado en el equipo." -ForegroundColor Yellow
            } else {
                $puertovalido = $false
                while (-not $puertovalido) {
                    $newPort = Read-Host "Introduce el puerto donde correrá el servicio"
                    if (Comprobarpuerto -newPort $newPort) {
                        $puertovalido = $true
                        Write-Host "Puerto válido, se procederá a la instalación." -ForegroundColor Green
                    } else {
                        $puertovalido = $false
                        Write-Host "Puerto inválido o en uso, ingrese otro dato." -ForegroundColor Red
                    }
                }
                InstallCady -ftp $true
            }
        }
        '2' {
            if (Test-Path "C:\nginx\nginx-*\nginx.exe") {
                Write-Host "Nginx ya está instalado en el equipo." -ForegroundColor Yellow
            } else {
                $puertovalido = $false
                while (-not $puertovalido) {
                    $newPort = Read-Host "Introduce el puerto donde correrá el servicio"
                    if (Comprobarpuerto -newPort $newPort) {
                        $puertovalido = $true
                        Write-Host "Puerto válido, se procederá a la instalación." -ForegroundColor Green
                    } else {
                        $puertovalido = $false
                        Write-Host "Puerto inválido o en uso, ingrese otro dato." -ForegroundColor Red
                    }
                }
                InstallNginx -ftp $true
            }
        }
        '3' {
            otrasdescargas
        }
        default {
            Write-Host "Volviendo al menú principal."
        }
    }
}
