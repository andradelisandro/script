############################################
# @Autor: AndradeLisandro 
# Run: #PowerShell -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File C:\Tareas\SendMailBackup.ps1
# Descripcion:  Este script que envia un mail con el contenido de un logs
# @Variable:
# Nota:
# Fecha:

$folder = "C:\Backups\__Log"
$file = Get-ChildItem $folder |
              sort LastWriteTime |
              Select-Object -Last 1
$body = get-content $folder\$file -Raw
$from = "xxxxx@dominio.com"
$to = "xxxxx@dominio.com"
$subject = "****** Log Backup Base de datos $(hostname) ******"
$smtpserver = "smtp.com"
$user="xxxxx@dominio.com"
$passwd = ConvertTo-SecureString "xxxxxxxxx" -AsPlainText -Force #aqui va la passsword del usuario SMTP
$credenciales= New-Object System.Management.Automation.PSCredential ($user,$passwd)
Send-MailMessage -smtpServer $smtpserver -from $from -to $to -subject $subject -body $body -credential $credenciales