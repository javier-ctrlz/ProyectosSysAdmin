# Funciones Active Directory
# Zapien Rivera Jesús Javier
# 302 IS

function InstalarAD(){
    if(-not((Get-WindowsFeature -Name AD-Domain-Services).Installed)){
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    }
    else{
        Write-Host "AD ya se encuentra instalado, omitiendo instalación" -ForegroundColor Yellow
    }
}

function ConfigurarDominioAD(){
    if((Get-WmiObject Win32_ComputerSystem).Domain -eq "pruebas.com"){
        Write-Host "El dominio ya se encuentra configurado" -ForegroundColor Yellow
    }
    else{
        Import-Module ADDSDeployment
        Install-ADDSForest -DomainName "pruebas.com" -DomainNetbiosName "PRUEBAS" -InstallDNS
        New-ADOrganizationalUnit -Name "cuates"
        New-ADOrganizationalUnit -Name "nocuates"
        Write-Host "Organizaciones creadas correctamente" -ForegroundColor Green
    }
}


function ValidarContraseña($contrasena) {
    return ($contrasena.Length -ge 8 -and
            $contrasena -match '[A-Z]' -and
            $contrasena -match '[a-z]' -and
            $contrasena -match '\d' -and
            $contrasena -match '[^a-zA-Z\d]')
}

function CrearUsuario(){
    try {
        $usuario = Read-Host "Ingresa el nombre de usuario"
        $password = Read-Host "Ingresa la contrasena"
        $organizacion = Read-Host "Ingresa la unidad organizativa de la que sera parte el usuario (cuates/nocuates)"
        if(($organizacion -ne "cuates") -and ($organizacion -ne "nocuates")){
            echo "Ingresa una unidad organizativa valida (cuates/nocuates)"
        }
        elseif(-not(ValidarContraseña -contrasena $password)){
            Write-Host "La contraseña no es segura" -ForegroundColor Yellow
        }
        else{
            New-ADUser -Name $usuario -GivenName $usuario -Surname $usuario -SamAccountName $usuario -UserPrincipalName "$usuario@pruebas.com" -Path "OU=$organizacion,DC=pruebas,DC=com" -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -Enabled $true
            Add-ADGroupMember -Identity "Administradores" -Members $usuario
            Write-Host "Usuario agregado con éxito" -ForegroundColor Green
        }
    }
    catch {
        echo $Error[0].ToString()
    }
}