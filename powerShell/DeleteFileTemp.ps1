############################################
# @Autor: AndradeLisandro 
# Run: PowerShell -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File DeleteFileTemp.ps1 "C:\Tareas\PRUEBA\"
# Descripcion:  Este script borra todo los archivos de un directorio 
# @Variable:
#          C:\Tareas\PRUEBA\: Directorio que desea eliminar todo los archivos
# Nota: Es muy importante la barra al final de la ruta sino se borrara la carpeta. Esto script son usados con el programador de tarea
# Fecha: 10/12/2019

$path=$args[0]

$files = Get-ChildItem -Path $path

Foreach ($file in $files){
    Write-Host $file
    Remove-Item -Force $path$file
}