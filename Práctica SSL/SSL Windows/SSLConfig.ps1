# Configuración inicial y menú de gestión de SSL para FTP y HTTP
# Javier Zapien
# Descripción: Script principal: SSLConfig.ps1

# --- Importación de scripts y módulos necesarios ---
. "$PSScriptRoot\ftpConfig.ps1"
. "$PSScriptRoot\SSLfunctions.ps1"
. "$PSScriptRoot\httpconfig.ps1"
. "$PSScriptRoot\httpfunctions.ps1"

# --- Descarga e instalación de OpenSSL (comentado) ---
# Se requiere OpenSSL para crear los archivos de certificados para Caddy y Nginx
# Descomenta la siguiente línea si aún no lo tienes instalado:
# choco install openssl -y

# --- Importación del módulo de administración web ---
Import-Module WebAdministration

# --- Creación de certificado SSL (comentado) ---
# Genera un certificado SSL autofirmado. Descomenta la siguiente línea y ejecútala si es necesario.
# New-SelfSignedCertificate -DnsName "ftp.PruebaFTP.com" -CertStoreLocation "Cert:\LocalMachine\My"

# --- Verificación e instalación del rol FTP ---
if ((Get-WindowsFeature -Name Web-FTP-Server).Installed) {
    Write-Host "FTP instalado" -ForegroundColor Green
} else {
    Write-Host "FTP no instalado, se procederá a configurar su instalación" -ForegroundColor Yellow
    # Llamada a la función que configura FTP
    Configftp
}

# --- Menú para la configuración de SSL para FTP ---
$running = $true
while ($running) {
    Write-Host " "
    Write-Host "¿Desea configurar SSL para FTP? [S/N]"
    $opc = Read-Host "Opción"
    if ($opc.ToLower() -eq "s" -or $opc.ToLower() -eq "si") {
        Configsslftp
        $running = $false
    } elseif ($opc.ToLower() -eq "n" -or $opc.ToLower() -eq "no") {
        $running = $false
    } else {
        Write-Host "Opción inválida. Intente nuevamente." -ForegroundColor Red
    }
}

# --- Menú para la instalación de servicios o visualización de opciones en el servidor FTP ---
$running = $true
while ($running) {
    Write-Host " "
    Write-Host "======================================="
    Write-Host "  Menú de Gestión de Servicios FTP"
    Write-Host "======================================="
    Write-Host "[1] Instalar servicios HTTP"
    Write-Host "[2] Ver opciones del servidor FTP"
    Write-Host "======================================="
    $opc = Read-Host "Selecciona una opción [1-2]:"
    
    switch ($opc) {
        "1" {
            httpconfig
            cd C:\Users\Administrador
            $running = $false
        }
        "2" {
            elegirserviciosftp
            cd C:\Users\Administrador
            $running = $false
        }
        default {
            Write-Host "Opción inválida. Por favor, selecciona 1 o 2." -ForegroundColor Red
        }
    }
}
