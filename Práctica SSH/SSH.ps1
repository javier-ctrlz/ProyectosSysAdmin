# Script para instalar y configurar un servidor SSH
# Zapien Rivera Jes�s Javier
# 302 IS

# Script principal

# Importar el m�dulo de gesti�n de usuarios
. "$PSScriptRoot\usuarios.ps1"

# Instalaci�n y Configuraci�n inicial del Servidor SSH
Write-Host "Instalando el rol de servidor SSH..."
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Write-Host "Servidor SSH instalado exitosamente." -ForegroundColor Green
New-NetFirewallRule -Name "SSH" -DisplayName 'OpenSSH Server' -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow # Habilita una regla para evitar problemas con el firewall
Write-Host "Instalaci�n del Servidor SSH completa" -ForegroundColor Green

# Men� Principal
do {
    Write-Host " "
    Write-Host "=== Men� de Configuraci�n Servidor SSH ==="
    Write-Host "1. Crear Usuario SSH"
    Write-Host "2. Salir"
    Write-Host " "

    $Opcion = Read-Host "Selecciona una opci�n (1-2)"

    switch ($Opcion) {
        "1" {
            CrearUsuarioSSH # Llama a la funci�n de usuarios.ps1
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
            Write-Host "Opci�n no v�lida. Por favor, selecciona una opci�n del 1 al 2." -ForegroundColor Yellow
        }
    }
} while ($true) # Bucle infinito hasta que se seleccione "Salir"
