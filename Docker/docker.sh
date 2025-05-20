#!/bin/bash
# Zapien Rivera Jesús Javier
# 302 IS

source dockerfunctions.sh

while true; do
  echo "======== DOCKER ========"
  echo "Seleccione una opción:"
  echo "1) Instalar docker"
  echo "2) Descargar imagen de apache"
  echo "3) Modificar imagen de apache"
  echo "4) Crear imagen perzonalizada"
  echo "5) Configurar postgress"
  echo "6) Salir"
  echo "Elige una opcion: "
  read opc

  case $opc in
    1)
        installdocker
        ;;
    2)
        installapache
        ;;
    3)
        modapache
        ;;
    4)
        createdockerfile
        ;;
    5)
        configpostgres
        ;;
    *)
        echo 'Saliendo...'
        break
        ;;
  esac
done
