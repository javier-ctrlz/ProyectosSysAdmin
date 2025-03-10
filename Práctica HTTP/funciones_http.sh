#!/bin/bash
# funciones_http.sh
# Script para funciones de gestión de instalación de servicios HTTP en Linux

# --- Funciones de Validación ---
validar_numero() {
    local numero="$1"
    if ! [[ "$numero" =~ ^[0-9]+$ ]]; then
        echo "Error: Por favor, introduce un número válido."
        return 1
    fi
    return 0
}

validar_puerto() {
    local puerto="$1"
    if ! [[ "$puerto" =~ ^[0-9]+$ ]]; then
        echo "Error: El puerto debe ser un número."
        return 1
    fi
    if (( puerto < 1 )) || (( puerto > 65535 )); then
        echo "Error: El puerto debe estar entre 1 y 65535."
        return 1
    fi
    return 0
}

verificar_puerto_en_uso() {
    local puerto="$1"
    # Usa netcat para verificar si el puerto está en uso (más robusto)
    if sudo nc -z -w 1 localhost "$puerto" ; then
        return 0 # Puerto en uso
    else
        return 1 # Puerto libre
    fi
}



obtener_puertos_disponibles() {
    local puerto_inicio=8000 # Puerto de inicio para buscar disponibles
    local puerto_fin=8100   # Puerto final para buscar disponibles
    local puertos_disponibles=()
    for ((puerto=puerto_inicio; puerto<=puerto_fin; puerto++)); do
        if verificar_puerto_en_uso "$puerto"; then
            continue # Puerto en uso, continuar al siguiente
        else
            puertos_disponibles+=("$puerto") # Puerto disponible, añadir a la lista
        fi
    done
    if [ ${#puertos_disponibles[@]} -gt 0 ]; then
        echo "Puertos disponibles sugeridos:"
        IFS=$'\n'
        echo "${puertos_disponibles[*]}"
        unset IFS
    else
        echo "No se encontraron puertos disponibles en el rango ${puerto_inicio}-${puerto_fin}."
    fi
}


# --- Funciones de Obtención de Versiones ---
obtener_versiones_nginx() {
    local url="https://nginx.org/en/download.html"
    local html=$(curl -s "$url")

    # Extraer versión LTS
    local version_lts=$(echo "$html" | grep -oP '(?s)Stable version.*?nginx-([\d\.]+)\.tar\.gz')
    version_lts=$(echo "$version_lts" | grep -oP 'nginx-([\d\.]+)\.tar\.gz')
    version_lts=$(echo "$version_lts" | grep -oP '(\d+\.)*\d+')

    # Extraer versión de desarrollo (Mainline)
    local version_dev=$(echo "$html" | grep -oP '(?s)Mainline version.*?nginx-([\d\.]+)\.tar\.gz')
    version_dev=$(echo "$version_dev" | grep -oP 'nginx-([\d\.]+)\.tar\.gz')
    version_dev=$(echo "$version_dev" | grep -oP '(\d+\.)*\d+')


    echo "NGINX version:"
    echo "1.- ${version_dev}"
    echo "2.- ${version_lts}"
    echo ""
    echo "3.- Cancelar"
}

obtener_versiones_tomcat() {
    local url_lts="https://tomcat.apache.org/download-10.cgi"
    local url_dev="https://tomcat.apache.org/download-11.cgi"
    local html_lts=$(curl -s "$url_lts")
    local html_dev=$(curl -s "$url_dev")

    # Extraer versión LTS (Tomcat 10)
    local version_lts=$(echo "$html_lts" | grep -oP '(?s)<h3 id="Tomcat_10_Software_Downloads">.*?Tomcat\s*10')
    version_lts=$(echo "$version_lts" | grep -oP 'Tomcat\s*(\d+)')
    version_lts=$(echo "$version_lts" | grep -oP '\d+')

    # Extraer versión de desarrollo (Tomcat 11)
    local version_dev=$(echo "$html_dev" | grep -oP '(?s)<h3 id="Tomcat_11_Software_Downloads">.*?Tomcat\s*11')
    version_dev=$(echo "$version_dev" | grep -oP 'Tomcat\s*(\d+)')
    version_dev=$(echo "$version_dev" | grep -oP '\d+')


    echo "TOMCAT version:"
    echo "1.- ${version_dev}"
    echo "2.- ${version_lts}"
    echo ""
    echo "3.- Cancelar"
}

obtener_versiones_ols() {
    local url="https://openlitespeed.org/downloads/"
    local html=$(curl -s "$url")

    # Extraer versión de desarrollo
    local version_dev=$(echo "$html" | grep -oP '(?s)<h6>OpenLiteSpeed\s+V\s+([\d\.]+)<\/h6>')
    version_dev=$(echo "$version_dev" | grep -oP 'OpenLiteSpeed\s+V\s+([\d\.]+)')
    version_dev=$(echo "$version_dev" | grep -oP '([\d\.]+)')

    # Extraer versión LTS
    local version_estable=$(echo "$html" | grep -oP '(?s)<h6>OpenLiteSpeed\s+V\s+([\d\.]+)\s*<small>Stable<\/small><\/h6>')
    version_estable=$(echo "$version_estable" | grep -oP 'OpenLiteSpeed\s+V\s+([\d\.]+)\s*<small>Stable<\/small>')
    version_estable=$(echo "$version_estable" | grep -oP '([\d\.]+)')


    echo "OpenLiteSpeed version:"
    echo "1.- ${version_dev}"
    echo "2.- ${version_estable}"
    echo ""
    echo "3.- Cancelar"

}

# --- Funciones de Instalación Específicas---
instalar_nginx() {
    local puerto="$1" # Recibe el puerto
    local opcion_version="$2" # Recibe la opcion de version (1 o 2)
    local version_nginx=""
    local enlace_descarga=""
    local nombre_archivo_nginx=""
    local version_dev="" # Declarar version_dev localmente
    local version_lts="" # Declarar version_lts localmente

    # Obtener versiones ACTUALES de nginx (por si acaso, aunque ya deberian estar definidas globalmente)
    version_dev=$(obtener_versiones_nginx_dev) # Asignar valor a version_dev
    version_lts=$(obtener_versiones_nginx_lts) # Asignar valor a version_lts


    case "$opcion_version" in
        1) version_nginx="${version_dev}"; nombre_archivo_nginx="nginx-${version_dev}.tar.gz";; # Usar version_dev y construir nombre_archivo aqui
        2) version_nginx="${version_lts}"; nombre_archivo_nginx="nginx-${version_lts}.tar.gz";; # Usar version_lts y construir nombre_archivo aqui
        *) echo "Opción de versión no válida para Nginx (en función interna)."; return 1;;
    esac

    local version_nginx_nombre_completo="" # Variable para el nombre completo de la versión para mensajes

    if [[ "$opcion_version" -eq 1 ]]; then
        version_nginx_nombre_completo="Mainline ${version_dev}" # Nombre completo para mensajes
    elif [[ "$opcion_version" -eq 2 ]]; then
        version_nginx_nombre_completo="Stable ${version_lts}" # Nombre completo para mensajes
    fi


    enlace_descarga="https://nginx.org/download/${nombre_archivo_nginx}" # Enlace de descarga


    echo ""
    echo "=== Instalando NGINX ${version_nginx_nombre_completo} en puerto ${puerto} ==="

    # Descargar Nginx desde nginx.org
    echo "Descargando Nginx ${version_nginx_nombre_completo} desde ${enlace_descarga}..."
    wget "$enlace_descarga" -O /tmp/"$nombre_archivo_nginx" &>/dev/null


    # Crear directorio de instalación y extraer el tar.gz
    sudo mkdir -p /opt/nginx &>/dev/null
    sudo tar -xzf /tmp/"$nombre_archivo_nginx" -C /opt/nginx --strip-components=1 &>/dev/null
    rm /tmp/"$nombre_archivo_nginx"

    #  Configurar con --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf --http-port=PUERTO
    sudo ./configure --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf --with-http_ssl_module --with-pcre &>/dev/null


    sudo make &>/dev/null
    sudo make install &>/dev/null


    cd ~ # Vuelve al directorio home


    # --- Configuración de Nginx después de la instalación (Versión 16 - Configuracion POST-instalacion) ---

    #  Crear directorio /etc/nginx si no existe (si configure --conf-path=/etc/nginx/nginx.conf)
    sudo mkdir -p /etc/nginx  &>/dev/null

    if [ ! -f /etc/nginx/nginx.conf ]; then # Solo copia si NO existe ya
        sudo cp /usr/local/nginx/conf/nginx.conf /etc/nginx/nginx.conf &>/dev/null # Copia config por defecto a /etc/nginx/nginx.conf
    fi

    sudo sed -i "s/listen[[:space:]]*80;/listen ${puerto};/g" /etc/nginx/nginx.conf &>/dev/null
    
    sudo bash -c 'cat <<EOF > /tmp/nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/local/nginx/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s TERM $MAINPID

