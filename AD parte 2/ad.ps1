# Script para configurar un dominio de Active Directory
# Zapien Rivera Jesús Javier
# 302 IS

. "$PSScriptRoot/funcionesad.ps1"

while($true){
    echo "==================================="
    echo "Menu de opciones"
    echo "==================================="
    echo "1. Instalar"
    echo "2. Configurar Active Directory"
    echo "3. Crear usuario"
    echo "4. Crear grupos"
    echo "5. Configurar grupos"
    echo "6. Configurar política de contraseñas"
    echo "7. Habilitar auditoría de AD"
    echo "8. Implementar MFA (Google Authenticator)"
    echo "9. Salir"
    $opc = Read-Host "Selecciona una opción"

    switch($opc){
        "1"{ InstalarAD }
        "2"{ ConfigurarDominioAD }
        "3"{ CrearUsuario }
        "4"{ CrearGruposAD }
        "5"{ ConfigurarPermisosdeGruposAD }
        "6"{ ConfigurarPoliticaContraseñaAD }
        "7"{ HabilitarAuditoriaAD }
        "8"{ ConfigurarMFAAD }
        "9"{ Write-Host "Saliendo..." -ForegroundColor Yellow; exit }
        default { Write-Host "Selecciona una opcion valida (1..9)" -ForegroundColor Yellow }
    }
}