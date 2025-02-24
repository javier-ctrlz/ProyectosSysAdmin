# Script para instalar y configurar un servidor DNS
# Zapien Rivera Jesús Javier 
# 302 IS

# Instalar el servicio de servidor DNS
#Write-Host "Instalando el rol de servidor DNS..."
#Install-WindowsFeature -Name DNS -IncludeManagementTools

. "$PSScriptRoot\funciones_dns.ps1"

# Preguntar al usuario por el dominio
while (!$DomainName) {
    $DomainName = Read-Host "Introduce el dominio que vas a usar (con terminación en .com)"
    if ([string]::IsNullOrEmpty($DomainName)) {
        Write-Host "El dominio no puede estar vacío. Por favor, introduce un dominio."
    }
}

# Preguntar al usuario por la IP del servidor DNS
$DNSServerIP = ""
while (!$DNSServerIP) {
    $DNSServerIP = Read-Host "Introduce la IP que se asignará a este servidor DNS"
    if (! (ValidarIP -IPAddress $DNSServerIP)) {
        Write-Host "IP no válida. Introduce una IP IPv4 válida"
        $DNSServerIP = ""
    }
}

# Crear la zona de búsqueda directa
Write-Host "Creando la zona de búsqueda directa para $($DomainName)..."
Add-DnsServerPrimaryZone -Name "$($DomainName)" -ZoneFile "$($DomainName).dns" -DynamicUpdate NonsecureAndSecure
 
# Añadir registros
Write-Host "Añadiendo registros A para $($DomainName) y www.$($DomainName) apuntando a la IP de este servidor DNS ($DNSServerIP)..."
Add-DnsServerResourceRecordA -Name "@" -ZoneName $DomainName -IPv4Address $DNSServerIP
Add-DnsServerResourceRecordA -Name "www" -ZoneName $DomainName -IPv4Address $DNSServerIP

# Reiniciar el servicio DNS
Write-Host "Reiniciando el servicio DNS..."
Restart-Service -Name DNS

Write-Host "Servidor DNS instalado y configurado para el dominio $($DomainName)."
Write-Host "Este servidor DNS se configuró con la IP: $DNSServerIP"