#Ilustración 93
try 
{
    Write-OutPut "Todo bien"
}
catch 
{
    Write-OutPut "Algo lanzó una excepción"
    Write-OutPut $_
}

try
{
    Start-Something -ErrorAction Stop
}
catch
{
    Write-OutPut "Algo generó una excepción o usó Write-Error"
    Write-OutPut $_
}

#Ilustración 94
$comando = [System.Data.SqlClient.SqlCommand]::new(queryString, connection)
try
{
    $comando.Connection.Open()
    $comando.ExecuteNonQuery()
}
finally
{
    Write-Error "Ha habido un problema con la ejecución de la query. Cerrando la conexión"
    $comando.Connection.Close()
}

#Ilustración 95
try 
{
    Start-Something -Path $path -ErrorAction Stop
}
catch [System.IO.DirectoryNotFoundException], [System.IO.FileNotFoundException]
{
    Write-OutPut "El directorio o fichero no ha sido encontrado: [$path]"
}
catch [System.IO.IOException]
{
    Write-OutPut "Error de IO con el archivo: [$path]"
}

#Ilustración 96
throw "No se puede encontrar la ruta: [$path]"

throw [System.IO.FileNotFoundException] "No se puede encontrar la ruta: [$path]"

throw [System.IO.FileNotFoundException]::new

throw [System.IO.FileNotFoundException]::new("No se puede encontrar la ruta: [$path]")

throw (New-Object -TypeName System.IO.FileNotFoundException)

throw (New-Object -TypeName System.IO.FileNotFoundException -ArgumentList "No se puede encontrar la ruta: [$path]")

#Ilustración 97
trap
{
    Write-OutPut $PSItem.ToString()
}
throw [System.Exception]::new("primero")
throw [System.Exception]::new("segundo")
throw [System.Exception]::new("tercero")

#Ilustración 102
ls
Import-Module BackupRegistry

#Ilustración 103
Get-Help Backup-Registry

#Ilustración 104
Backup-Registry -Path "C:\Users\JAVI_\OneDrive\Desktop\Backup"

#Ilustración 105
vim C:\Users\JAVI_\OneDrive\Desktop\Backup\BackupRegistry.ps1
Import-Module BackupRegistry -Force
Backup-Registry -rutaBackup "C:\Users\JAVI_\OneDrive\Desktop\Backup"
ls

#Ilustración 107
ls C:\Users\JAVI_\OneDrive\Desktop\Backup
Get-Date
ls C:\Users\JAVI_\OneDrive\Desktop\Backup

#Ilustración 108
Get-ScheduledTask

#Ilustración 109
Unregister-ScheduledTask 'Ejecutar Backup del Registro del Sistema'

#Ilustración 110
Get-ScheduledTask