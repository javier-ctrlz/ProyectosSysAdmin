function Configftp {
    # Importar las funciones de FTP desde el módulo correspondiente
    . "$PSScriptRoot/ftpfunctions.ps1"

    Write-Host "Iniciando instalación y configuración del servidor FTP..." -ForegroundColor Cyan
    InstallFtp

    $running = $true
    while ($running) {
        Clear-Host
        Write-Host "========================================"
        Write-Host "       Menú de Administración FTP       "
        Write-Host "========================================"
        Write-Host "[1] Administrar Usuario"
        Write-Host "[2] Crear Usuario"
        Write-Host "[Otro] Salir"
        Write-Host "========================================"
        $opc = Read-Host "Seleccione una opción [1-2]"

        switch ($opc) {
            '1' {
                Login
            }
            '2' {
                Register
            }
            default {
                $running = $false
            }
        }
        # Reiniciar los servicios FTP e IIS para aplicar cambios
        Restart-Service ftpsvc -Force
        Restart-Service W3SVC -Force
    }

    # Reiniciar el sitio FTP en IIS para asegurar que los cambios se apliquen
    Restart-WebItem "IIS:\Sites\PruebaFTP" -Verbose
}
