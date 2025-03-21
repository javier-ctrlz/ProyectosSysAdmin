#!/bin/bash
# funciones_http.sh
# Script para funciones de gestión de instalación de servicios HTTP en Linux

FUENTE_DESCARGA=${INSTALACION_FUENTE:-online}

FTP_BASE_URL="ftp://localhost/"

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

    # Verificar que el puerto sea numérico
    if ! [[ "$puerto" =~ ^[0-9]+$ ]]; then
        echo "Error: El puerto debe ser un número."
        return 1
    fi

    # Verificar que el puerto esté en el rango permitido (1-65535)
    if (( puerto < 1 || puerto > 65535 )); then
        echo "Error: El puerto debe estar entre 1 y 65535."
        return 1
    fi

    # Lista de puertos inseguros
    local unsafePorts=(1 7 9 11 13 17 19 20 21 22 23 25 37 42 53 69 77 79 87 95 101 102 103 104 109 110 111 113 115 117 119 123 135 137 138 139 143 161 162 171 179 194 389 427 465 512 513 514 515 526 530 531 532 540 548 554 556 563 587 601 636 993 995 2049 3659 4045 6000 6001 6002 6003 6004 6005 6006 6007 6008 6009 6010 6011 6012 6013 6014 6015 6016 6017 6018 6019 6020 6021 6022 6023 6024 6025 6026 6027 6028 6029 6030 6031 6032 6033 6034 6035 6036 6037 6038 6039 6040 6041 6042 6043 6044 6045 6046 6047 6048 6049 6050 6051 6052 6053 6054 6055 6056 6057 6058 6059 6060 6061 6062 6063 6665 6666 6667 6668 6669)

    # Comprobar si el puerto está en la lista de puertos inseguros
    for unsafe in "${unsafePorts[@]}"; do
        if (( puerto == unsafe )); then
            echo "Error: El puerto $puerto está bloqueado por seguridad en navegadores. Elija otro."
            return 1
        fi
    done

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
    local url="https://tomcat.apache.org/index.html"
    local html=$(curl -s "$url")

    # Extraer todas las versiones disponibles
    local versiones=($(echo "$html" | grep -oP '(?<=<h3 id="Tomcat_)\d+\.\d+\.\d+'))

    if [[ ${#versiones[@]} -ge 2 ]]; then
        local version_lts="${versiones[0]}"   # La primera coincidencia es la LTS
        local version_dev="${versiones[-1]}"  # La última coincidencia es la de desarrollo
    else
        echo "No se pudieron obtener las versiones de Tomcat."
        return
    fi

    echo "TOMCAT version:"
    echo "1.- ${version_dev}"
    echo "2.- ${version_lts}"
    echo ""
    echo "3.- Cancelar"
}
# LIGHTTPD
obtener_versiones_lighttpd() {
    local url="https://www.lighttpd.net/releases/index.html"
    local html
    html=$(curl -s "$url")
    local versions=($(echo "$html" | grep -oP '<li><a href="[^"]*">[0-9]+\.[0-9]+\.[0-9]+' | sed 's/.*">//'))
    if [ ${#versions[@]} -lt 2 ]; then
        echo "No se pudieron obtener las versiones de Lighttpd."
        return 1
    fi
    local version_latest="${versions[0]}"
    local version_stable="${versions[1]}"
    
    echo "Lighttpd version:"
    echo "1.- ${version_latest}"
    echo "2.- ${version_stable}"
    echo ""
    echo "3.- Cancelar"
}

# --- Funciones de Instalación Específicas ---

instalar_nginx() {
    local puerto="$1"            # Recibe el puerto
    local opcion_version="$2"    # Recibe la opción de versión (1 o 2)
    local ssl="$3"             # Recibe opción de instalación segura (SSL)
    local version_nginx=""
    local enlace_descarga=""
    local nombre_archivo_nginx=""
    local version_dev=""
    local version_lts=""

    # Obtener versiones actuales de Nginx
    version_dev=$(obtener_versiones_nginx_dev)
    version_lts=$(obtener_versiones_nginx_lts)

    case "$opcion_version" in
        1) version_nginx="${version_dev}"; nombre_archivo_nginx="nginx-${version_dev}.tar.gz";;
        2) version_nginx="${version_lts}"; nombre_archivo_nginx="nginx-${version_lts}.tar.gz";;
        *) echo "Opción de versión no válida para Nginx (en función interna)."; return 1;;
    esac

    local version_nginx_nombre_completo=""
    if [[ "$opcion_version" -eq 1 ]]; then
        version_nginx_nombre_completo="Mainline ${version_dev}"
    elif [[ "$opcion_version" -eq 2 ]]; then
        version_nginx_nombre_completo="Stable ${version_lts}"
    fi

    if [[ "$FUENTE_DESCARGA" == "ftp" ]]; then
        enlace_descarga="${FTP_BASE_URL}nginx/${nombre_archivo_nginx}"
    else
        enlace_descarga="https://nginx.org/download/${nombre_archivo_nginx}"
    fi

    echo ""
    echo "=== Instalando NGINX ${version_nginx_nombre_completo} en puerto ${puerto} ==="
    echo "Descargando NGINX ${version_nginx_nombre_completo} desde ${enlace_descarga}..."
    wget "$enlace_descarga" -O /tmp/"$nombre_archivo_nginx" &>/dev/null

    # Crear directorio de instalación y extraer el tar.gz
    sudo mkdir -p /opt/nginx &>/dev/null
    sudo tar -xzf /tmp/"$nombre_archivo_nginx" -C /opt/nginx --strip-components=1 &>/dev/null
    sudo rm /tmp/"$nombre_archivo_nginx"

    # Cambiar al directorio de compilación
    cd /opt/nginx || { echo "No se pudo acceder a /opt/nginx"; return 1; }

    # Compilar e instalar Nginx, indicando que su configuración se ubique en /etc/nginx/nginx.conf
    sudo ./configure --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf --with-http_ssl_module --with-pcre &>/dev/null
    
    sudo make &>/dev/null
    sudo make install &>/dev/null

    cd ~ # Vuelve al directorio home

    # --- Configuración de Nginx después de la instalación ---

    # Asegurar que exista el directorio /etc/nginx
    sudo mkdir -p /etc/nginx &>/dev/null

    # Forzar la copia de la configuración por defecto a /etc/nginx/nginx.conf (sobrescribe cualquier configuración anterior)
    sudo cp -f /usr/local/nginx/conf/nginx.conf /etc/nginx/nginx.conf &>/dev/null

    # Modificar el puerto en /etc/nginx/nginx.conf
    if [[ "$ssl" == "true" ]]; then
        echo "Configurando SSL para Nginx..."
        # Generar certificado autofirmado
        sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -subj "/CN=localhost" \
            -keyout /etc/nginx/selfsigned.key \
            -out /etc/nginx/selfsigned.crt
        # Realizar backup del archivo de configuración original
        sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
sudo bash -c "cat > /etc/nginx/nginx.conf" <<EOF

#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    server {
    #    listen ${puerto};
    #    server_name  localhost;
        
        location / {
            root   html;
            index  index.html index.htm;
            }

    #    #charset koi8-r;

    #    #access_log  logs/host.access.log  main;

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen ${puerto};
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    server {
        listen ${puerto} ssl;
        server_name localhost;
        ssl_certificate /etc/nginx/selfsigned.crt;
        ssl_certificate_key /etc/nginx/selfsigned.key;
    }

}
EOF
        sudo systemctl restart nginx &>/dev/null
        echo "SSL configurado para Nginx. Ahora redirige de HTTP a HTTPS en el puerto ${puerto}."
 else
 sudo bash -c "cat > /etc/nginx/nginx.conf" <<EOF

#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    server {
        listen ${puerto};
        server_name  localhost;
        

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }


    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen ${puerto};
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #
    #server {
        #server_name localhost;
        #ssl_certificate /etc/nginx/selfsigned.crt;
        #ssl_certificate_key /etc/nginx/selfsigned.key;
    #}

}
EOF
    fi

    sudo bash -c 'cat <<EOF > /tmp/nginx.service
