# Función para validar una dirección IPv4
validar_ip() {
  if [[ "$1" =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]; then
        return 0 # Verdadero
    else
        return 1 # Falso
    fi
}

# Función para obtener la dirección de red
obtener_direccion_red() {
  local ip=$1
  local octetos
  IFS='.' read -r -a octetos <<< "$ip"
  direccion_red="${octetos[0]}.${octetos[1]}.${octetos[2]}.0"
  echo "$direccion_red"
}