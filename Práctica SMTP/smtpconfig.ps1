# Script para configurar un servidor de correo
# Zapien Rivera Jesús Javier
# 302 IS

#Ruta donde guardas los scripts
. "$PSScriptRoot\smtpfunctions.ps1"



$running = $true
while($running){
    Write-Host "========================================"
    Write-Host "Configuración de correo"
    Write-Host "========================================"
    Write-Host "1) Instalar Mercury"
    Write-Host "2) Configurar usuarios"
    Write-Host "3) Instalar SquirrelMail"
    Write-Host "4) Salir"
    $opc = Read-Host "Seleccione una opción"
    switch($opc){
        '1'{
            InstalarMercury
        }
        '2'{
            Write-Host "Abre la ventana de Mercury. Configuration -> Manage Local Users -> Add"
        }
        '3'{
            instalarsquirrel
        }
        '4'{
            Write-Host "Saliendo..."
            $running = $false
        }
        default {
        Write-Host "Opción inválida. Intente nuevamente."
    }
    }

}


