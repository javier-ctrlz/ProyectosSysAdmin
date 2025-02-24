# Script para instalar y configurar un servidor DHCP
# Zapien Rivera Jesús Javier
# 302 IS

# Instalar el rol de servidor DHCP
# Write-Host "Instalando el rol de servidor DHCP..."
# Install-WindowsFeature -Name DHCP -IncludeManagementTools

. "$PSScriptRoot\funciones.ps1"

# Inicio de la configuración del DHCP

# Preguntar por el nombre del DHCP
$NombreDHCP = ""
while ([string]::IsNullOrEmpty($NombreDHCP)) {
    $NombreDHCP = Read-Host "Introduce el nombre para el servidor DHCP"
    if ([string]::IsNullOrEmpty($NombreDHCP)) {
        Write-Host "El nombre del DHCP no puede estar vacío. Por favor, introduce un nombre." -ForegroundColor Yellow
    }
}

# Preguntar por la IP del servidor DHCP
$IPSservidor = ""
while (!($IPSservidor) -or !(ValidarIP -IPAddress $IPSservidor)) {
    $IPSservidor = Read-Host "Introduce la IP del servidor DHCP"
    if ([string]::IsNullOrEmpty($IPSservidor)) {
        Write-Host "La IP del servidor no puede estar vacía." -ForegroundColor Yellow
    } elseif (!(ValidarIP -IPAddress $IPSservidor)) {
        Write-Host "IP no válida. Introduce una IP IPv4 válida." -ForegroundColor Yellow
        $IPSservidor = ""
    }
}

# Calcular la dirección de red usando la función
$RedIP = Get-NetworkAddress -IPAddress $IPSservidor
if ($RedIP -eq $null) {
    Write-Host "No se pudo obtener la dirección de red. Saliendo." -ForegroundColor Red
    return
}


# Preguntar por la IP de inicio del rango DHCP
$RangoInicio = ""
while (!($RangoInicio) -or !(ValidarIP -IPAddress $RangoInicio)) {
    $RangoInicio = Read-Host "Introduce la IP de inicio del rango DHCP"
    if ([string]::IsNullOrEmpty($RangoInicio)) {
        Write-Host "La IP de inicio no puede estar vacía." -ForegroundColor Yellow
    } elseif (!(ValidarIP -IPAddress $RangoInicio)) {
        Write-Host "IP no válida. Introduce una IP IPv4 válida." -ForegroundColor Yellow
        $RangoInicio = ""
    }
}

# Preguntar por la IP de fin del rango DHCP
$RangoFin = ""
while (!($RangoFin) -or !(ValidarIP -IPAddress $RangoFin)) {
    $RangoFin = Read-Host "Introduce la IP de fin del rango DHCP"
    if ([string]::IsNullOrEmpty($RangoFin)) {
        Write-Host "La IP de fin no puede estar vacía." -ForegroundColor Yellow
    } elseif (!(ValidarIP -IPAddress $RangoFin)) {
        Write-Host "IP no válida. Introduce una IP IPv4 válida." -ForegroundColor Yellow
        $RangoFin = ""
    }
}

# Preguntar por la máscara de subred
$MascaraSubred = ""
while (!($MascaraSubred) -or !(ValidarIP -IPAddress $MascaraSubred)) {
    $MascaraSubred = Read-Host "Introduce la Máscara de Subred (ej: 255.255.255.0)"
    if ([string]::IsNullOrEmpty($MascaraSubred)) {
        Write-Host "La Máscara de Subred no puede estar vacía." -ForegroundColor Yellow
    } elseif (!(ValidarIP -IPAddress $MascaraSubred)) {
        Write-Host "Máscara de Subred no válida. Introduce una Máscara IPv4 válida." -ForegroundColor Yellow
        $MascaraSubred = ""
    }
}



# Crear el ámbito DHCP
Write-Host "Creando el ámbito DHCP con nombre $($NombreDHCP)..."
Add-DhcpServerv4Scope -Name $NombreDHCP -StartRange $RangoInicio -EndRange $RangoFin -SubnetMask $MascaraSubred

# Reiniciar el servicio DHCP
Write-Host "Reiniciando el servicio DHCP..."
Restart-Service -Name dhcpserver -Force

Write-Host "Servidor DHCP instalado y configurado exitosamente" -ForegroundColor Green
Write-Host "Nombre del DHCP: $($NombreDHCP)"
Write-Host "IP del Servidor DHCP: $($IPSservidor)"
Write-Host "Rango DHCP: $($RangoInicio) - $($RangoFin)"
Write-Host "Máscara de Subred: $($MascaraSubred)"
Write-Host "Red: $($RedIP)"