[Install]
WantedBy=multi-user.target
EOF' &>/dev/null
    sudo mv /tmp/nginx.service /etc/systemd/system/nginx.service &>/dev/null # Mover el archivo de servicio a la ubicación correcta
    sudo systemctl daemon-reload &>/dev/null
    sudo systemctl enable nginx &>/dev/null
    sudo systemctl start nginx &>/dev/null
    sudo systemctl restart nginx &>/dev/null


    echo "Nginx ${version_nginx_nombre_completo} instalado y configurado en el puerto ${puerto}." # Mensaje final - desde codigo fuente
    echo "Instalación de NGINX ${version_nginx_nombre_completo} finalizada." # Mensaje final - con nombre version completo
    echo "======================================="
}

instalar_tomcat() {
    local opcion_version="$1" # Recibe opcion de version (1 o 2)
    local puerto="$2"        # Y puerto
    local version_tomcat=""
    local url_tomcat=""
    local version_dev="" # Declarar version_dev localmente
    local version_lts="" # Declarar version_lts localmente

    # Obtener versiones ACTUALES de Tomcat
    version_dev=$(obtener_versiones_tomcat_dev) # Asignar valor a version_dev (Tomcat 11 - desarrollo)
    version_lts=$(obtener_versiones_tomcat_lts) # Asignar valor a version_lts (Tomcat 10 - estable)


    case "$opcion_version" in
        1) version_tomcat="${version_dev}"; url_tomcat="https://tomcat.apache.org/download-$(obtener_versiones_tomcat_dev).cgi";; # Usar version_dev
        2) version_tomcat="${version_lts}"; url_tomcat="https://tomcat.apache.org/download-$(obtener_versiones_tomcat_lts).cgi";; # Usar version_lts
        *) echo "Opción de versión no válida para Tomcat (en función interna)."; return 1;; # Error interno, no deberia pasar
    esac


    echo ""
    echo "=== Instalando TOMCAT ${version_tomcat} en puerto ${puerto} ==="
    echo "Instalando Tomcat ${version_tomcat}..."

    # Obtener enlace de descarga del binario .tar.gz - asumiendo core es suficiente
    local enlace_descarga=$(curl -s "$url_tomcat" | grep -oP 'https:\/\/dlcdn\.apache\.org\/tomcat\/tomcat-\d+\/v[\d\.]+\/bin\/apache-tomcat-[\d\.]+\.tar\.gz') &>/dev/null

    if [ -z "$enlace_descarga" ]; then
        echo "Error al obtener el enlace de descarga de Tomcat." 
        return 1
    fi

    local archivo_tomcat=$(basename "$enlace_descarga") &>/dev/null
    wget "$enlace_descarga" -O "/tmp/$archivo_tomcat" &>/dev/null

    # Crear directorio de instalación
    sudo mkdir /opt/tomcat &>/dev/null
    sudo tar -xzf "/tmp/$archivo_tomcat" -C /opt/tomcat --strip-components=1 &>/dev/null
    rm "/tmp/$archivo_tomcat" &>/dev/null

    sudo sed -i "s/<Connector port=\"8080\"/<Connector port=\"${puerto}\"/" /opt/tomcat/conf/server.xml &>/dev/null

    sudo bash -c 'cat <<EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Server
