# ----------------------------------------------------------------
# Función: Configsslftp
# Descripción: Configura el certificado SSL para el sitio FTP y
#              establece las políticas de seguridad SSL en IIS.
# ----------------------------------------------------------------
function Configsslftp {
    # Generar un certificado SSL autofirmado (línea comentada)
    # New-SelfSignedCertificate -DnsName "ftp.PruebaFTP.com" -CertStoreLocation "Cert:\LocalMachine\My"
    
    # Seleccionar el certificado existente. Si generaste otro, actualiza la última parte de la ruta.
    $cert = Get-Item "Cert:\LocalMachine\My\E99189813BB80D71022255874F3BD71115C4E0C0"
    Write-Host "Certificado seleccionado:" 
    Write-Host $cert

    # Asignar el certificado SSL al sitio FTP
    Set-ItemProperty "IIS:\Sites\PruebaFTP" -Name "ftpServer.security.ssl.serverCertHash" -Value E99189813BB80D71022255874F3BD71115C4E0C0
    Set-ItemProperty "IIS:\Sites\PruebaFTP" -Name "ftpServer.security.ssl.serverCertStoreName" -Value "My"

    # Configurar las políticas SSL para el canal de control y datos (habilitar SSL)
    $SSLPolicy = @(
        'ftpServer.security.ssl.controlChannelPolicy',
        'ftpServer.security.ssl.dataChannelPolicy'
    )
    Set-ItemProperty "IIS:\Sites\PruebaFTP" -Name $SSLPolicy[0] -Value 1
    Set-ItemProperty "IIS:\Sites\PruebaFTP" -Name $SSLPolicy[1] -Value 1

    # Reiniciar el servicio FTP para aplicar los cambios
    Restart-Service ftpsvc -Force
    Write-Host "Configuración SSL para FTP completada." -ForegroundColor Green
}

# ----------------------------------------------------------------
# Función: ConfigsslIIS
# Descripción: Configura el certificado SSL para el sitio web de IIS,
#              asignando un nuevo puerto para HTTPS.
# Parámetro:
#   - $newPort : Puerto en el que correrá el servicio HTTPS.
# ----------------------------------------------------------------
function ConfigsslIIS {
    param (
        [int]$newPort
    )
    # Generar un certificado SSL autofirmado (línea comentada)
    # New-SelfSignedCertificate -DnsName "http.httpsite.com" -CertStoreLocation "Cert:\LocalMachine\My"
    
    # Seleccionar el certificado existente
    $cert = Get-Item "Cert:\LocalMachine\My\E99189813BB80D71022255874F3BD71115C4E0C0"
    Write-Host "Thumbprint del certificado:" $cert.Thumbprint

    # Asignar el certificado SSL a la conexión HTTPS existente en el "Default Web Site"
    $binding = Get-WebBinding -Name "Default Web Site" -Protocol "https"
    $binding.AddSslCertificate($cert.GetCertHashString(), "My")

    # Solicitar un puerto válido para la conexión HTTPS
    $running = $true
    while ($running) {
        $newPort = Read-Host "Introduce el puerto para HTTPS en el servicio"
        if (Comprobarpuerto -newPort $newPort) {
            Write-Host "Puerto válido, se procederá a la configuración." -ForegroundColor Green
            $running = $false
        } else {
            Write-Host "Puerto inválido o en uso, ingresa otro valor." -ForegroundColor Red
        }
    }
    
    # Crear la nueva conexión HTTPS con el puerto especificado
    New-WebBinding -Name "Default Web Site" -IPAddress "*" -Port $newPort -Protocol "https"
    Get-WebBinding -Name "Default Web Site" -Protocol "https" -Port 444 | ForEach-Object {
        $_.AddSslCertificate($cert.GetCertHashString(), "MY")
    }
    
    # Reiniciar IIS para aplicar los cambios
    iisreset
    Write-Host "Configuración SSL en IIS completada." -ForegroundColor Green
}

