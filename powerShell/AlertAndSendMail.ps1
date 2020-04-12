############################################
# @Autor: AndradeLisandro 
# Run: PowerShell -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File AlertAndSendMail.ps1 5
# Descripcion:  Este script informar el estado del disco por correo
# @Variable:
#          5: Es la cantida de GB minimo disponible en el disco para enviar el mail
# Nota: Esto script son usados con el programador de tarea
# Fecha: 10/12/2019

#Paramt
$param1=$args[0]
#write-host $param1 

#Informacion de Disk
$DiskReport =Get-WMIObject Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"}  | select @{n="Unidad";e={($_.Name)}},@{n="Label";e={($_.VolumeName)}},@{n='Size';e={"{0:n2}" -f ($_.size/1gb)}},@{n='FreeSpace';e={"{0:n0}" -f ($_.freespace/1gb)}},@{n="FreeSpacePercentage";e={"{0:n2}" -f ($_.freespace/$_.size*100)}}
$DiskReportValue = $DiskReport[0] | select freespace

#Variables
$FreeSpace = $DiskReport[0] |select FreeSpace
$Size = $DiskReport[0] | select Size
$Unidad = $DiskReport[0] | select Unidad
$FreeSpacePercentage = $DiskReport[0] | select FreeSpacePercentage
$Label = $DiskReport[0] | select Label
$time = Get-Date -DisplayHint Time 
$time = $time.ToString('dd-MM-yyyy HH:mm:ss').Trim()

#create report
$body = $DiskReport | Select-Object 
                    @{Label ="Unidad";e={($_.Name)}}, 
                    @{Label = "Label";e={($_.VolumeName)}}, 
                    @{Label = "Size (GB)";e={"{0:n2}" -f ($_.size/1gb)}}, 
                    @{Label = "Free (GB)";e={"{0:n2}" -f ($_.freespace/1gb)}}, 
                    @{Label = "%Free";e={"{0:n0}" -f ($_.freespace/$_.size*100)}}|
Out-String
#$body += "Equipo: = {0}" -f $env:computername

$body = 
"Host : "+(hostname)+,
"`n"+
"Fecha : "+$time+,
"`n"+
"Unidad : "+$Unidad.Unidad.Trim()+,
"`n"+
"Etiqueta : "+$Label.Label.Trim()+,
"`n"+
"Tamano (GB) : "+$Size.Size.Trim()+,
"`n"+
"Libre (GB) : "+$FreeSpace.FreeSpace.Trim()+,
"`n"+
"% Libre    : "+$FreeSpacePercentage.FreeSpacePercentage.Trim()|
Out-String

$from = "xxxx@dominio.com"
$to = "xxxx@dominio.com"
$subject = "****** Queda Poco Espacio en disco en $(hostname) ******"
$smtpserver = "server.smtp.dominio.com"
#Usuario del servidor SMTP
$user="xxxxxx@dominio.com"
#Password del servidor SMTP
$passwd = ConvertTo-SecureString "xxxxxxx" -AsPlainText -Force
$credenciales= New-Object System.Management.Automation.PSCredential ($user,$passwd)

if ([int]$DiskReportValue.FreeSpace -le $param1){
    Send-MailMessage -smtpServer $smtpserver -from $from -to $to -subject $subject -body $body -credential $credenciales
}