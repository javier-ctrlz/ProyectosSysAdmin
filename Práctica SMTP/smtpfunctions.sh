#!/bin/bash
# Archivo de funciones SMTP
# Zapién Rivera Jesús Javier
# 302 IS

function InstallServices {
    echo "Comprobando instalación de Postfix y Dovecot..."

    if dpkg -l | grep -q postfix; then
        echo "Postfix ya está instalado"
    else
        sudo apt-get install -y postfix
    fi

    if dpkg -l | grep -q dovecot-core; then
        echo "Dovecot ya está instalado."
    else
        sudo apt-get install -y dovecot-imapd dovecot-pop3d
    fi
}

function ConfigureDomain {
    echo "Configurando dominio..."
    while true; do
        read -p "Ingrese un nombre de dominio: " domainName
        if [[ -z "$domainName" || "$domainName" =~ \  ]]; then
            echo "El nombre no puede tener espacios en blanco ni ser nulo."
        else
            break
        fi
    done

    if grep -q "$domainName" /etc/postfix/main.cf; then
        echo "El dominio $domainName ya está configurado en Postfix"
    else
        echo "Agregando dominio $domainName a Postfix..."
        sudo sed -i "/^mydestination/ s/$/, $domainName/" /etc/postfix/main.cf
        sudo systemctl reload postfix
        echo "Dominio configurado y Postfix recargado."
    fi
}

function ConfigureUser {
    local username
    while true; do
        read -p "Ingrese su nombre de usuario: " username
        if [[ -z "$username" || "$username" =~ \  ]]; then
            echo "El nombre no puede tener espacios en blanco ni ser nulo."
        else
            break
        fi
    done

    local password
    read -s -p "Ingrese una contraseña: " password
    echo

    if id "$username" &>/dev/null; then
        echo "El usuario $username ya existe."
    else
        sudo useradd -m -s /bin/false "$username"
        echo "$username:$password" | sudo chpasswd
        echo "Usuario $username creado con éxito."
    fi

    MAILBOX="/var/mail/$username"
    if [ ! -f "$MAILBOX" ]; then
        sudo touch "$MAILBOX"
        sudo chown "$username":mail "$MAILBOX"
        sudo chmod 644 "$MAILBOX"
        echo "Buzón creado para el usuario $username."
    else
        echo "El buzón ya existe para el usuario $username."
    fi
}

function ConfigureSquirrelMail {
    echo "Iniciando la configuración de SquirrelMail..."
    echo "Se instalarán PHP, Apache y dependencias necesarias."

    # Instalar repositorio de PHP y paquetes requeridos
    #sudo apt install software-properties-common -y
    #sudo add-apt-repository ppa:ondrej/php -y
    #sudo apt update
    #sudo apt install php7.4 libapache2-mod-php7.4 php-mysql -y

    # Solicitar el dominio que se usará en la configuración de SquirrelMail
    while true; do
        read -p "Ingrese el dominio para SquirrelMail (sin espacios): " dominio
        if [[ -z "$dominio" || "$dominio" =~ \  ]]; then
            echo "El dominio no puede estar vacío ni contener espacios."
        else
            break
        fi
    done

    # Establecer rutas para los directorios de datos y archivos adjuntos
    data_directory="/var/www/html/squirrelmail/data/"
    attach_directory="/var/www/html/squirrelmail/attach/"

    # Ruta de instalación de SquirrelMail
    install_dir="/var/www/html/squirrelmail"

    # Descargar y extraer SquirrelMail
    cd /var/www/html/
    wget -O squirrelmail.zip "https://sourceforge.net/projects/squirrelmail/files/stable/1.4.22/squirrelmail-webmail-1.4.22.zip/download" -q
    if [ $? -ne 0 ]; then
        echo "Error al descargar SquirrelMail."
        return 1
    fi
    unzip -q squirrelmail.zip
    sudo mv squirrelmail-webmail-1.4.22 squirrelmail
    rm squirrelmail.zip

    # Ajustar permisos y propiedad para Apache
    sudo chown -R www-data:www-data "$install_dir/"
    sudo chmod -R 755 "$install_dir/"

    # Modificar configuración de SquirrelMail (archivo config_default.php)
    config_file="$install_dir/config/config_default.php"
    if [ ! -f "$config_file" ]; then
        echo "No se encontró $config_file. Verifique la instalación de SquirrelMail."
        return 1
    fi

    sudo sed -i "s/^\$domain.*/\$domain = '$dominio';/" "$config_file"
    sudo sed -i "s|^\$data_dir.*| \$data_dir = '$data_directory';|" "$config_file"
    sudo sed -i "s|^\$attachment_dir.*| \$attachment_dir = '$attach_directory';|" "$config_file"
    sudo sed -i "s/^\$allow_server_sort.*/\$allow_server_sort = true;/" "$config_file"

    # Ejecutar el script de configuración interactivo de SquirrelMail de forma automatizada
    echo -e "s\n\nq" | perl "$install_dir/config/conf.pl"

    # Reiniciar Apache para aplicar cambios
    sudo systemctl reload apache2
    sudo systemctl restart apache2

    echo "SquirrelMail ha sido configurado exitosamente. Acceda mediante http://$dominio o la IP del servidor."
}