[Unit]
Description=nginx - high performance web server
Documentation=https://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /etc/nginx/nginx.conf
ExecStart=/usr/local/nginx/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s TERM \$MAINPID

[Install]
WantedBy=multi-user.target
EOF' &>/dev/null

    sudo mv /tmp/nginx.service /etc/systemd/system/nginx.service &>/dev/null
    sudo systemctl daemon-reload &>/dev/null
    sudo systemctl enable nginx &>/dev/null
    sudo systemctl start nginx &>/dev/null
    sudo systemctl restart nginx &>/dev/null
    unset DESCARGADO

    echo "Nginx ${version_nginx_nombre_completo} instalado y configurado en el puerto ${puerto}."
    echo "Instalación de NGINX ${version_nginx_nombre_completo} finalizada."
    echo "======================================="
}

instalar_tomcat() {
    local opcion_version="$1" # Recibe opción de versión (1 o 2)
    local puerto="$2"         # Recibe el puerto
    local ssl="$3"            # Recibe opción SSL
    local version_tomcat=""

    # Obtener versiones desde la página principal de Tomcat
    local html=$(curl -s "https://tomcat.apache.org/index.html")
    local versiones=($(echo "$html" | grep -oP '(?<=<h3 id="Tomcat_)\d+\.\d+\.\d+'))

    if [[ ${#versiones[@]} -ge 2 ]]; then
        local version_lts="${versiones[0]}"    # Primera coincidencia = LTS
        local version_dev="${versiones[-1]}"   # Última coincidencia = Desarrollo
    else
        echo "No se pudieron obtener las versiones de Tomcat."
        return 1
    fi

    case "$opcion_version" in
        1) version_tomcat="${version_dev}";;
        2) version_tomcat="${version_lts}";;
        *) echo "Opción de versión no válida para Tomcat."; return 1;;
    esac

    # Extraer el número mayor de la versión (ejemplo: "11" de "11.0.14")
    local bercion=$(echo "$version_tomcat" | cut -d'.' -f1)

    # Construir el enlace de descarga basado en la versión obtenida
    local enlace_descarga=""
    if [[ "$FUENTE_DESCARGA" == "ftp" ]]; then
        enlace_descarga="${FTP_BASE_URL}tomcat/apache-tomcat-${version_tomcat}.tar.gz"
    else
        enlace_descarga="https://dlcdn.apache.org/tomcat/tomcat-${bercion}/v${version_tomcat}/bin/apache-tomcat-${version_tomcat}.tar.gz"
    fi

    echo ""
    echo "=== Instalando TOMCAT ${version_tomcat} en puerto ${puerto} ==="
    echo "Descargando Tomcat desde: ${enlace_descarga}"

    # Descargar Tomcat
    local archivo_tomcat="/tmp/apache-tomcat-${version_tomcat}.tar.gz"
    wget "$enlace_descarga" -O "$archivo_tomcat" &>/dev/null

    if [ ! -f "$archivo_tomcat" ]; then
        echo "Error al descargar Tomcat."
        return 1
    fi

    # Crear directorio de instalación
    sudo mkdir -p /opt/tomcat &>/dev/null
    sudo tar -xzf "$archivo_tomcat" -C /opt/tomcat --strip-components=1 &>/dev/null
    sudo rm "$archivo_tomcat" &>/dev/null

    # Configurar puerto en server.xml
    if [[ "$ssl" == "true" ]]; then
    sudo $JAVA_HOME/bin/keytool -genkey -alias tomcat -keyalg RSA -keystore /opt/tomcat/conf/tomcat.keystore -storepass changeit -keypass changeit -dname "CN=localhost, OU=IT, O=zapien, L=Mochis, S=Ahome, C=ES"
    	
    	
    	sudo bash -c "cat > /opt/tomcat/conf/server.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<!-- Note:  A "Server" is not itself a "Container", so you may not
     define subcomponents such as "Valves" at this level.
     Documentation at /docs/config/server.html
 -->
<Server port="8005" shutdown="SHUTDOWN">
  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <!-- Security listener. Documentation at /docs/config/listeners.html
  <Listener className="org.apache.catalina.security.SecurityListener" />
  -->
  <!-- OpenSSL support using Tomcat Native -->
  <Listener className="org.apache.catalina.core.AprLifecycleListener" />
  <!-- OpenSSL support using FFM API from Java 22 -->
  <!-- <Listener className="org.apache.catalina.core.OpenSSLLifecycleListener" /> -->
  <!-- Prevent memory leaks due to use of particular java/javax APIs-->
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />

  <!-- Global JNDI resources
       Documentation at /docs/jndi-resources-howto.html
  -->
  <GlobalNamingResources>
    <!-- Editable user database that can also be used by
         UserDatabaseRealm to authenticate users
    -->
    <Resource name="UserDatabase" auth="Container"
              type="org.apache.catalina.UserDatabase"
              description="User database that can be updated and saved"
              factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
              pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>

  <!-- A "Service" is a collection of one or more "Connectors" that share
       a single "Container" Note:  A "Service" is not itself a "Container",
       so you may not define subcomponents such as "Valves" at this level.
       Documentation at /docs/config/service.html
   -->
  <Service name="Catalina">

    <!--The connectors can use a shared executor, you can define one or more named thread pools-->
    <!--
    <Executor name="tomcatThreadPool" namePrefix="catalina-exec-"
        maxThreads="150" minSpareThreads="4"/>
    -->


    <!-- A "Connector" represents an endpoint by which requests are received
         and responses are returned. Documentation at :
         HTTP Connector: /docs/config/http.html
         AJP  Connector: /docs/config/ajp.html
         Define a non-SSL/TLS HTTP/1.1 Connector on port 8080
    -->
    <!--
    <Connector port="${puerto}" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="${puerto}" />
    -->
    <!-- A "Connector" using the shared thread pool-->
    <!--
    <Connector executor="tomcatThreadPool"
               port="${puerto}" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
    -->
    <!-- Define an SSL/TLS HTTP/1.1 Connector on port 8443 with HTTP/2
         This connector uses the NIO implementation. The default
         SSLImplementation will depend on the presence of the APR/native
         library and the useOpenSSL attribute of the AprLifecycleListener.
         Either JSSE or OpenSSL style configuration may be used regardless of
         the SSLImplementation selected. JSSE style configuration is used below.
    -->
   
   <Connector
    protocol="org.apache.coyote.http11.Http11NioProtocol"
    port="${puerto}"
    maxThreads="150"
    SSLEnabled="true"
    scheme="https"
    secure="true">
  <SSLHostConfig>
    <Certificate
      certificateKeystoreFile="/opt/tomcat/conf/tomcat.keystore"
      certificateKeystorePassword="changeit"
      type="RSA" />
  </SSLHostConfig>
</Connector>

    <!-- Define an AJP 1.3 Connector on port 8009 -->
    <!--
    <Connector protocol="AJP/1.3"
               address="::1"
               port="8009"
               redirectPort="8443" />
    -->

    <!-- An Engine represents the entry point (within Catalina) that processes
         every request.  The Engine implementation for Tomcat stand alone
         analyzes the HTTP headers included with the request, and passes them
         on to the appropriate Host (virtual host).
         Documentation at /docs/config/engine.html -->

    <!-- You should set jvmRoute to support load-balancing via AJP ie :
    <Engine name="Catalina" defaultHost="localhost" jvmRoute="jvm1">
    -->
    <Engine name="Catalina" defaultHost="localhost">

      <!--For clustering, please take a look at documentation at:
          /docs/cluster-howto.html  (simple how to)
          /docs/config/cluster.html (reference documentation) -->
      <!--
      <Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster"/>
      -->

      <!-- Use the LockOutRealm to prevent attempts to guess user passwords
           via a brute-force attack -->
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <!-- This Realm uses the UserDatabase configured in the global JNDI
             resources under the key "UserDatabase".  Any edits
             that are performed against this UserDatabase are immediately
             available for use by the Realm.  -->
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>

      <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">

        <!-- SingleSignOn valve, share authentication between web applications
             Documentation at: /docs/config/valve.html -->
        <!--
        <Valve className="org.apache.catalina.authenticator.SingleSignOn" />
        -->

        <!-- Access log processes all example.
             Documentation at: /docs/config/valve.html
             Note: The pattern used is equivalent to using pattern="common" -->
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log" suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />

      </Host>
    </Engine>
  </Service>
</Server>
EOF
echo "SSL configurado para Tomcat"
else
sudo bash -c "cat > /opt/tomcat/conf/server.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<!-- Note:  A "Server" is not itself a "Container", so you may not
     define subcomponents such as "Valves" at this level.
     Documentation at /docs/config/server.html
 -->
<Server port="8005" shutdown="SHUTDOWN">
  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <!-- Security listener. Documentation at /docs/config/listeners.html
  <Listener className="org.apache.catalina.security.SecurityListener" />
  -->
  <!-- OpenSSL support using Tomcat Native -->
  <Listener className="org.apache.catalina.core.AprLifecycleListener" />
  <!-- OpenSSL support using FFM API from Java 22 -->
  <!-- <Listener className="org.apache.catalina.core.OpenSSLLifecycleListener" /> -->
  <!-- Prevent memory leaks due to use of particular java/javax APIs-->
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />

  <!-- Global JNDI resources
       Documentation at /docs/jndi-resources-howto.html
  -->
  <GlobalNamingResources>
    <!-- Editable user database that can also be used by
         UserDatabaseRealm to authenticate users
    -->
    <Resource name="UserDatabase" auth="Container"
              type="org.apache.catalina.UserDatabase"
              description="User database that can be updated and saved"
              factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
              pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>

  <!-- A "Service" is a collection of one or more "Connectors" that share
       a single "Container" Note:  A "Service" is not itself a "Container",
       so you may not define subcomponents such as "Valves" at this level.
       Documentation at /docs/config/service.html
   -->
  <Service name="Catalina">

    <!--The connectors can use a shared executor, you can define one or more named thread pools-->
    <!--
    <Executor name="tomcatThreadPool" namePrefix="catalina-exec-"
        maxThreads="150" minSpareThreads="4"/>
    -->


    <!-- A "Connector" represents an endpoint by which requests are received
         and responses are returned. Documentation at :
         HTTP Connector: /docs/config/http.html
         AJP  Connector: /docs/config/ajp.html
         Define a non-SSL/TLS HTTP/1.1 Connector on port 8080
    -->
    <Connector port="${puerto}" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
    <!-- A "Connector" using the shared thread pool-->
    <!--
    <Connector executor="tomcatThreadPool"
               port="${puerto}" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
    -->
    <!-- Define an SSL/TLS HTTP/1.1 Connector on port 8443 with HTTP/2
         This connector uses the NIO implementation. The default
         SSLImplementation will depend on the presence of the APR/native
         library and the useOpenSSL attribute of the AprLifecycleListener.
         Either JSSE or OpenSSL style configuration may be used regardless of
         the SSLImplementation selected. JSSE style configuration is used below.
    -->
    <!--
    <Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
               maxThreads="150" SSLEnabled="true">
        <UpgradeProtocol className="org.apache.coyote.http2.Http2Protocol" />
        <SSLHostConfig>
            <Certificate certificateKeystoreFile="conf/localhost-rsa.jks"
                         certificateKeystorePassword="changeit" type="RSA" />
        </SSLHostConfig>
    </Connector>
    -->

    <!-- Define an AJP 1.3 Connector on port 8009 -->
    <!--
    <Connector protocol="AJP/1.3"
               address="::1"
               port="8009"
               redirectPort="8443" />
    -->

    <!-- An Engine represents the entry point (within Catalina) that processes
         every request.  The Engine implementation for Tomcat stand alone
         analyzes the HTTP headers included with the request, and passes them
         on to the appropriate Host (virtual host).
         Documentation at /docs/config/engine.html -->

    <!-- You should set jvmRoute to support load-balancing via AJP ie :
    <Engine name="Catalina" defaultHost="localhost" jvmRoute="jvm1">
    -->
    <Engine name="Catalina" defaultHost="localhost">

      <!--For clustering, please take a look at documentation at:
          /docs/cluster-howto.html  (simple how to)
          /docs/config/cluster.html (reference documentation) -->
      <!--
      <Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster"/>
      -->

      <!-- Use the LockOutRealm to prevent attempts to guess user passwords
           via a brute-force attack -->
      <Realm className="org.apache.catalina.realm.LockOutRealm">
        <!-- This Realm uses the UserDatabase configured in the global JNDI
             resources under the key "UserDatabase".  Any edits
             that are performed against this UserDatabase are immediately
             available for use by the Realm.  -->
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>

      <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">

        <!-- SingleSignOn valve, share authentication between web applications
             Documentation at: /docs/config/valve.html -->
        <!--
        <Valve className="org.apache.catalina.authenticator.SingleSignOn" />
        -->

        <!-- Access log processes all example.
             Documentation at: /docs/config/valve.html
             Note: The pattern used is equivalent to using pattern="common" -->
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log" suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />

      </Host>
    </Engine>
  </Service>
</Server>
EOF

fi

    # Crear servicio systemd para Tomcat
    sudo bash -c "cat > /etc/systemd/system/tomcat.service" <<EOF
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
EOF

    echo "Tomcat ${version_tomcat} instalado y configurado en el puerto ${puerto}."
    echo "======================================="

        
    sudo systemctl daemon-reload &>/dev/null
    sudo systemctl enable tomcat &>/dev/null
    sudo systemctl start tomcat &>/dev/null
    sudo systemctl restart tomcat &>/dev/null
    unset DESCARGADO
}



