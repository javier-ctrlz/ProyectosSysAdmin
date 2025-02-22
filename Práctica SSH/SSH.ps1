# Script para instalar y configurar un servidor SSH
# Zapien Rivera Jesús Javier
# 302 IS

# Script principal

# Importar el módulo de gestión de usuarios
. "$PSScriptRoot\usuarios.ps1"

# Instalación y Configuración inicial del Servidor SSH
Write-Host "Instalando el rol de servidor SSH..."
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Write-Host "Servidor SSH instalado exitosamente." -ForegroundColor Green
New-NetFirewallRule -Name "SSH" -DisplayName 'OpenSSH Server' -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow # Habilita una regla para evitar problemas con el firewall
Write-Host "Instalación del Servidor SSH completa" -ForegroundColor Green

# Menú Principal
do {
    Write-Host " "
    Write-Host "=== Menú de Configuración Servidor SSH ==="
    Write-Host "1. Crear Usuario SSH"
    Write-Host "2. Salir"
    Write-Host " "

    $Opcion = Read-Host "Selecciona una opción (1-2)"

    switch ($Opcion) {
        "1" {
            CrearUsuarioSSH # Llama a la función de usuarios.ps1
            # Reinicio del servicio SSH
            Write-Host "Reiniciando el servicio SSH..."
            try {
                Restart-Service -Name sshd -Force
                Write-Host "Servicio SSH reiniciado exitosamente" -ForegroundColor Green

                # Obtener el objeto NetIPAddress y luego la propiedad IPAddress
                $IPObject = Get-NetIPAddress -InterfaceAlias 'Ethernet' | Where-Object {$_.AddressFamily -eq 'IPv4'}
                $ServerIP = $IPObject.IPAddress

                Write-Host "La IP del servidor SSH es: $($ServerIP)" -ForegroundColor Green
            }
            catch {
                Write-Error "Error al reiniciar el servicio SSH: $($_.Exception.Message)"
                Write-Warning "Problema al intentar reiniciar el servicio SSH" -ForegroundColor Yellow
            }
        }
        "2" {
            Write-Host "Saliendo del script..." -ForegroundColor Yellow
            exit # Sale del do-while
        }
        default {
            Write-Host "Opción no válida. Por favor, selecciona una opción del 1 al 2." -ForegroundColor Yellow
        }
    }
} while ($true) # Bucle infinito hasta que se seleccione "Salir"