After=network.target

[Service]
Type=forking
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF' &>/dev/null
    sudo mv /tmp/tomcat.service /etc/systemd/system/tomcat.service &>/dev/null
    sudo systemctl daemon-reload &>/dev/null
    sudo systemctl enable tomcat &>/dev/null
    sudo systemctl start tomcat &>/dev/null
    sudo systemctl restart tomcat &>/dev/null


    echo "Tomcat ${version_tomcat} instalado y configurado en el puerto ${puerto}."
    echo "Instalación de TOMCAT ${version_tomcat} finalizada."
    echo "======================================="
}

instalar_ols() {
    local opcion_version="$1" # Recibe opcion de version (1 o 2)
    local puerto="$2"        # Y puerto
    local version_ols=""
    local version_dev="" # Declarar version_dev localmente
    local version_estable="" # Declarar version_estable localmente


    # Obtener versiones ACTUALES de OLS
    version_dev=$(obtener_versiones_ols_dev)   # Asignar valor a version_dev (OpenLiteSpeed Mainline/Desarrollo)
    version_estable=$(obtener_versiones_ols_estable) # Asignar valor a version_estable (OpenLiteSpeed Stable/LTS)


    case "$opcion_version" in
        1) version_ols="Mainline";; #Asumiendo Mainline es desarrollo
        2) version_ols="Stable";;
        *) echo "Opción de versión no válida para OpenLiteSpeed (en función interna)."; return 1;; # Error interno, no deberia pasar
    esac


    echo ""
    echo "=== Instalando OpenLiteSpeed ${version_ols} en puerto ${puerto} ==="
    echo "Instalando OpenLiteSpeed ${version_ols}..."

    local nombre_archivo_ols_dev="v${version_dev}.tar.gz" &>/dev/null # Nombre archivo desarrollo - Versión 15 - URL GitHub Correcta
    local nombre_archivo_ols_estable="v${version_estable}.tar.gz" &>/dev/null # Nombre archivo estable - Versión 15 - URL GitHub Correcta


    # Enlaces de descarga CORRECTOS desde GITHUB (Versión 15 - URL GitHub Correcta)
    local enlace_descarga_dev="https://github.com/litespeedtech/openlitespeed/archive/refs/tags/${nombre_archivo_ols_dev}" &>/dev/null # Enlace DESARROLLO/Mainline
    local enlace_descarga_estable="https://github.com/litespeedtech/openlitespeed/archive/refs/tags/${nombre_archivo_ols_estable}" &>/dev/null # Enlace ESTABLE/LTS


    local enlace_descarga="" &>/dev/null # Variable para enlace descarga segun version seleccionada
    local nombre_archivo_ols="" &>/dev/null # Variable para nombre archivo descarga segun version seleccionada


    if [[ "$opcion_version" -eq 1 ]]; then
        enlace_descarga="$enlace_descarga_dev"
        version_ols_nombre_completo="V ${version_dev} (Mainline)" # Nombre completo para mensajes
        nombre_archivo_ols="$nombre_archivo_ols_dev" # Nombre de archivo para descarga

    elif [[ "$opcion_version" -eq 2 ]]; then
        enlace_descarga="$enlace_descarga_estable"
        version_ols_nombre_completo="V ${version_estable} (Stable)" # Nombre completo para mensajes
        nombre_archivo_ols="$nombre_archivo_ols_estable" # Nombre de archivo para descarga
    fi



    # Descargar OpenLiteSpeed
    echo "Descargando OpenLiteSpeed ${version_ols_nombre_completo} desde ${enlace_descarga}..." # Mensaje con nombre completo
    sudo wget "$enlace_descarga" -O "/tmp/$nombre_archivo_ols" &>/dev/null 


    # Crear directorio de instalación (si no existe) y extraer el tar.gz
    sudo mkdir -p /opt/openlitespeed &>/dev/null
    sudo tar -xzf "/tmp/$nombre_archivo_ols" -C /opt/openlitespeed --strip-components=1 &>/dev/null
    rm "/tmp/$nombre_archivo_ols" # Elimina el archivo tar.gz descargado de /tmp


    # Script de instalación interna de OLS 
    sudo chmod +x /opt/openlitespeed/dist/install.sh &>/dev/null
    sudo /opt/openlitespeed/dist/install.sh &>/dev/null


    # Configurar puerto
    sudo chmod +x /opt/openlitespeed/dist/admin/misc/admpass.sh &>/dev/null
    sudo /opt/openlitespeed/dist/admin/misc/admpass.sh &>/dev/null
    sudo sed -i "s/8080/${puerto}/g" /opt/openlitespeed/dist/conf/httpd_config.conf.in &>/dev/null


    echo "OpenLiteSpeed ${version_ols_nombre_completo} instalado y configurado en el puerto ${puerto}." # Mensaje con nombre completo
    echo "Instalación de OpenLiteSpeed ${version_ols} finalizada."
    echo "======================================="
}


