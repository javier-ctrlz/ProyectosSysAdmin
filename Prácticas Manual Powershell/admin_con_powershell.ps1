#Ilustración 111
Get-Service

#Ilustración 112
Get-Service -Name Spooler
Get-Service -DisplayName Hora*

#Ilustración 113
Get-Service | WQhere-Object {$_.Status -eq "Running"}

#Ilustración 114
Get-Service | WQhere-Object {$_.Status -eq "Automatic"} | Select-Object Name, StartType

#Ilustración 115
Get-Service -DependentServices Spooler

#Ilustración 116
Get-Service -RequiredServices Fax

#Ilustración 117
Stop-Service -Name Spooler -Confirm -PassThru

#Ilustración 118
Start-Service -Name Spooler -Confirm -PassThru

#Ilustración 119
Suspend-Service -Name stisvc -Confirm -PassThru

#Ilustración 120
Get-Service | Where-Object CanPauseAndContinue -eq True

#Ilustración 121
Suspend-Service -Name Spooler

#Ilustración 122
Restart-Service -Name WSearch -Confirm -PassThru

#Ilustración 123
Set-Service -Name dcsvc -DisplayName "Servicio de virtualización  de credenciales de seguridad distribuidas" 

#Ilustración 124
Set-Service -Name BITS -StartupType Automatic -Confirm -PassThru | Select-Object Name, StartType

#Ilustración 125
Set-Service -Name BITS -Description "Transfiere archivos en segundo plano mediante el uso de ancho de banda de red inactivo"

#Ilustración 126
Get-CimInstance Win32_Service -Filter "Name='BITS'" | Format-List Name, Description

#Ilustración 127
Set-Service -Name Spooler -Status Running -Confirm -PassThru

#Ilustración 128
Set-Service -Name BITS -Status Stopped -Confirm -PassThru

#Ilustración 129
Set-Service -Name stisvc -Status Paused -Confirm -PassThru

#Ilustración 130
Get-Process

#Ilustración 131
Get-Process -Name Acrobat
Get-Process -Name Search*
Get-Process -Id 13948

#Ilustración 132
Get-Process WINWORD -FileVersionInfo

#Ilustración 133
Get-Process WINWORD -IncludeUserName

#Ilustración 134
Get-Process WINWORD -Module

#Ilustración 135
Stop-Process -Name Acrobat -Confirm -PassThru
Stop-Process -Id 10940 -Confirm -PassThru
Get-Process -Name Acrobat | Stop-Process -Confirm -PassThru

#Ilustración 136
Start-Process -FilePath "C:\Windows\notepad.exe" -PassThru

#Ilustración 137
Start-Process -FilePath "cmd.exe" -ArgumentList "/c mkdir NuevaCarpeta" -WorkingDirectory "C:\Users\JAVI_\OneDrive\Desktop" -PassThru

#Ilustración 138
Start-Process -FilePath "notepad.exe" -WindowStyle Maximized -PassThru

#Ilustración 139
Start-Process -FilePath "C:\Users\JAVI_\OneDrive\Desktop\TT.txt" -Verb Print -PassThru

#Ilustración 140
Get-Process -Name notep*
Wait-Process -Name notepad
Get-Process -Name notep*

Get-Process -Name notepad
Wait-Process -Id 11568
Get-Process -Name notep*

Get-Process -Name notep*
Get-Process -Name notepad | Wait-Process

#Ilustración 141
Get-LocalUser

#Ilustración 142
Get-LocalUser -SID S-1-5-21-1234567890-1234567890-1234567890-1234 | Select-Object

#Ilustración 143
Get-LocalUser -Name JAVI_ | Select-Object

#Ilustración 144
Get-LocalGroup

#Ilustración 145
Get-LocalGroup -Name Administradores | Select-Object

#Ilustración 146
Get-LocalGroup -SID S-1-5-32-544 | Select-Object

#Ilustración 147
New-LocalUser -Name "Usuario2" -Description "Usuario de prueba 2" -Password (ConvertTo-SecureString "12345" -AsPlainText -Force)

#Ilustración 148
New-LocalUser -Name "Usuario1" -Description "Usuario de prueba 1" -NoPassword

#Ilustración 149
Get-LocalUser -Name "Usuario1"
Remove-LocalUser -Name "Usuario1"
Get-LocalUser -Name "Usuario1"

Get-LocalUser -Name "Usuario2"
Get-LocalUser -Name "Usuario2" | Remove-LocalUser
Get-LocalUser -Name "Usuario2"

#Ilustración 150
New-LocalGroup -Name "Grupo1" -Description "Grupo de prueba 1"

#Ilustración 151
Add-LocalGroupMember -Group "Grupo1" -Member "Usuario2" -Verbose

#Ilustración 152
Get-LocalGroupMember -Group "Grupo1"

#Ilustración 153
Remove-LocalGroupMember -Group "Grupo1" -Member "Usuario1"
Remove-LocalGroup -Name "Grupo1" -Member "Usuario2"
Get-LocalGroupMember "Grupo1" 

#Ilustración 154
Get-LocalGroup -Name "Grupo1"
Remove-LocalGroup -Name "Grupo1"
Get-LocalGroup -Name "Grupo1"