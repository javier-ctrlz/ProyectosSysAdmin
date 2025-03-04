# Configuración inicial y menú de gestión para usuarios FTP
# Zapien Rivera Jesús Javier
# 302 IS

# Script principal: FTP.ps1

# Importar el módulo de funciones de gestión de usuarios FTP
. "$PSScriptRoot\USUARIOS_FTP.ps1"

# --- Instalación y Configuración Inicial del Servidor FTP ---
Write-Host " "
Write-Host "=== Instalación y Configuración Inicial del Servidor FTP ==="
Write-Host "Instalando el rol de servidor FTP..."

#Install-WindowsFeature -Name Web-Ftp-Server -IncludeManagementTools -IncludeAllSubFeature
#Install-WindowsFeature -Name Web-Server -IncludeManagementTools -IncludeAllSubFeature
#Install-WindowsFeature -Name Web-Basic-Auth
Import-Module WebAdministration

Write-Host "Rol de servidor FTP instalado exitosamente." -ForegroundColor Green

# Asegurar que el servicio IIS esté instalado y en ejecución
Write-Host "Verificando e iniciando el servicio IIS..."
if (!(Get-Service W3SVC).Status -eq "Running") {
    Start-Service W3SVC
    Write-Host "Servicio IIS iniciado." -ForegroundColor Green
} else {
    Write-Host "Servicio IIS en ejecución." -ForegroundColor Green
}

# --- Configuración del sitio FTP ---
Write-Host " "
Write-Host "=== Configuración del sitio FTP ==="
ConfigurarSitioFTP

Write-Host "Sitio FTP configurado exitosamente." -ForegroundColor Green

# --- Configuración de carpetas base ---
Write-Host " "
Write-Host "=== Configuración de carpetas base ==="
ConfigurarCarpetasFTP

Write-Host "Carpetas base configuradas exitosamente." -ForegroundColor Green

# --- Creación de grupos FTP ---
Write-Host " "
Write-Host "=== Creación de Grupos FTP ==="
CrearGruposFTP

Write-Host "Grupos FTP creados exitosamente." -ForegroundColor Green

# --- Configuración de permisos anónimos ---
Write-Host " "
Write-Host "=== Configuración de acceso anónimo ==="
ConfigurarAccesoAnonimoFTP

Write-Host "Acceso anónimo configurado exitosamente." -ForegroundColor Green

# --- Configuración de Permisos para Grupos y Usuarios Autenticados ---
Write-Host " "
Write-Host "=== Configuración de Permisos para Grupos y Usuarios Autenticados ==="
ConfigurarPermisosGruposUsuarios

Write-Host "Permisos para grupos y usuarios autenticados configurados exitosamente." -ForegroundColor Green

Restart-Service -Name ftpsvc -Force
Restart-Service -Name W3SVC -Force

# ---  Bucle principal del menú ---
while ($true) {
    Write-Host " "
    Write-Host "======================================="
    Write-Host "  Menú de Gestión de Usuarios FTP"
    Write-Host "======================================="
    Write-Host "1. Crear Usuario FTP"
    Write-Host "2. Eliminar Usuario FTP"
    Write-Host "3. Cambiar Grupo de Usuario FTP"
    Write-Host "4. Salir"
    Write-Host "======================================="
    Write-Host " "
    $opcion = Read-Host "Selecciona una opción (1-4)"

    switch ($opcion) {
        "1" {
            CrearUsuarioFTP
            Restart-Service -Name ftpsvc -Force
            Restart-Service -Name W3SVC -Force
        }
        "2" {
            EliminarUsuarioFTP
            Restart-Service -Name ftpsvc -Force
            Restart-Service -Name W3SVC -Force
        }
        "3" {
            CambiarGrupoUsuarioFTP
            Restart-Service -Name ftpsvc -Force
            Restart-Service -Name W3SVC -Force
        }
        "4" {
            Write-Host "Saliendo del script..."
            exit # Salir del bucle while
        }
        default {
            Write-Warning "Opción no válida. Por favor, selecciona una opción del 1 al 4."
        }
    } # Fin del switch
} # Fin del bucle while