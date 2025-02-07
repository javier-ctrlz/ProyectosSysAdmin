#Ilustración 73
Get-Verb

#Ilustración 74
function Get-Fecha 
{
    Get-Date
}

Get-Fecha

#Ilustración 75
Get-ChildItem -Path Function:\Get-*

#Ilustración 76
Get-ChildItem -Path Function:\Get-Fecha | Remove-Item
Get-ChildItem -Path Function:\Get-*

#Ilustación 77
function Get-Resta {
    param ([int]$num1,[int]$num2)
    $resta = $num1 - $num2
    Write-Host "La resta de los parametros es $resta"
}

#Ilustración 78
Get-Resta 10 5

#Ilustración 79
Get-Resta -num2 10 -num1 5

#Ilustración 80
Get-Resta -num2 10

#Ilustración 81
function Get-Resta {
    param ( [Parameter(Mandatory)][int]$num1, [int]$num2 )
    $resta = $num1 - $num2
    Write-Host "La resta de los parametros es $resta"
}

Get-Resta -num2 10

#Ilustración 82
function Get-Resta {
    [CmdletBinding()]
    param ( [int]$num1, [int]$num2 )
    $resta = $num1 - $num2
    Write-Host "La resta de los parametros es $resta"
}

#Ilustración 83
(Get-Command -Name Get-Resta).Parameters.Keys

#Ilustración 84
function Get-Resta {
    [CmdletBinding()]
    param ( [int]$num1, [int]$num2 )
    $resta = $num1 - $num2 #Operación que realiza la resta
    Write-Host "La resta de los parametros es $resta"
}

#Ilustración 85
function Get-Resta {
    [CmdletBinding()]
    param ( [int]$num1, [int]$num2 )
    $resta = $num1 - $num2
    Write-Verbose - Message "Operación que va a realizar una resta de $num1 y $num2"
    Write-Host "La resta de los parametros es $resta"
}

Get-Resta 10 5 -Verbose