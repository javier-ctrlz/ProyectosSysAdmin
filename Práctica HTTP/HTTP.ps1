# Configuración inicial y menú de gestión para servicios HTTP
# Zapien Rivera Jesús Javier
# 302 IS

# Importar el módulo de funciones de gestión de servicios HTTP
. "$PSScriptRoot\FUNCIONES_HTTP.ps1"

# --- Instalación y Configuración Inicial de Componentes ---
Write-Host ""
Write-Host "=== Instalación y Configuración Inicial de Servicios HTTP ==="
Write-Host ""

# --- Bucle principal del menú ---
while ($true) {
    Write-Host ""
    Write-Host "======================================="
    Write-Host "    Menú de Gestión de Servicios HTTP"
    Write-Host "======================================="
    Write-Host "1. Instalar NGINX"
    Write-Host "2. Instalar Tomcat"
    Write-Host "3. Configurar IIS"
    Write-Host "4. Salir"
    Write-Host "======================================="
    Write-Host ""
    $opcion = Read-Host "Selecciona una opción (1-4)"

    switch ($opcion) {
        "1" { Install-HTTPService -Service "nginx" }
        "2" { Install-HTTPService -Service "tomcat" }
        "3" { Install-HTTPService -Service "iis" }
        "4" { Write-Host "Saliendo del script..."; exit }
        default { Write-Warning "Opción no válida. Seleccione una opción del 1 al 4." }
    }
}
