# Zapien Rivera Jesús Javier
# 302 IS

# Función para obtener la dirección de red
function Get-NetworkAddress {
    param (
        [string]$IPAddress
    )

    # Calcular la dirección de red (último octeto en 0)
    $octets = $IPAddress -split "\."
    $networkAddress = "$($octets[0]).$($octets[1]).$($octets[2]).0"

    # Retornar la dirección de red
    return $networkAddress
}

# Función para validar una dirección IPv4
function ValidarIP {
    param(
        [string]$IPAddress
    )
    if ($IPAddress -match "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$") {
        return $true
    } else {
        return $false
    }
}
