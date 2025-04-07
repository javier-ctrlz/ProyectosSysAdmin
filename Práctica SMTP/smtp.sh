#!/bin/bash
# Zapién Rivera Jesús Javier
# 302 IS

# Se importa nuestro archivo de funciones
source ./smtpfunctions.sh

while true; do
    clear
    echo "========================================"
    echo "   Configuración de correo"
    echo "========================================"
    echo "1) Instalar Postfix y Dovecot"
    echo "2) Configurar dominio de correo"
    echo "3) Configurar usuario"
    echo "4) Configurar SquirrelMail"
    echo "5) Salir"
    echo "========================================"
    read -p "Seleccione una opción: " option

    case $option in
        1) InstallServices ;;
        2) ConfigureDomain ;;
        3) ConfigureUser ;;
        4) ConfigureSquirrelMail ;;
        5) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción no válida" ;;
    esac

    read -p "Presione Enter para continuar..."
done