# --- Función Genérica de Instalación de Servicio HTTP ---
instalar_servicio_http() {
    local servicio="$1" # Recibe el nombre del servicio (nginx, tomcat, ols)
    local opcion_version_servicio # Variable para guardar la opción de versión seleccionada
    local puerto_servicio # Variable para guardar el puerto seleccionado

    case "$servicio" in
        "nginx")
            obtener_versiones_nginx
            while true; do # Bucle de validación para Nginx version
                read -p "Selecciona la versión de Nginx a instalar (1-3): " opcion_version_servicio
                case "$opcion_version_servicio" in
                    1|2) break ;; # Opción 1 o 2 son válidas, sale del bucle
                    3) echo "Instalación de Nginx cancelada."; return ;; # Opción 3 cancela la instalación
                    *) echo "Opción no válida. Por favor, selecciona 1, 2 o 3.";; # Opción inválida, muestra mensaje de error
                esac
            done
            ;;
        "tomcat")
            obtener_versiones_tomcat
            while true; do # Bucle de validación para Tomcat version
                read -p "Selecciona la versión de Tomcat a instalar (1-3): " opcion_version_servicio
                case "$opcion_version_servicio" in
                    1|2) break ;; # Opción 1 o 2 son válidas, sale del bucle
                    3) echo "Instalación de Tomcat cancelada."; return ;; # Opción 3 cancela la instalación
                    *) echo "Opción no válida. Por favor, selecciona 1, 2 o 3.";; # Opción inválida, muestra mensaje de error
                esac
            done
            ;;
        "ols")
            obtener_versiones_ols
            while true; do # Bucle de validación para OpenLiteSpeed version
                read -p "Selecciona la versión de OpenLiteSpeed a instalar (1-3): " opcion_version_servicio
                case "$opcion_version_servicio" in
                    1|2) break ;; # Opción 1 o 2 son válidas, sale del bucle
                    3) echo "Instalación de OpenLiteSpeed cancelada."; return ;; # Opción 3 cancela la instalación
                    *) echo "Opción no válida. Por favor, selecciona 1, 2 o 3.";; # Opción inválida, muestra mensaje de error
                esac
            done
            ;;
        *)
            echo "Servicio no válido."
            return 1
            ;;
    esac


    while true; do
        read -p "Introduce el puerto para ${servicio}: " puerto_servicio
        if validar_puerto "$puerto_servicio"; then
            if verificar_puerto_en_uso "$puerto_servicio"; then
                echo "Puerto ${puerto_servicio} está en uso."
                obtener_puertos_disponibles
            else
                break # Puerto validado y libre, sale del bucle
            fi
        fi
    done


    # Llama a la función de instalación específica según el servicio, pasando versión y puerto
    case "$servicio" in
        "nginx")
            instalar_nginx "$puerto_servicio" "$opcion_version_servicio" ;; # Ahora SI pasa la opcion de version
        "tomcat")
            instalar_tomcat "$opcion_version_servicio" "$puerto_servicio" ;; # Pasa opcion de version y puerto
        "ols")
            instalar_ols "$opcion_version_servicio" "$puerto_servicio" ;;   # Pasa opcion de version y puerto
    esac

}



