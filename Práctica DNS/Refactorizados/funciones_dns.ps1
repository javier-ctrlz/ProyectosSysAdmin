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
