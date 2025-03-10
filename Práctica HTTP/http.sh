#!/bin/bash
# Script principal para la instalación de servicios HTTP
# Zapien Rivera Jesús Javier
# 302 IS

# Importar el script de funciones de servicios HTTP
source "$(dirname "$0")/funciones_http.sh"

# --- Inicio del script ---

while true; do
    echo ""
    echo "=== Instalación de Servicios HTTP ==="
    echo ""
    echo "======================================="
    echo "  Selecciona el servicio HTTP a instalar"
    echo "======================================="
    echo "1. Nginx"
    echo "2. Tomcat"
    echo "3. OpenLiteSpeed"
    echo "4. Salir" # Opción para salir ahora es la 4
    echo "======================================="
    echo ""
    read -p "Selecciona una opción (1-4): " opcion_servicio

    case "$opcion_servicio" in
        1)
            instalar_servicio_http "nginx" ;; # Llama a la función para Nginx
        2)
            instalar_servicio_http "tomcat" ;; # Llama a la función para Tomcat
        3)
            instalar_servicio_http "ols" ;;    # Llama a la función para OpenLiteSpeed
        4)
            echo "Saliendo del script..."
            exit 0
            ;;
        *)
            echo "Opción no válida. Por favor, selecciona una opción del 1 al 4."
            ;;
    esac
done