instalar_lighttpd() {
    local opcion_version="$1"
    local puerto="$2"
    local versionLIGHTTPD=""
    local home_dir=$(eval echo ~$USER) # Get the home directory
    
    sudo pkill lighttpd

    if [ "$opcion_version" -eq 1 ]; then
        versionLIGHTTPD=$(obtener_versiones_lighttpd_latest)
    elif [ "$opcion_version" -eq 2 ]; then
        versionLIGHTTPD=$(obtener_versiones_lighttpd_stable)
    else
        echo "Opción de versión no válida para Lighttpd."
        return 1
    fi

    echo ""
    echo "=== Instalando LIGHTTPD ${versionLIGHTTPD} en puerto ${puerto} ==="
    echo "Por favor espere..."

    local nombre_archivo="lighttpd-${versionLIGHTTPD}.tar.gz"
    local url_descarga=""
    if [[ "$FUENTE_DESCARGA" == "ftp" ]]; then
        url_descarga="${FTP_BASE_URL}lighttpd/lighttpd-${versionLIGHTTPD}.tar.gz"
    else
        url_descarga="https://download.lighttpd.net/lighttpd/releases-1.4.x/${nombre_archivo}"
    fi

    if ! wget "$url_descarga" -O "$nombre_archivo" &>/dev/null; then
        echo "Error al descargar Lighttpd desde ${url_descarga}."
        return 1
    fi

    sudo tar -xvzf "$nombre_archivo" > /dev/null 2>&1
    local directorio_lighttpd="lighttpd-${versionLIGHTTPD}"
    cd "$directorio_lighttpd" || { echo "No se pudo acceder al directorio de Lighttpd"; return 1; }

    echo "Ejecutando autogen.sh..."
    sudo bash autogen.sh &>/dev/null

    echo "Ejecutando configure"
    ./configure --prefix=/usr/local/lighttpd --with-openssl > /dev/null

    echo "Ejecutando make..."
    make -j$(nproc) &>/dev/null

    echo "Ejecutando make install..."
    sudo make install &>/dev/null

    /usr/local/lighttpd/sbin/lighttpd -v &>/dev/null
 
    local rutaArchivoConfiguracion="/etc/lighttpd/lighttpd.conf"
    sudo install -Dp "doc/config/lighttpd.conf" "$rutaArchivoConfiguracion" &>/dev/null
    sudo cp -R "doc/config/conf.d/" /etc/lighttpd/
    sudo cp "doc/config/conf.d/mod.template" /etc/lighttpd/modules.conf

    echo "--- Modificando la configuración del puerto ---" # Línea de depuración

    # Corregir permisos del log de acceso
    sudo chown lighttpd:lighttpd /var/log/lighttpd
    sudo chmod 755 /var/log/lighttpd # Dar permisos de lectura, escritura y ejecución al propietario
    
    if [[ "$ssl" == "true" ]]; then
    local https_port
        https_port=$((puerto+1))
        echo "Configurando HTTPS en el puerto ${https_port} y redirigiendo HTTP a HTTPS..."
        
        # Reescribir el archivo de configuración completo para incluir HTTPS y redirección
    	sudo bash -c "cat > /etc/lighttpd/lighttpd.conf" <<EOF
#######################################################################
##
## /etc/lighttpd/lighttpd.conf
##
## check /etc/lighttpd/conf.d/*.conf for the configuration of modules.
##
#######################################################################

#######################################################################
##
## Some Variable definition which will make chrooting easier.
##
## if you add a variable here. Add the corresponding variable in the
## chroot example as well.
##
var.log_root    = "/var/log/lighttpd"
var.server_root = "/srv/www"
var.state_dir   = "/run"
var.home_dir    = "/var/lib/lighttpd"
var.conf_dir    = "/etc/lighttpd"

## 
## run the server chrooted.
## 
## This requires root permissions during startup.
##
## If you run chroot'ed, set the variables to directories relative to
## the chroot dir.
##
## example chroot configuration:
## 
#var.log_root    = "/logs"
#var.server_root = "/"
#var.state_dir   = "/run"
#var.home_dir    = "/lib/lighttpd"
#var.vhosts_dir  = "/vhosts"
#var.conf_dir    = "/etc"
#
#server.chroot   = "/srv/www"

##
## Some additional variables to make the configuration easier
##

##
## Base directory for all virtual hosts
##
## used in:
## conf.d/evhost.conf
## conf.d/simple_vhost.conf
## vhosts.d/vhosts.template
##
var.vhosts_dir  = server_root + "/vhosts"

##
## Cache for mod_deflate
##
## used in:
## conf.d/deflate.conf
##
var.cache_dir   = "/var/cache/lighttpd"

##
## Base directory for sockets.
##
## used in:
## conf.d/fastcgi.conf
## conf.d/scgi.conf
##
var.socket_dir  = home_dir + "/sockets"

##
#######################################################################

#######################################################################
##
## Load the modules.
include conf_dir + "/modules.conf"

##
#######################################################################

#######################################################################
##
##  Basic Configuration
## ---------------------
##
server.port = ${puerto}
\$SERVER["socket"] == ":$puerto" {
    ssl.engine = "enable"
    ssl.pemfile = "/etc/lighttpd/certs/lighttpd.pem"
}

##
## bind to a specific IP
## (default: "*" for all local IPv4 interfaces)
##
#server.bind = "localhost"

##
## Run as a different username/groupname.
## This requires root permissions during startup. 
##
server.username  = "lighttpd"
server.groupname = "lighttpd"

##
## Enable lighttpd to serve requests on sockets received from systemd
## https://www.freedesktop.org/software/systemd/man/systemd.socket.html
##
#server.systemd-socket-activation = "enable"

## 
## enable core files.
##
#server.core-files = "disable"

##
## Document root
##
server.document-root = server_root + "/htdocs"

##
## The value for the "Server:" response field.
##
## It would be nice to keep it at "lighttpd".
##
#server.tag = "lighttpd"

##
## store a pid file
##
server.pid-file = state_dir + "/lighttpd.pid"

##
#######################################################################

#######################################################################
##
##  Logging Options
## ------------------
##
## all logging options can be overwritten per vhost.
##
## Path to the error log file
##
server.errorlog = "/tmp/lighttpd_error.log"

##
## If you want to log to syslog you have to unset the 
## server.errorlog = "/tmp/lighttpd_error.log"
##
#server.errorlog = "/tmp/lighttpd_error.log"

##
## Access log config
## 
include conf_dir + "/conf.d/access_log.conf"

##
## The debug options are moved into their own file.
## see conf.d/debug.conf for various options for request debugging.
##
include conf_dir + "/conf.d/debug.conf"

##
#######################################################################

#######################################################################
##
##  Tuning/Performance
## --------------------
##
## corresponding documentation:
## https://wiki.lighttpd.net/Docs_Performance
##
## set the event-handler (read the performance section in the manual)
##
## The recommended server.event-handler is chosen by default for each OS.
##
## epoll  (recommended on Linux)
## kqueue (recommended on *BSD and MacOS X)
## solaris-eventports (recommended on Solaris)
## poll   (recommended if none of above are available)
## select (*not* recommended)
##
#server.event-handler = "epoll"

##
## The basic network interface for all platforms at the syscalls read()
## and write(). Every modern OS provides its own syscall to help network
## servers transfer files as fast as possible 
##
#server.network-backend = "sendfile"

##
## As lighttpd is a single-threaded server, its main resource limit is
## the number of file descriptors, which is set to 1024 by default (on
## most systems).
##
## If you are running a high-traffic site you might want to increase this
## limit by setting server.max-fds.
##
## Changing this setting requires root permissions on startup. see
## server.username/server.groupname.
##
## By default lighttpd would not change the operation system default.
## But setting it to 16384 is a better default for busy servers.
##
## With SELinux enabled, this is denied by default and needs to be allowed
## by running the following once: setsebool -P httpd_setrlimit on
##
server.max-fds = 16384

##
## listen-backlog is the size of the listen() backlog queue requested when
## the lighttpd server ask the kernel to listen() on the provided network
## address.  Clients attempting to connect() to the server enter the listen()
## backlog queue and wait for the lighttpd server to accept() the connection.
##
## The out-of-box default on many operating systems is 128 and is identified
## as SOMAXCONN.  This can be tuned on many operating systems.  (On Linux,
## cat /proc/sys/net/core/somaxconn)  Requesting a size larger than operating
## system limit will be silently reduced to the limit by the operating system.
##
## When there are too many connection attempts waiting for the server to
## accept() new connections, the listen backlog queue fills and the kernel
## rejects additional connection attempts.  This can be useful as an
## indication to an upstream load balancer that the server is busy, and
## possibly overloaded.  In that case, configure a smaller limit for
## server.listen-backlog.  On the other hand, configure a larger limit to be
## able to handle bursts of new connections, but only do so up to an amount
## that the server can keep up with responding in a reasonable amount of
## time.  Otherwise, clients may abandon the connection attempts and the
## server will waste resources servicing abandoned connections.
##
## It is best to leave this setting at its default unless you have modelled
## your traffic and tested that changing this benefits your traffic patterns.
##
## Default: 1024
##
#server.listen-backlog = 128

##
## Stat() call caching.
##
## lighttpd can utilize FAM/Gamin to cache stat call.
##
## possible values are:
## disable, simple, inotify, kqueue, or fam.
##
#server.stat-cache-engine = "simple"

##
## Fine tuning for the request handling
##
## max-connections == max-fds/3
## (other file handles are used for fastcgi/files)
##
#server.max-connections = 1024

##
## How many seconds to keep a keep-alive connection open,
## until we consider it idle. 
##
## Default: 5
##
#server.max-keep-alive-idle = 5

##
## How many keep-alive requests until closing the connection.
##
## Default: 16
##
#server.max-keep-alive-requests = 16

##
## Maximum size of a request in kilobytes.
## By default it is unlimited (0).
##
## Uploads to your server cant be larger than this value.
##
#server.max-request-size = 0

##
## Time to read from a socket before we consider it idle.
##
## Default: 60
##
#server.max-read-idle = 60

##
## Time to write to a socket before we consider it idle.
##
## Default: 360
##
#server.max-write-idle = 360

##
##  Traffic Shaping 
## -----------------
##
## see /usr/share/doc/lighttpd/traffic-shaping.txt
##
## Values are in kilobytes per second.
##
## Keep in mind that a limit below 32kB/s might actually limit the
## traffic to 32kB/s. This is caused by the size of the TCP send
## buffer. 
##
## per server:
##
#server.kbytes-per-second = 128

##
## per connection:
##
#connection.kbytes-per-second = 32

##
#######################################################################

#######################################################################
##
##  Filename/File handling
## ------------------------

##
## files to check for if .../ is requested
## index-file.names            = ( "index.php", "index.rb", "index.html",
##                                 "index.htm", "default.htm" )
##
index-file.names += (
  "index.xhtml", "index.html", "index.htm", "default.htm", "index.php"
)

##
## deny access the file-extensions
##
## ~    is for backupfiles from vi, emacs, joe, ...
## .inc is often used for code includes which should in general not be part
##      of the document-root
url.access-deny             = ( "~", ".inc" )

##
## disable range requests for pdf files
## workaround for a bug in the Acrobat Reader plugin.
## (ancient; should no longer be needed)
##
#\$HTTP["url"] =~ "\.pdf$" {
#  server.range-requests = "disable"
#}

##
## url handling modules (rewrite, redirect)
##
#url.rewrite                = ( "^/$"             => "/server-status" )
#url.redirect               = ( "^/wishlist/(.+)" => "http://www.example.com/$1" )

##
## both rewrite/redirect support back reference to regex conditional using %n
##
#\$HTTP["host"] =~ "^www\.(.*)" {
#  url.redirect            = ( "^/(.*)" => "http://%1/$1" )
#}

##
## which extensions should not be handled via static-file transfer
##
## .php, .pl, .fcgi are most often handled by mod_fastcgi or mod_cgi
##
static-file.exclude-extensions = ( ".php", ".pl", ".fcgi", ".scgi" )

##
## error-handler for all status 400-599
##
#server.error-handler       = "/error-handler.html"
#server.error-handler       = "/error-handler.php"

##
## error-handler for status 404
##
#server.error-handler-404   = "/error-handler.html"
#server.error-handler-404   = "/error-handler.php"

##
## Format: <errorfile-prefix><status-code>.html
## -> ..../status-404.html for 'File not found'
##
#server.errorfile-prefix    = server_root + "/htdocs/errors/status-"

##
## mimetype mapping
##
include conf_dir + "/conf.d/mime.conf"

##
## directory listing configuration
##
include conf_dir + "/conf.d/dirlisting.conf"

##
## Should lighttpd follow symlinks?
## default: "enable"
#server.follow-symlink = "enable"

##
## force all filenames to be lowercase?
##
#server.force-lowercase-filenames = "disable"

##
## defaults to /var/tmp as we assume it is a local harddisk
## default: "/var/tmp"
#server.upload-dirs = ( "/var/tmp" )

##
#######################################################################

#######################################################################
##
##  SSL Support
## ------------- 
##
## https://wiki.lighttpd.net/Docs_SSL
#
## To enable SSL for the whole server you have to provide a valid
## certificate and have to enable the SSL engine.::
##
##   server.modules += ( "mod_openssl" )
##
##   ssl.privkey = "/path/to/privkey.pem"
##   ssl.pemfile = "/path/to/fullchain.pem"
##   # ssl.pemfile should contain the sorted certificate chain, including
##   # intermediate certificates, as provided by the certificate issuer.
##   # If both privkey and cert are in same file, specify only ssl.pemfile.
##
##   # Check your cipher list with: openssl ciphers -v '...'
##   # (use single quotes with: openssl ciphers -v '...'
##   #  as your shell won't like ! in double quotes)
##   #ssl.openssl.ssl-conf-cmd +=
##   #  ("CipherString" => "EECDH+AESGCM:CHACHA20:!PSK:!DHE")   # default
##
##   # (recommended to accept only TLSv1.2 and TLSv1.3)
##   #ssl.openssl.ssl-conf-cmd += ("MinProtocol" => "TLSv1.2")  # default
##
##   \$SERVER["socket"] == "*:443" {
##     ssl.engine  = "enable"
##   }
##   \$SERVER["socket"] == "[::]:443" {
##     ssl.engine  = "enable"
##   }
##
#######################################################################

#######################################################################
##
## custom includes like vhosts.
##
#include conf_dir + "/conf.d/config.conf"
#include conf_dir + "/vhosts.d/*.conf"
##
#######################################################################
EOF
else
sudo bash -c "cat > /etc/lighttpd/lighttpd.conf" <<EOF
#######################################################################
##
## /etc/lighttpd/lighttpd.conf
##
## check /etc/lighttpd/conf.d/*.conf for the configuration of modules.
##
#######################################################################

#######################################################################
##
## Some Variable definition which will make chrooting easier.
##
## if you add a variable here. Add the corresponding variable in the
## chroot example as well.
##
var.log_root    = "/var/log/lighttpd"
var.server_root = "/srv/www"
var.state_dir   = "/run"
var.home_dir    = "/var/lib/lighttpd"
var.conf_dir    = "/etc/lighttpd"

## 
## run the server chrooted.
## 
## This requires root permissions during startup.
##
## If you run chroot'ed, set the variables to directories relative to
## the chroot dir.
##
## example chroot configuration:
## 
#var.log_root    = "/logs"
#var.server_root = "/"
#var.state_dir   = "/run"
#var.home_dir    = "/lib/lighttpd"
#var.vhosts_dir  = "/vhosts"
#var.conf_dir    = "/etc"
#
#server.chroot   = "/srv/www"

##
## Some additional variables to make the configuration easier
##

##
## Base directory for all virtual hosts
##
## used in:
## conf.d/evhost.conf
## conf.d/simple_vhost.conf
## vhosts.d/vhosts.template
##
var.vhosts_dir  = server_root + "/vhosts"

##
## Cache for mod_deflate
##
## used in:
## conf.d/deflate.conf
##
var.cache_dir   = "/var/cache/lighttpd"

##
## Base directory for sockets.
##
## used in:
## conf.d/fastcgi.conf
## conf.d/scgi.conf
##
var.socket_dir  = home_dir + "/sockets"

##
#######################################################################

#######################################################################
##
## Load the modules.
include conf_dir + "/modules.conf"

##
#######################################################################

#######################################################################
##
##  Basic Configuration
## ---------------------
##
server.port = ${puerto}

##
## bind to a specific IP
## (default: "*" for all local IPv4 interfaces)
##
#server.bind = "localhost"

##
## Run as a different username/groupname.
## This requires root permissions during startup. 
##
server.username  = "lighttpd"
server.groupname = "lighttpd"

##
## Enable lighttpd to serve requests on sockets received from systemd
## https://www.freedesktop.org/software/systemd/man/systemd.socket.html
##
#server.systemd-socket-activation = "enable"

## 
## enable core files.
##
#server.core-files = "disable"

##
## Document root
##
server.document-root = server_root + "/htdocs"

##
## The value for the "Server:" response field.
##
## It would be nice to keep it at "lighttpd".
##
#server.tag = "lighttpd"

##
## store a pid file
##
server.pid-file = state_dir + "/lighttpd.pid"

##
#######################################################################

#######################################################################
##
##  Logging Options
## ------------------
##
## all logging options can be overwritten per vhost.
##
## Path to the error log file
##
server.errorlog = "/tmp/lighttpd_error.log"

##
## If you want to log to syslog you have to unset the 
## server.errorlog = "/tmp/lighttpd_error.log"
##
#server.errorlog = "/tmp/lighttpd_error.log"

##
## Access log config
## 
include conf_dir + "/conf.d/access_log.conf"

##
## The debug options are moved into their own file.
## see conf.d/debug.conf for various options for request debugging.
##
include conf_dir + "/conf.d/debug.conf"

##
#######################################################################

#######################################################################
##
##  Tuning/Performance
## --------------------
##
## corresponding documentation:
## https://wiki.lighttpd.net/Docs_Performance
##
## set the event-handler (read the performance section in the manual)
##
## The recommended server.event-handler is chosen by default for each OS.
##
## epoll  (recommended on Linux)
## kqueue (recommended on *BSD and MacOS X)
## solaris-eventports (recommended on Solaris)
## poll   (recommended if none of above are available)
## select (*not* recommended)
##
#server.event-handler = "epoll"

##
## The basic network interface for all platforms at the syscalls read()
## and write(). Every modern OS provides its own syscall to help network
## servers transfer files as fast as possible 
##
#server.network-backend = "sendfile"

##
## As lighttpd is a single-threaded server, its main resource limit is
## the number of file descriptors, which is set to 1024 by default (on
## most systems).
##
## If you are running a high-traffic site you might want to increase this
## limit by setting server.max-fds.
##
## Changing this setting requires root permissions on startup. see
## server.username/server.groupname.
##
## By default lighttpd would not change the operation system default.
## But setting it to 16384 is a better default for busy servers.
##
## With SELinux enabled, this is denied by default and needs to be allowed
## by running the following once: setsebool -P httpd_setrlimit on
##
server.max-fds = 16384

##
## listen-backlog is the size of the listen() backlog queue requested when
## the lighttpd server ask the kernel to listen() on the provided network
## address.  Clients attempting to connect() to the server enter the listen()
## backlog queue and wait for the lighttpd server to accept() the connection.
##
## The out-of-box default on many operating systems is 128 and is identified
## as SOMAXCONN.  This can be tuned on many operating systems.  (On Linux,
## cat /proc/sys/net/core/somaxconn)  Requesting a size larger than operating
## system limit will be silently reduced to the limit by the operating system.
##
## When there are too many connection attempts waiting for the server to
## accept() new connections, the listen backlog queue fills and the kernel
## rejects additional connection attempts.  This can be useful as an
## indication to an upstream load balancer that the server is busy, and
## possibly overloaded.  In that case, configure a smaller limit for
## server.listen-backlog.  On the other hand, configure a larger limit to be
## able to handle bursts of new connections, but only do so up to an amount
## that the server can keep up with responding in a reasonable amount of
## time.  Otherwise, clients may abandon the connection attempts and the
## server will waste resources servicing abandoned connections.
##
## It is best to leave this setting at its default unless you have modelled
## your traffic and tested that changing this benefits your traffic patterns.
##
## Default: 1024
##
#server.listen-backlog = 128

##
## Stat() call caching.
##
## lighttpd can utilize FAM/Gamin to cache stat call.
##
## possible values are:
## disable, simple, inotify, kqueue, or fam.
##
#server.stat-cache-engine = "simple"

##
## Fine tuning for the request handling
##
## max-connections == max-fds/3
## (other file handles are used for fastcgi/files)
##
#server.max-connections = 1024

##
## How many seconds to keep a keep-alive connection open,
## until we consider it idle. 
##
## Default: 5
##
#server.max-keep-alive-idle = 5

##
## How many keep-alive requests until closing the connection.
##
## Default: 16
##
#server.max-keep-alive-requests = 16

##
## Maximum size of a request in kilobytes.
## By default it is unlimited (0).
##
## Uploads to your server cant be larger than this value.
##
#server.max-request-size = 0

##
## Time to read from a socket before we consider it idle.
##
## Default: 60
##
#server.max-read-idle = 60

##
## Time to write to a socket before we consider it idle.
##
## Default: 360
##
#server.max-write-idle = 360

##
##  Traffic Shaping 
## -----------------
##
## see /usr/share/doc/lighttpd/traffic-shaping.txt
##
## Values are in kilobytes per second.
##
## Keep in mind that a limit below 32kB/s might actually limit the
## traffic to 32kB/s. This is caused by the size of the TCP send
## buffer. 
##
## per server:
##
#server.kbytes-per-second = 128

##
## per connection:
##
#connection.kbytes-per-second = 32

##
#######################################################################

#######################################################################
##
##  Filename/File handling
## ------------------------

##
## files to check for if .../ is requested
## index-file.names            = ( "index.php", "index.rb", "index.html",
##                                 "index.htm", "default.htm" )
##
index-file.names += (
  "index.xhtml", "index.html", "index.htm", "default.htm", "index.php"
)

##
## deny access the file-extensions
##
## ~    is for backupfiles from vi, emacs, joe, ...
## .inc is often used for code includes which should in general not be part
##      of the document-root
url.access-deny             = ( "~", ".inc" )

##
## disable range requests for pdf files
## workaround for a bug in the Acrobat Reader plugin.
## (ancient; should no longer be needed)
##
#\$HTTP["url"] =~ "\.pdf$" {
#  server.range-requests = "disable"
#}

##
## url handling modules (rewrite, redirect)
##
#url.rewrite                = ( "^/$"             => "/server-status" )
#url.redirect               = ( "^/wishlist/(.+)" => "http://www.example.com/$1" )

##
## both rewrite/redirect support back reference to regex conditional using %n
##
#\$HTTP["host"] =~ "^www\.(.*)" {
#  url.redirect            = ( "^/(.*)" => "http://%1/$1" )
#}

##
## which extensions should not be handled via static-file transfer
##
## .php, .pl, .fcgi are most often handled by mod_fastcgi or mod_cgi
##
static-file.exclude-extensions = ( ".php", ".pl", ".fcgi", ".scgi" )

##
## error-handler for all status 400-599
##
#server.error-handler       = "/error-handler.html"
#server.error-handler       = "/error-handler.php"

##
## error-handler for status 404
##
#server.error-handler-404   = "/error-handler.html"
#server.error-handler-404   = "/error-handler.php"

##
## Format: <errorfile-prefix><status-code>.html
## -> ..../status-404.html for 'File not found'
##
#server.errorfile-prefix    = server_root + "/htdocs/errors/status-"

##
## mimetype mapping
##
include conf_dir + "/conf.d/mime.conf"

##
## directory listing configuration
##
include conf_dir + "/conf.d/dirlisting.conf"

##
## Should lighttpd follow symlinks?
## default: "enable"
#server.follow-symlink = "enable"

##
## force all filenames to be lowercase?
##
#server.force-lowercase-filenames = "disable"

##
## defaults to /var/tmp as we assume it is a local harddisk
## default: "/var/tmp"
#server.upload-dirs = ( "/var/tmp" )

##
#######################################################################

#######################################################################
##
##  SSL Support
## ------------- 
##
## https://wiki.lighttpd.net/Docs_SSL
#
## To enable SSL for the whole server you have to provide a valid
## certificate and have to enable the SSL engine.::
##
##   server.modules += ( "mod_openssl" )
##
##   ssl.privkey = "/path/to/privkey.pem"
##   ssl.pemfile = "/path/to/fullchain.pem"
##   # ssl.pemfile should contain the sorted certificate chain, including
##   # intermediate certificates, as provided by the certificate issuer.
##   # If both privkey and cert are in same file, specify only ssl.pemfile.
##
##   # Check your cipher list with: openssl ciphers -v '...'
##   # (use single quotes with: openssl ciphers -v '...'
##   #  as your shell won't like ! in double quotes)
##   #ssl.openssl.ssl-conf-cmd +=
##   #  ("CipherString" => "EECDH+AESGCM:CHACHA20:!PSK:!DHE")   # default
##
##   # (recommended to accept only TLSv1.2 and TLSv1.3)
##   #ssl.openssl.ssl-conf-cmd += ("MinProtocol" => "TLSv1.2")  # default
##
##   \$SERVER["socket"] == "*:443" {
##     ssl.engine  = "enable"
##   }
##   \$SERVER["socket"] == "[::]:443" {
##     ssl.engine  = "enable"
##   }
##
#######################################################################

#######################################################################
##
## custom includes like vhosts.
##
#include conf_dir + "/conf.d/config.conf"
#include conf_dir + "/vhosts.d/*.conf"
##
#######################################################################
EOF
    fi
    
    sudo sed -i '/mod_Foo/d' /etc/lighttpd/modules.conf
    
    local error_log_file="/tmp/lighttpd_error.log"
    sudo sed -i "s#server.errorlog.*#server.errorlog = \"${error_log_file}\"#g" "$rutaArchivoConfiguracion"

    local access_log_file="/tmp/lighttpd_access.log"
    sudo sed -i "s/^accesslog.filename[[:space:]]*=.*$/accesslog.filename = \"${access_log_file}\"/" "$rutaArchivoConfiguracion"

    # Establecer server.document-root si no existe
    if ! grep -q "^server.document-root" "$rutaArchivoConfiguracion"; then
        sudo sed -i '$a server.document-root = "/var/www/html/"' "$rutaArchivoConfiguracion"
    fi
    
    echo "Iniciando Lighttpd directamente..."
    sudo /usr/local/lighttpd/sbin/lighttpd -f "$rutaArchivoConfiguracion"

    echo "Verificando si Lighttpd está corriendo..."
    ps aux | grep lighttpd

    echo "Lighttpd ${versionLIGHTTPD} compilado e instalado en el puerto ${puerto}."
    echo "======================================="
    cd ..
    
    sudo systemctl daemon-reload &>/dev/null
    sudo systemctl enable lighttpd &>/dev/null
    sudo systemctl start lighttpd &>/dev/null
    sudo systemctl restart lighttpd &>/dev/null
    unset DESCARGADO
}

