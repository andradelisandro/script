############################################
# @Autor: AndradeLisandro 
# Run: PowerShell -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File C:\Tareas\Compress7z.ps1 "$FOLDER"
# Descripcion: Compresion de todo los backup de una base en 7z
# @Variable:
#          $FOLDER: Path donde estan todo los backup o archivos a comprimir
# Nota: ruta que se envia en el script "E:\Respaldo"
# Fecha: 

## Ejecutar script
$path=$args[0]
$destinationArchiveFile="E:\Compress_Backup\"

# Alias for 7-zip 
if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {
    throw "$env:ProgramFiles\7-Zip\7z.exe not found"
} 
set-alias 7z "$env:ProgramFiles\7-Zip\7z.exe" 

Get-ChildItem -Path $path -Recurse -File | ForEach-Object { & 7z a -tzip -mx9 ($destinationArchiveFile+$_.Name+".7z") $_.FullName }
