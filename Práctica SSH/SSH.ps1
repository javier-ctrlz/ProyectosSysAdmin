# Script para instalar y configurar un servidor SSH
# Zapien Rivera Jesús Javier
# 302 IS

# Script principal

# Importar el módulo de gestión de usuarios
.\usuarios.ps1

# Instalación y Configuración Inicial del Servidor SSH
if ($SSHFeature.InstallState -eq "Installed") {
    Write-Host "El rol de servidor SSH ya está instalado, verificando activación..." -ForegroundColor Green
    Start-Service sshd
    Write-Host "SSH instalado y activado." -ForegroundColor Yellow
} else {
    Write-Host "Instalando el rol de servidor SSH..."
    try {
        Install-WindowsFeature -Name OpenSSH-Server -Online -ErrorAction Stop
        Write-Host "Servidor SSH instalado exitosamente." -ForegroundColor Green

        Write-Host "Iniciando el servicio SSH y configurando el inicio automático..."
        Start-Service sshd
        Set-Service -Name sshd -StartupType 'Automatic'
        Write-Host "Servicio SSH iniciado y configurado para inicio automático" -ForegroundColor Green
        Write-Host "Instalación del Servidor SSH completa." -ForegroundColor Green
    }
    catch {
        Write-Error "Error al instalar el rol de servidor SSH: $($_.Exception.Message)"
        Write-Warning "Falló la instalación del rol de Servidor SSH." -ForegroundColor Yellow
    }
}

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
        }
        "2" {
            Write-Host "Saliendo del script."
            break # Sale del do-while
        }
        default {
            Write-Host "Opción no válida. Por favor, selecciona una opción del 1 al 2." -ForegroundColor Yellow
        }
    }
} while ($true) # Bucle infinito hasta que se seleccione "Salir"

# Reinicio del servicio SSH
Write-Host "Reiniciando el servicio SSH..."
try {
    Restart-Service -Name sshd -Force
    Write-Host "Servicio SSH reiniciado exitosamente" -ForegroundColor Green
    Write-Host "La IP del servidor SSH es: $(Get-NetIPAddress -InterfaceAlias 'Ethernet' | Where-Object {$_.AddressFamily -eq 'IPv4'}).IPAddress" -ForegroundColor Green
}
catch {
    Write-Error "Error al reiniciar el servicio SSH: $($_.Exception.Message)"
    Write-Warning "Problema al intentar reiniciar el servicio SSH" -ForegroundColor Yellow
}