# smtpfunctions.ps1
# Script que contiene las funciones que se usan para la configuración del servidor

function Configurarini($lines, $section, $key, $value){

    #Esto confugrua el archivo de configuracion, si alguien pregunra ehm... un hechicero lo hizo
    $sectionIndex = $lines.IndexOf("[$section]")
    if($sectionIndex -lt 0) {
        $lines += "[$section]", "$key=$value"
    } else {
        $i = $sectionIndex + 1
        $found = $false
        while ($i -lt $lines.Length -and $lines[$i] -notmatch "^\[.*\]"){
            if ($lines[$i] -match "^$key="){
                $lines[$i] = "$key=$value"
                $found = $true
                break
            }
            $i++
        }
        if(-not $found){
            $lines = @(
                $lines[0..$sectionIndex]
                "$key=$value"
                $lines[($sectionIndex + 1)..($lines.Length - 1)]
            )
        }
    }
    return $lines
}

function instalarsquirrel{
    #Install-WindowsFeature -name Web-Server, Web-Common-Http, Web-Static-Content, Web-Default-Doc, Web-Dir-Browsing, Web-Http-Errors, Web-Http-Logging, Web-Request-Monitor, Web-Http-Redirect, Web-Filtering, Web-Performance, Web-Stat-Compression, Web-Security, Web-Mgmt-Console -IncludeManagementTools
    
    #Descargamos Xammp
    Write-Host "Para ejecutar squirrelmail se necesita un servidor http que soporte php, se utilizará xampp para esto "
    curl.exe -L "https://sourceforge.net/projects/xampp/files/XAMPP%20Windows/5.6.14/xampp-portable-win32-5.6.14-4-VC11-installer.exe/download" -o "C:\Users\Administrador\Downloads\xampp-portable-win32-5.6.14-4-VC11-installer.exe"
    Start-Process "C:\Users\Administrador\Downloads\xampp-portable-win32-5.6.14-4-VC11-installer.exe" -Wait
    
    #Descargamos squirrelmaul
    Write-Host "Descargando squirrelmail" 
    curl.exe -L "https://sourceforge.net/projects/squirrelmail/files/stable/1.4.22/squirrelmail-webmail-1.4.22.zip/download?use_mirror=psychz" -o "C:\Users\Administrador\Downloads\squirrelmail.zip"

    Expand-Archive -Path "C:\Users\Administrador\Downloads\squirrelmail.zip" -DestinationPath "C:\xampp\htdocs\"
    #Se renombra la carpeta descomprimida como squirrelmail
    Rename-Item -Path C:\xampp\htdocs\squirrelmail-webmail-1.4.22 -NewName "squirrelmail"

    #Renombramos y editamos el archivo de configuracion
    Rename-Item -Path C:\xampp\htdocs\squirrelmail\config\config_default.php -NewName "config.php"            #Aqui el dominio que se configuro en la instalacion
    (Get-Content "C:\xampp\htdocs\squirrelmail\config\config.php") -replace '\$domain\s*=\s*''[^'']+'';', '$domain = ''correoprueba.com'';' | Set-Content "C:\xampp\htdocs\squirrelmail\config\config.php"
    (Get-Content "C:\xampp\htdocs\squirrelmail\config\config.php") -replace '\$data_dir\s*=\s*''[^'']+'';', '$data_dir = ''C:/xampp/htdocs/squirrelmail/data/'';' | Set-Content "C:\xampp\htdocs\squirrelmail\config\config.php"

    
    Write-Host "Squirrelmail instalado y configardo"
    #Para probar squirrelmaul, abre xampp e inicia apache, luego ve al navegador y escribe localhots squirrelmail asegurate de tener el puerto 80 o  443 libre

}

function InstalarMercury{
    $mercuryURL = "https://download-us.pmail.com/m32-491.exe"
    $mercryFolder = "C:\Mercury"
    $installerPath = "$mercryFolder\MercuryInstall.exe"

    $inipath = "$mercryFolder\mercury.ini"
    $nssmUrls = "https://nssm.cc/release/nssm-2.24.zip"
    $nssmFolder = "$mercryFolder\nssm"

    #Creamos la carpeta de instalacion
    New-Item -ItemType Directory -Path $mercryFolder -Force | Out-Null

    #Descrgamos Mercury
    Write-Host "Descargando mercury"
    Invoke-WebRequest -Uri $mercuryURL -OutFile $installerPath

    Write-Host "Ejecutamos instalador, requiere intervencion del usuario..."
    Start-Process -FilePath $installerPath -Wait

    if (-not (Test-Path $inipath)){
        Write-Error "No se encontró el archivo de configuracion, vuelva a ejecutar el script para reinstalar el srevicio"
        exit 1 
    }

    #Se edita el archivo de configuracion
    Write-Host "Configurando Servicio"

    $content = Get-Content $inipath

    $content = Configurarini $content "MercuryS" "TCP/IP_port" "25"
    $content = Configurarini $content "MercuryP" "TCP/IP_port" "110"
    $content = Configurarini $content "MercuryP" "POP3Enabled" "1"
    $content = Configurarini $content "MercuryS" "SMTPEnabled" "1"

    $content | Set-Content $inipath

    #Start-Service Mercury32 al parecer para ejecutar como servicio esto requiere licencia 


    Start-Process "C:\Mercury\mercury.exe" #Mejor ejecutar el .exe directamente y dejar la pestaña abierta

    #Al parecer para crear usuario no hay comandos como tal, es hacerlo desde la propia app o editar archivos de configuracion dentro de C:\Mercury32\MAIL
    #Supuestamente habua un pquerño programa que podias ejecutar para añadirlos pero no lo encontré, se llama pmuser.exe

}
