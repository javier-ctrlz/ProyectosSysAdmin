#!/bin/bash
# Zapien Rivera Jesús Javier
# 302 IS

installdocker(){
  sudo apt update
  echo "Instalando dependencias..."
  sudo apt install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "Añadiendo repositorios al sistema..."
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  echo "Repositorios añadidos."
  
  echo "Instalando docker..."
  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl status docker 
  echo "Presiona ENTER para continuar..."
  read enter
  clear
  echo "Verificando instalacion..."
  echo "Corriendo imagen predeterminada..."
  sudo docker run hello-world
  echo "Presiona ENTER para continuar..."
  read enter
}

installapache(){
  echo "Descargando imagen de apache..."
  sudo docker pull httpd
  sudo docker run -d --name imagen-apache -p 8080:80 httpd
}

modapache(){
  sudo docker rm -f imagen-apache
  
  echo "Ingresa un mensaje para mostrar en la pagina de inicio de apache:"
  read texto
  echo "<h1> $texto </h1>" > index.html

  sudo docker run -d --name imagen-apache -p 8080:80 \
    -v $(pwd)/index.html:/usr/local/apache2/htdocs/index.html \
    httpd
  echo "Imagen modificada..."
}

createdockerfile(){
  sudo docker rm -f imagen-apache
  echo "Creando imagen personalizada..."
  echo "FROM httpd
COPY index.html /usr/local/apache2/htdocs/index.html" > Dockerfile
  sudo docker build -t apache-personalizado .
  sudo docker run -d --name imagen-apache -p 8081:80 apache-personalizado
  echo "Imagen creada..."
}

configpostgres(){
  echo "Creando red para conectar contenedores..."
  sudo docker network create red-postgres

  echo "Creando contenedores..."
  sudo docker run -d --name post1 --network red-postgres -e POSTGRES_PASSWORD=1234 -e POSTGRES_USER=usuario postgres #Contenedor 1

  echo "Ingresa una contraseña para el contenedor 2"
  read contra
  sudo docker run -d --name post2 --network red-postgres -e POSTGRES_PASSWORD=$contra -e POSTGRES_USER=usuario -e POSTGRES_DB=dbprueba postgres #Contenedor 2 con base de datos
  sudo docker logs -f post2
  echo "Conectando contenedores..."
  echo "Ingresa las contraseñas configuradas para el contenedor 2"
  sudo docker exec -it post1 psql -h post2 -U usuario -d dbprueba  #ejecutamos el contenedor 1 conectandonos al 2
}