# --- Función Genérica de Instalación de Servicio HTTP ---
instalar_servicio_http() {
    local servicio="$1"
    local opcion_version_servicio
    local puerto_servicio

    if [[ "$DESCARGADO" == "true" ]]; then
        # Extraer la versión desde ARCHIVO
        if [[ "$ARCHIVO" =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
            version_instalada="${BASH_REMATCH[1]}"
        else
            echo "No se pudo extraer la versión del archivo '$ARCHIVO'."
            exit 1
        fi

        case "$servicio" in
            "nginx")
                local version_lts_online
                local version_dev_online
                version_lts_online=$(obtener_versiones_nginx_lts)
                version_dev_online=$(obtener_versiones_nginx_dev)
                if [[ "$version_instalada" == "$version_lts_online" ]]; then
                    opcion_version_servicio=2
                elif [[ "$version_instalada" == "$version_dev_online" ]]; then
                    opcion_version_servicio=1
                else
                    echo "La versión '$version_instalada' no coincide con las versiones oficiales de Nginx."
                    exit 1
                fi
                ;;
            "tomcat")
                # Para Tomcat, se compara con las versiones obtenidas desde la web
                local html=$(curl -s "https://tomcat.apache.org/index.html")
                local versiones=($(echo "$html" | grep -oP '(?<=<h3 id="Tomcat_)\d+\.\d+\.\d+'))
                if [[ ${#versiones[@]} -ge 2 ]]; then
                    local version_lts="${versiones[0]}"
                    local version_dev="${versiones[-1]}"
                else
                    echo "No se pudieron obtener las versiones de Tomcat."
                    exit 1
                fi
                if [[ "$version_instalada" == "$version_lts" ]]; then
                    opcion_version_servicio=2
                elif [[ "$version_instalada" == "$version_dev" ]]; then
                    opcion_version_servicio=1
                else
                    echo "La versión '$version_instalada' no coincide con las versiones oficiales de Tomcat."
                    exit 1
                fi
                ;;
            "lighttpd")
                local version_latest
                local version_stable
                version_latest=$(obtener_versiones_lighttpd_latest)
                version_stable=$(obtener_versiones_lighttpd_stable)
                if [[ "$version_instalada" == "$version_latest" ]]; then
                    opcion_version_servicio=1
                elif [[ "$version_instalada" == "$version_stable" ]]; then
                    opcion_version_servicio=2
                else
                    echo "La versión '$version_instalada' no coincide con las versiones oficiales de Lighttpd."
                    exit 1
                fi
                ;;
            *)
                echo "Servicio no válido."
                return 1
                ;;
        esac
    else
        # Flujo interactivo: se muestran las versiones para que el usuario seleccione
        case "$servicio" in
            "nginx")
                obtener_versiones_nginx
                while true; do
                    read -p "Selecciona la versión de Nginx a instalar (1-3): " opcion_version_servicio
                    case "$opcion_version_servicio" in
                        1|2) break ;;
                        3) echo "Instalación de Nginx cancelada."; unset DESCARGADO; return ;;
                        *) echo "Opción no válida. Por favor, selecciona 1, 2 o 3." ;;
                    esac
                done
                ;;
            "tomcat")
                obtener_versiones_tomcat
                while true; do
                    read -p "Selecciona la versión de Tomcat a instalar (1-3): " opcion_version_servicio
                    case "$opcion_version_servicio" in
                        1|2) break ;;
                        3) echo "Instalación de Tomcat cancelada."; unset DESCARGADO; return ;;
                        *) echo "Opción no válida. Por favor, selecciona 1, 2 o 3." ;;
                    esac
                done
                ;;
            "lighttpd")
                obtener_versiones_lighttpd
                while true; do
                    read -p "Selecciona la versión de Lighttpd a instalar (1-3): " opcion_version_servicio
                    case "$opcion_version_servicio" in
                        1|2) break ;;
                        3) echo "Instalación de Lighttpd cancelada."; unset DESCARGADO; return ;;
                        *) echo "Opción no válida. Por favor, selecciona 1, 2 o 3." ;;
                    esac
                done
                ;;
            *)
                echo "Servicio no válido."
                return 1
                ;;
        esac
    fi

    # Solicitar puerto
    while true; do
        read -p "Introduce el puerto para ${servicio}: " puerto_servicio
        if validar_puerto "$puerto_servicio"; then
            if verificar_puerto_en_uso "$puerto_servicio"; then
                echo "Puerto ${puerto_servicio} está en uso."
                obtener_puertos_disponibles
            else
                break
            fi
        fi
    done

    # Solicitar configuración SSL
    read -p "¿Desea instalar el servicio de forma segura con SSL autofirmado? (s/n): " opcion_ssl
    if [[ "$opcion_ssl" =~ ^[sS] ]]; then
         ssl="true"
    else
         ssl="false"
    fi

    # Llamar a la función específica según el servicio
    case "$servicio" in
        "nginx")
            instalar_nginx "$puerto_servicio" "$opcion_version_servicio" "$ssl"
            unset DESCARGADO
            ;;
        "tomcat")
            instalar_tomcat "$opcion_version_servicio" "$puerto_servicio" "$ssl"
            unset DESCARGADO
            ;;
        "lighttpd")
            instalar_lighttpd "$opcion_version_servicio" "$puerto_servicio" "$ssl"
            unset DESCARGADO
            ;;
    esac
}

# --- Funciones auxiliares para obtener versiones de Nginx y Tomcat ---
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

obtener_versiones_lighttpd_latest() {
    local url="https://www.lighttpd.net/releases/index.html"
    local html=$(curl -s "$url")
    local version=$(echo "$html" | grep -oP '<li><a href="[^"]*">[0-9]+\.[0-9]+\.[0-9]+' | sed 's/.*\">//' | head -n 1)
    echo "$version"
}

obtener_versiones_lighttpd_stable() {
    local url="https://www.lighttpd.net/releases/index.html"
    local html=$(curl -s "$url")
    local version=$(echo "$html" | grep -oP '<li><a href="[^"]*">[0-9]+\.[0-9]+\.[0-9]+' | sed 's/.*\">//' | head -n 2 | tail -n 1)
    echo "$version"
}

