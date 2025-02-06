#Ilustración 50
Get-Service -Name "LSM" | Get-Member

#Ilustración 51
Get-Service -Name "LSM" | Get-Member -MemberType Property

#Ilustración 52
Get-Item .\test.txt | Get-Member -MemberType Method

#Ilustración 53
Get-Item .\test.txt | Select-Object Name, Length

#Ilustración 54
Get-Service | Select-Object -Last 5

#Ilustración 55
Get-Service | Select-Object -First 5

#Ilustración 56
Get-Service | Where-Object {$_.Status -eq "Running"}

#Ilustración 57
(Get-Item .\test.txt).IsReadOnly
(Get-Item .\test.txt).IsReadOnly = 1
(Get-Item .\test.txt).IsReadOnly

#Ilustración 58
Get-ChildItem *.txt
(Get-Item .\test.txt).CopyTo("C:\Users\JAVI_\OneDrive\Desktop\prueba.txt")
(Get-Item .\test.txt).Delete()
Get-ChildItem *.txt

#Ilustración 59
$miObjeto = New-Object PSObject
$miObjeto | Add-Member -MemberType NoteProperty -Name Nombre -Value "Miguel"
$miObjeto | Add-Member -MemberType NoteProperty -Name Edad -Value 23
$miObjeto | Add-Member -MemberType ScriptMethod -Name Saludar -Value { Write-Host "¡Hola Mundo!" }

#Ilustración 60
$miObjeto = New-Object -TypeName PSObject -Property @{
    Nombre = "Miguel"
    Edad = 23
}
$miObjeto | Add-Member -MemberType ScriptMethod -Name Saludar -Value { Write-Host "¡Hola Mundo!"}
$miObjeto | Get-Member

#Ilustración 61
$miObjeto = [PSCustomObject]@{
    Nombre = "Miguel"
    Edad = 23
}
$miObjeto | Add-Member -MemberType ScriptMethod -Name Saludar -Value { Write-Host "¡Hola Mundo!"}
$miObjeto | Get-Member

#Ilustración 62
Get-Process -Name Acrobat | Stop-Process

#Ilustración 63
Get-Help -Full Stop-Process

#Ilustración 64
Get-Help -Full Get-Process

#Ilustración 65
Get-Process
Get-Process -Name Acrobat | Stop-Process
Get-Process

#Ilustración 66
Get-Help -Full Get-ChildItem
Get-Help -Full Get-Clipboard
Get-ChildItem *.txt | Get-Clipboard

#Ilustración 67
Get-Help -Full Stop-Service

#Ilustración 68
-InputObject <ServiceController[]>
    Required?                    true
    Position?                    1
    Default value
    Accept pipeline input?       true (ByValue)
    Accept wildcard characters?  false

-Name <String[]>
    Required?                    false
    Position?                    named
    Default value
    Accept pipeline input?       false
    Accept wildcard characters?  false

#Ilustración 69
Get-Service
Get-Service Spooler | Stop-Service
Get-Service

#Ilustración 70
Get-Service
"Spooler" | Stop-Service
Get-Service
Get-Service

#Ilustración 71
Get-Service
$miObjeto = [PSCustomObject]@{
    Name = "Spooler"
}
$miObjeto | Stop-Service
Get-Service
Get-Service