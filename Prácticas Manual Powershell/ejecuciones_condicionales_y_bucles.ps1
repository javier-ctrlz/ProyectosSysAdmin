#Ilustración 14
$condicion = $true
if ( $condicion )
{
    Write-Output "La condicion era verdadera"
}
else
{
    Write-Output "La condicion era falsa"
}

#Ilustración 15
$numero = 2
if ( $numero -ge 3 )
{
    Write-Output "El numero [$numero] es mayor o igual que 3"
}
elseif ( $numero -lt 2 )
{
    Write-Output "El numero [$numero] es menor que 2"
}
else
{
    Write-Output "El numero [$numero] es igual a 2"
}


#Ilustración 17
$PSVersionTable

#Ilustración 18
$mensaje = (Test-Path $path) ? "Path existe" : "Path no encontrado"
$mensaje

#Ilustración 21
switch (3) 
{
    1 { "[$_] es uno." }
    2 { "[$_] es dos." }
    3 { "[$_] es tres." }
    4 { "[$_] es cuatro." }
}

#Ilustración 22
switch (3) 
{
    1 { "[$_] es uno." }
    2 { "[$_] es dos." }
    3 { "[$_] es tres." }
    4 { "[$_] es cuatro." }
    3 { "[$_] es tres de nuevo." }
}

#Ilustración 23
switch (3) 
{
    1 { "[$_] es uno." }
    2 { "[$_] es dos." }
    3 { "[$_] es tres."; Break }
    4 { "[$_] es cuatro." }
    3 { "[$_] es tres de nuevo." }
}

#Ilustración 24
switch (1, 5) 
{
    1 { "[$_] es uno." }
    2 { "[$_] es dos." }
    3 { "[$_] es tres." }
    4 { "[$_] es cuatro." }
    5 { "[$_] es cinco." }
}

#Ilustración 25
switch ("seis")
{
    1 { "[$_] es uno."; Break }
    2 { "[$_] es dos."; Break }
    3 { "[$_] es tres."; Break }
    4 { "[$_] es cuatro."; Break }
    5 { "[$_] es cinco."; Break }
    "se*" { "[$_] coincide con se*." }
    Default { 
        "No hay coincidencias con [$_]" 
            }
}

#Ilustración 26
switch -Wildcard ("seis")
{
    1 { "[$_] es uno."; Break }
    2 { "[$_] es dos."; Break }
    3 { "[$_] es tres."; Break }
    4 { "[$_] es cuatro."; Break }
    5 { "[$_] es cinco."; Break }
    "se*" { "[$_] coincide con se*." }
    Default { 
        "No hay coincidencias con [$_]" 
            }
}

#Ilustración 27
$email = 'antonio.yanez@udc.es'
$email2 = 'antonio.yanez@usc.gal'
$url = 'https://www.dc.fi-udc.es/~afyanes/Docencia/2023'
switch -Regex ($url, $email, $email2)
{
    '^\w+\.\w+@(udc|usc|edu)\.es|gal$' { "[$_] es una direccion de correo electronico academica" }
    '^ftp\://.*$' { "[$_] es una direccion ftp"}
    '^(http[s]?)\://.*$' { "[$_] es una direccion web, que utiliza [$($matches[1])]" }
}

#Ilustración 28
1 -eq "1.0"
"1.0" -eq 1

#Ilustración 31
for (($i = 0), ($j = 0); $i -lt 5; $i++) {
    "`$i:$i"
    "`$j:$j"
}

#Ilustración 32
for ($($i = 0;$j = 0); $i -lt 5; $($i++;$j++)) {
    "`$i:$i"
    "`$j:$j"
}

#Ilustración 34
$ssoo = "freebsd", "openbsd", "solaris", "fedora", "ubuntu", "netbsd"
foreach ($so in $ssoo) {
    Write-Host $so
}

#Ilustración 35
foreach ($archivo in Get-ChildItem) {
    if ($archivo.lenght -ge 10KB)
    {
        Write-Host $archivo -> [($archivo.lenght)]
    }
}

#Ilustración 37
$num = 0

while ($num -ne 3)
{
    $num++
    Write-Host $num
}

#Ilustración 38
$num = 0

while ($num -ne 5)
{
    if ($num -eq 1){ $num = $num + 3 ; Continue }
    $num++
    Write-Host $num
}

#Ilustración 40
$valor = 5
$multiplicacion = 1
do
{
    $multiplicacion = $multiplicacion * $valor
    $valor--
}
while ($valor -gt 0)

Write-Host $multiplicacion

#Ilustración 41
$valor = 5
$multiplicacion = 1
do
{
    $multiplicacion = $multiplicacion * $valor
    $valor--
}  
until ($valor -eq 0)

Write-Host $multiplicacion

#Ilustración 42
$num = 10

for($i = 2; $i -lt 10; $i++)
{
    $num = $num + $i
    if ($i -eq 5){ Break }
}

#Ilustración 43
$cadena = "Hola, buenas tardes"
$cadena2 = "Hola, buenas noches"

switch -Wildcard ($cadena, $cadena2)
{
    "Hola, buenas*" { "[$_] coincide con [Hola, buenas*]" }
    "Hola, bue*" { "[$_] coincide con [Hola, bue*]" }
    "Hola,* " { "[$_] coincide con [Hola,* ]" ; Break }
    "Hola, buenas tardes" { "[$_] coincide con [Hola, buenas tardes]" }
}

#Ilustración 44
$num = 10

for($i = 2; $i -lt 10; $i++)
{
    if ($i -eq 5){ Continue }
    $num = $num + $i
}

Write-Host $num
Write-Host $i

#Ilustración 45
$cadena = "Hola, buenas tardes"
$cadena2 = "Hola, buenas noches"

switch -Wildcard ($cadena, $cadena2)
{
    "Hola, buenas*" { "[$_] coincide con [Hola, buenas*]" }
    "Hola, bue*" { "[$_] coincide con [Hola, bue*]"; Continue }
    "Hola,* " { "[$_] coincide con [Hola,* ]" }
    "Hola, buenas tardes" { "[$_] coincide con [Hola, buenas tardes]" }
}