# Funciones auxiliares para obtener versiones (para asegurar que esten definidas en el scope)
obtener_versiones_nginx_dev() {
    local url="https://nginx.org/en/download.html"
    local html=$(curl -s "$url")
    local version_dev=$(echo "$html" | grep -oP '(?s)Mainline version.*?nginx-([\d\.]+)\.tar\.gz')
    version_dev=$(echo "$version_dev" | grep -oP 'nginx-([\d\.]+)\.tar\.gz')
    version_dev=$(echo "$version_dev" | grep -oP '(\d+\.)*\d+')
    echo "$version_dev"
}

obtener_versiones_nginx_lts() {
    local url="https://nginx.org/en/download.html"
    local html=$(curl -s "$url")
    local version_lts=$(echo "$html" | grep -oP '(?s)Stable version.*?nginx-([\d\.]+)\.tar\.gz')
    version_lts=$(echo "$version_lts" | grep -oP 'nginx-([\d\.]+)\.tar\.gz')
    version_lts=$(echo "$version_lts" | grep -oP '(\d+\.)*\d+')
    echo "$version_lts"
}

obtener_versiones_tomcat_dev() {
    local url_dev="https://tomcat.apache.org/download-11.cgi"
    local html_dev=$(curl -s "$url_dev")
    local version_dev=$(echo "$html_dev" | grep -oP '(?s)<h3 id="Tomcat_11_Software_Downloads">.*?Tomcat\s*11')
    version_dev=$(echo "$version_dev" | grep -oP 'Tomcat\s*(\d+)')
    version_dev=$(echo "$version_dev" | grep -oP '\d+')
    echo "$version_dev"
}