# ----------------------------------------------------------------
# Función: ConfigsslNginx
# Descripción: Exporta el certificado SSL para Nginx y configura el
#              archivo nginx.conf para habilitar HTTPS en el puerto indicado.
# ----------------------------------------------------------------
function ConfigsslNginx {
    # Seleccionar el certificado existente
    $cert = Get-Item "Cert:\LocalMachine\My\E99189813BB80D71022255874F3BD71115C4E0C0"
    
    # Exportar el certificado en formato PFX y CRT para Nginx
    Export-PfxCertificate -Cert $cert -FilePath "C:\nginx\certificado.pfx" -Password (ConvertTo-SecureString -String "Javeir1234!" -Force -AsPlainText)
    Export-Certificate -Cert $cert -FilePath "C:\nginx\certificado.crt"
    
    # Crear los archivos de clave y certificado en formato PEM y KEY usando OpenSSL
    openssl pkcs12 -in C:\nginx\certificado.pfx -clcerts -nokeys -out C:\nginx\clave.pem -passin pass:Javier1234!
    openssl pkcs12 -in C:\nginx\certificado.pfx -nocerts -nodes -out C:\nginx\clave.key -passin pass:Javier1234!

    # Solicitar un puerto válido para HTTPS
    $running = $true
    while ($running) {
        $newPort = Read-Host "Introduce el puerto para HTTPS del servicio"
        if (Comprobarpuerto -newPort $newPort) {
            Write-Host "Puerto válido, se procederá a la configuración." -ForegroundColor Green
            $running = $false
        } else {
            Write-Host "Puerto inválido o en uso, ingresa otro valor." -ForegroundColor Red
        }
    }
    
    # Ruta del archivo de configuración de Nginx (actualiza la variable $version si es necesario)
    $nginxconfig = "C:\nginx\nginx-$version\conf\nginx.conf"
    
    # Leer el contenido actual del archivo de configuración
    $config = Get-Content $nginxconfig -Raw

    # Definir la nueva configuración HTTPS para Nginx
    $newHttpsConfig = @"
server {
    listen $newPort ssl;
    server_name localhost;

    ssl_certificate C:\nginx\clave.pem;
    ssl_certificate_key C:\nginx\clave.key;

    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 5m;

    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        root html;
        index index.html index.htm;
    }
}
"@

    # Reemplazar o insertar la sección HTTPS en el archivo de configuración
    $config = $config -replace '(?s)# HTTPS server.*?}', "# HTTPS server`r`n$newHttpsConfig"
    $config | Set-Content -Path $nginxconfig

    Write-Host "Configuración SSL para Nginx completada." -ForegroundColor Green
}

# ----------------------------------------------------------------
# Función: ConfigsslCaddy
# Descripción: Exporta el certificado SSL para Caddy, configura la sección
#              HTTPS en el archivo Caddyfile y formatea la configuración.
# ----------------------------------------------------------------
function ConfigsslCaddy {
    # Seleccionar el certificado existente
    $cert = Get-Item "Cert:\LocalMachine\My\E99189813BB80D71022255874F3BD71115C4E0C0"
    
    # Exportar el certificado en formato PFX y CRT para Caddy
    Export-PfxCertificate -Cert $cert -FilePath "C:\caddy\certificado.pfx" -Password (ConvertTo-SecureString -String "Javier1234!" -Force -AsPlainText)
    Export-Certificate -Cert $cert -FilePath "C:\caddy\certificado.crt"
    
    # Exportar la clave privada en formato KEY usando OpenSSL
    openssl pkcs12 -in C:\caddy\certificado.pfx -nocerts -nodes -out C:\caddy\clave.key -passin pass:Javier1234!

    # Solicitar un puerto válido para HTTPS
    $running = $true
    while ($running) {
        $newPort = Read-Host "Introduce el puerto para HTTPS del servicio"
        if (Comprobarpuerto -newPort $newPort) {
            Write-Host "Puerto válido, se procederá a la configuración." -ForegroundColor Green
            $running = $false
        } else {
            Write-Host "Puerto inválido o en uso, ingresa otro valor." -ForegroundColor Red
        }
    }
    
    # Definir la nueva configuración HTTPS para Caddy
    $httpsConfig = @"
https://localhost:$newPort {
    tls internal
    root * C:/caddy/www/
    file_server
}
"@
    # Añadir la sección HTTPS al final del Caddyfile
    Add-Content -Path "C:\caddy\Caddyfile" -Value $httpsConfig

    # Formatear el Caddyfile para asegurar la correcta sintaxis
    & "C:\caddy\caddy.exe" fmt --overwrite

    Write-Host "Configuración SSL para Caddy completada." -ForegroundColor Green
}
