# ----------------------------------------------------------------
# Función: httpconfig
# Descripción: Valida la instalación de IIS, configura el puerto de 
#              escucha y habilita SSL para el sitio web predeterminado.
#              Además, llama al menú para la instalación de servicios HTTP.
# ----------------------------------------------------------------
function httpconfig {
    # Importar funciones adicionales para HTTP desde el módulo correspondiente
    . "$PSScriptRoot\httpfunctions.ps1"

    Write-Host "Validando instalación de los servicios de IIS..."

    # Verificar si IIS (Web-Server) está instalado
    if ((Get-WindowsFeature -Name Web-Server).Installed) {
        Write-Host "IIS instalado e iniciado." -ForegroundColor Green
        $opc = "s"
    } else {
        $running = $true
        while ($running) {
            Write-Host "Primero debes instalar el servicio HTTP de IIS. ¿Deseas instalarlo? [S/N]"
            $opc = Read-Host "Opción"
            if ($opc.ToLower() -eq "s" -or $opc.ToLower() -eq "si") {
                Install-WindowsFeature -Name Web-Server -IncludeManagementTools
                Write-Host "IIS instalado exitosamente." -ForegroundColor Green
                $opc = "s"
                $running = $false
            } elseif ($opc.ToLower() -eq "n" -or $opc.ToLower() -eq "no") {
                Write-Host "No se instalará IIS. Saliendo de la configuración." -ForegroundColor Red
                $opc = "n"
                $running = $false
                return
            } else {
                Write-Host "Opción inválida, intente nuevamente." -ForegroundColor Red
            }
        }
    }

    # Configurar el puerto para IIS
    $running = $true
    while ($running) {
        Write-Host "¿Desea configurar un puerto específico para IIS? [S/N]"
        $opc = Read-Host "Opción"
        if ($opc.ToLower() -eq "s" -or $opc.ToLower() -eq "si") {
            $newPort = Read-Host "Introduce el puerto donde correrá el servicio"
            if (Comprobarpuerto -newPort $newPort) {
                Write-Host "Puerto válido, se procederá a la configuración." -ForegroundColor Green
                # Actualizar el puerto de escucha del sitio web predeterminado
                Set-WebBinding -Name "Default Web Site" -BindingInformation "*:80:" -PropertyName port -Value $newPort > $null
                $running = $false
            } else {
                Write-Host "Puerto inválido o en uso, ingrese otro dato." -ForegroundColor Red
            }
        } elseif ($opc.ToLower() -eq "n" -or $opc.ToLower() -eq "no") {
            Write-Host "IIS se mantendrá en el puerto por defecto (80)." -ForegroundColor Yellow
            $newPort = 80
            $running = $false
        } else {
            Write-Host "Opción inválida, intente de nuevo." -ForegroundColor Red
        }
    }

    # Preguntar si se desea configurar SSL para IIS
    $running = $true
    while ($running) {
        Write-Host "¿Desea configurar SSL para IIS? [S/N]"
        $opc = Read-Host "Opción"
        if ($opc.ToLower() -eq "s" -or $opc.ToLower() -eq "si") {
            ConfigsslIIS
            $running = $false
        } elseif ($opc.ToLower() -eq "n" -or $opc.ToLower() -eq "no") {
            $running = $false
        } else {
            Write-Host "Opción inválida, intente nuevamente." -ForegroundColor Red
        }
    }

    # Llamar al menú de servicios web
    if ($opc -eq "s") {
        elegirserviciosweb
    }
}