obtener_versiones_tomcat_lts() {
    local url_lts="https://tomcat.apache.org/download-10.cgi"
    local html_lts=$(curl -s "$url_lts")
    local version_lts=$(echo "$html_lts" | grep -oP '(?s)<h3 id="Tomcat_10_Software_Downloads">.*?Tomcat\s*10')
    version_lts=$(echo "$version_lts" | grep -oP 'Tomcat\s*(\d+)')
    version_lts=$(echo "$version_lts" | grep -oP '\d+')
    echo "$version_lts"
}

obtener_versiones_ols_dev() {
    local url="https://openlitespeed.org/downloads/"
    local html=$(curl -s "$url")
    local version_dev=$(echo "$html" | grep -oP '(?s)<h6>OpenLiteSpeed\s+V\s+([\d\.]+)<\/h6>')
    version_dev=$(echo "$version_dev" | grep -oP 'OpenLiteSpeed\s+V\s+([\d\.]+)')
    version_dev=$(echo "$version_dev" | grep -oP '([\d\.]+)')
    echo "$version_dev"
}

obtener_versiones_ols_estable() {
    local url="https://openlitespeed.org/downloads/"
    local html=$(curl -s "$url")
    local version_estable=$(echo "$html" | grep -oP '(?s)<h6>OpenLiteSpeed\s+V\s+([\d\.]+)\s*<small>Stable<\/small><\/h6>')
    version_estable=$(echo "$version_estable" | grep -oP 'OpenLiteSpeed\s+V\s+([\d\.]+)\s*<small>Stable<\/small>')
    version_estable=$(echo "$version_estable" | grep -oP '([\d\.]+)')
    echo "$version_estable"
}
