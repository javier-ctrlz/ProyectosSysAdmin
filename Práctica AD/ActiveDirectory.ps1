# Script para configurar un dominio de Active Directory
# Zapien Rivera Jesús Javier
# 302 IS

. "$PSScriptRoot/funcionesad.ps1"

while($true){
    echo "==================================="
    echo "Menu de opciones"
    echo "==================================="
    echo "1. Instalar y configurar Active Directory"
    echo "2. Crear usuario"
    echo "3. Salir"
    $opc = Read-Host "Selecciona una opción"

    switch($opc){
        "1"{
            InstalarAD
            ConfigurarDominioAD
        }
        "2"{
            CrearUsuario
        }
        "3"{
            Write-Host "Saliendo..." -ForegroundColor Yellow
            exit
        }
        default { Write-Host "Selecciona una opcion valida (1..3)" -ForegroundColor Yellow}
    }
}