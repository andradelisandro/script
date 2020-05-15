############################################
# @Autor: AndradeLisandro 
# Run: PowerShell -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File .\Upload_Files_to_FTP_Dev.ps1
# Descripcion: Lee un arbol de directorio  
#              Guardar en el FTP con el mismo arbol de directorio
#              Genera un Logs de todo lo que hace
#              Comprime con 7z todo lo archivos .back que son archivos de backup de BD
#              Copia de un directorio a otro
#              Eliminar los archivos ya respaldo en el FTP (Esta variable indica la cantida $amountArchiveFtp)
#              Elimina los archivos locales(Esta variable indica la cantida $amountArchiveServer)
# @Variable:
# Nota: 
# Fecha: 


#set-psdebug -trace 1;
Write-Host "START Upload Files from Folder to FTP";
$ftp = "ftp://xxxxxxxxxxxxxxxxxxxxxxxxxxxx";
$username = "xxxxxxxxxxxxxxx";
$password = "xxxxxxxxxxxxxxxxxxx";
$folder = "C:\Backups" #Directorio rail para ejecutar el script
$folderLog = "\__Log"
#$path_7z="C:\Program/ Files\7-Zip\7z.exe"
$logPath = Join-Path -Path $folder$folderLog -ChildPath ("CompressArchive_Sql_Bak_Files_"+(Get-Date -UFormat "%Y_%m_%d")+".log")
$ExcludeFolder = "__*"
$bckupFolders = Get-ChildItem -Directory -Path $folder -Exclude  $ExcludeFolder
$ArchiveFolder = "_ARCHIVE"
$FileFilterCompress = "*.7z"
$FileFilterBackup = "*.bak"
$FileFilterlog= "*.log" 
$MaxLog = 5
#$amountArchive = 10
$amountArchiveFtp = 15
$amountArchiveServer = 2

# Alias for 7-zip 
if (-not (test-path "$env:ProgramFiles\7-Zip\7z.exe")) {
    throw "$env:ProgramFiles\7-Zip\7z.exe not found"
} 
set-alias 7z "$env:ProgramFiles\7-Zip\7z.exe" 

function New-FtpRequest ($sourceUri, $method, $username, $password) {
    $ftprequest = [System.Net.FtpWebRequest]::Create($sourceuri)
    $ftprequest.Method = $method
    $ftprequest.Credentials = New-Object System.Net.NetworkCredential($username,$password)
    return $ftprequest
}

function Send-FtpRequest($ftpRequest) {
    #Write-Host "$($ftpRequest.Method) for '$($ftpRequest.RequestUri)' executing"
    $response = $ftprequest.GetResponse()
    $closed = $response.Close()
    Write-Host "Response:" $($response.StatusDescription)
    return $response
}

function Add-FtpDirectory($ftpFolderPath, $username, $password) {
    try {
          $ftprequest = New-FtpRequest -sourceUri $ftpFolderPath -method ([System.Net.WebRequestMethods+Ftp]::MakeDirectory) -username $username -password $password
          $response = Send-FtpRequest $ftprequest
     } catch {
           Write-Host "Creating folder '$ftpFolderPath' failed, maybe because this folder already exists."
     }
}

#SIN USAR pero funciona pero no demanera recursiva
function Remove-FtpDirectory($ftpFolderPath, $username, $password) {
    $ftprequest = New-FtpRequest -sourceUri $ftpFolderPath -method ([System.Net.WebRequestMethods+Ftp]::RemoveDirectory) -username $username -password $password    
    $response = Send-FtpRequest $ftprequest
}

function Remove-FtpFile($ftpFilePath, $username, $password) {
    $ftprequest = New-FtpRequest -sourceUri $ftpFilePath -method ([System.Net.WebRequestMethods+Ftp]::DeleteFile) -username $username -password $password    
    $response = Send-FtpRequest $ftprequest
}

function Add-FtpFile($ftpFilePath, $localFile, $username, $password) {
    try {
        $ftprequest = New-FtpRequest -sourceUri $ftpFilePath -method ([System.Net.WebRequestMethods+Ftp]::UploadFile) -username $username -password $password
        Write-Host "$($ftpRequest.Method) UPLOAD '$($ftpRequest.RequestUri)'"
        # # $content = [System.IO.File]::ReadAllBytes($localFile)
        # # $ftprequest.ContentLength = $content.Length 
        # # $requestStream = $ftprequest.GetRequestStream()       
        # # $requestStream.Write($content, 0, $content.Length)
        # # $requestStream.Close()
        # # $requestStream.Dispose()
        # $bufsize = 2048
        # $requestStream = $ftprequest.GetRequestStream()
        # $fileStream = [System.IO.File]::OpenRead($localFile)
        # $chunk = New-Object byte[] $bufSize
    
        # while ( $bytesRead = $fileStream.Read($chunk, 0, $bufsize) ){
        #     $requestStream.write($chunk, 0, $bytesRead)
        #     $requestStream.Flush()
        # }
        # $FileStream.Close()
        # $requestStream.Close()
        $fileStream = [System.IO.File]::OpenRead($localFile)
        $ftpStream = $ftprequest.GetRequestStream()

        $buffer = New-Object Byte[] 10240
        while (($read = $fileStream.Read($buffer, 0, $buffer.Length)) -gt 0)
        {
            $ftpStream.Write($buffer, 0, $read)
            $pct = ($fileStream.Position / $fileStream.Length)
            Write-Progress `
                -Activity "Uploading" -Status ("{0:P0} complete:" -f $pct) `
                -PercentComplete ($pct * 100)
        }
        $fileStream.CopyTo($ftpStream)
        $ftpStream.Dispose()
        $fileStream.Dispose()
        $response = Send-FtpRequest $ftprequest
    } 
    catch
    {                   
        Write-Warning "Unable to upload '$ftpFilePath' because: $($_.exception)"
        Stop-Transcript
    }
}

function Parse-Output($output, [System.Management.Automation.SwitchParameter]$file, [System.Management.Automation.SwitchParameter]$directory) {
    $entities = @()
    foreach ($CurLine in $output) {
        $LineTok = ($CurLine -split '\ +')
        $currentEntity = $LineTok[8..($LineTok.Length-1)]
        if(-not $currentEntity) { continue }
        $isDirectory = $LineTok[0].StartsWith("d")
        if($file -and -not $isDirectory) {
            $entities += $currentEntity
        } elseif($directory -and $isDirectory) {
            $entities += $currentEntity
        }
    }
    return $entities
}

function Get-FtpChildItem($ftpFolderPath, $username, $password, [System.Management.Automation.SwitchParameter]$file, [System.Management.Automation.SwitchParameter]$directory) {
    $ftprequest = New-FtpRequest -sourceUri $ftpFolderPath -method ([System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails) -username $username -password $password
    $FTPResponse = $ftprequest.GetResponse()
    $ResponseStream = $FTPResponse.GetResponseStream()
    $StreamReader = New-Object System.IO.Streamreader $ResponseStream
    $DirListing = (($StreamReader.ReadToEnd()) -split [Environment]::NewLine)
    $StreamReader.Close()
    $FTPResponse.Close()
    $entities = @()
   
    (Parse-Output -output $DirListing -Directory:$directory -File:$file ) | foreach {
        $entities += "$($ftpFolderPath)/$($_)"
    }
    return $entities
}
function RemoveLogFilesBut($folder,$MaxLog,$FileFilterlog){
    Write-host "Clean Log START ******* " $folder
    Get-ChildItem $folder -filter $FileFilterlog|
        sort LastWriteTime -Descending |
        Select-Object -Skip $MaxLog |
        Remove-Item
    Write-host "Clean Log END "
}
function CopyERP ($folder,$FileFilterCompress){
    $originPath = $folder + "\" + "ERP\"
    $destinationPath = $folder + "\" + "ERPExterno\" + $ArchiveFolder + "\"

    Write-host "Move Dirmod ERP to ERPExterno -> START"

    $bkupFiles = Get-ChildItem $originPath -Filter $FileFilterCompress |
        sort LastWriteTime -Descending |
        Select-Object

    Foreach($bkupFile in $bkupFiles) {
        Write-host "START -> Moving -> " $bkupFile.FullName
    
        $destinationFile = $destinationPath + $bkupFile.Name
    
        Write-host "Moving To -> "$destinationFile

        Copy-Item -Path $bkupFile.FullName -Destination $destinationFile

        Write-host "END -> Moving"
    }

    Write-host "Move ERP to ERPExterno -> END"
}
function CompressArchive_Sql_Bak_Files($folder,$archiveFolder,$FileFilterCompress,$FileFilterBackup,$ExcludeFolder,$amountArchiveServer) {
    $scriptDir = $folder

    $bckupFolders = Get-ChildItem -Directory -Path $scriptDir -Exclude $ExcludeFolder

    Foreach($bkupFolder in $bckupFolders) {
        $folderPath =  $bkupFolder.FullName + "\"
        Write-host "Processing -> " $folderPath
        CompressArchiveBakFiles -folder $folderPath -archiveFolder $ArchiveFolder -FileFilterBackup $FileFilterBackup -FileFilterCompress $FileFilterCompress -amountArchiveServer $amountArchiveServer
    }

}
function CompressArchiveBakFiles ($folder,$archiveFolder,$FileFilterBackup,$FileFilterCompress,$amountArchiveServer){
   
    Write-Host "Compress & Archive files START"

    $archiveFolderPath = Join-Path -Path $folder -ChildPath $archiveFolder

    #Write-Host "Ensure Destination Exist"
    #New-Item -ItemType Directory -Force -Path $archiveFolderPath

    #Write-Host "Clean Up 7z Files except Newer BkUp START EXCEPT " $firstZipPath

    $zipToDelete = Get-Childitem -Path $folder -filter $FileFilterCompress  | 
        sort LastWriteTime -Descending |
        Select-Object -Skip 1
    
        
    if($zipToDelete){
        Write-Host " zipToDelete *** " $zipToDelete.FullName
        Remove-Item $zipToDelete.FullName
    }

    #Write-Host "Getting Files"
    $files = get-childitem -Path $folder -filter $FileFilterBackup | sort LastWriteTime -Descending
    Write-Host "Getting Files ******* "   $files
    
    $isFirstFile = $true
    $restoreFirstFilePath = $folder
    $firstZipPath = $false
    Foreach ($file in $files)
    {
        $destinationArchiveFile = Join-Path -Path $archiveFolderPath -ChildPath ($file.BaseName + ".7z")
        $filePath = Join-Path -Path $folder -ChildPath $file

        Write-Host "Compressing" $filePath " -> " $destinationArchiveFile "START"
        
        #Compress-Archive -Update -Path $filePath -CompressionLevel Optimal -DestinationPath $destinationArchiveFile
        7z a -tzip -mx9 "$destinationArchiveFile" "$filePath"

        Write-Host "Compressing END"
        #copia el ultimo backup a la raiz de la carpeta
        if($isFirstFile  -eq $true){
            Write-Host "Restoring First File *******  " $file
            Copy-Item $destinationArchiveFile -Destination $restoreFirstFilePath
            $isFirstFile = $false
            $firstZipPath = Join-Path -Path $restoreFirstFilePath -ChildPath ($file.BaseName + ".7z")
        }
        # Comprime todo lo .back y deja un respaldo del ultimo back comprimido
        Write-Host "Remove Compressed File START" 
        Write-Host $file.FullName
        Remove-Item –path $file.FullName
        Write-Host "Remove Compressed File END"   
    }
    Write-Host "Compress & Archive files END"

    Write-Host "END SHRINK"
}
function Upload-FtpFile ($bckupFolders,$username, $password,$FileFilterCompress,$ftp){
    Write-Host "Upload Files FTP START "
    $FptDirectories = Get-FtpChildItem -ftpFolderPath $ftp -username $username -password $password -Directory
    Foreach($bkupFolder in $bckupFolders) {
        $DirectoryExist = $false
        $folderPath =  $bkupFolder.Name + "\"
        $folderPathRemplace = $folderPath.replace("\","").Trim()
        IF ([string]::IsNullOrWhitespace($FptDirectories)) {
            Add-FtpDirectory -ftpFolderPath $ftp$folderPath -username $username -password $password
            Write-host "Creando Directorio *******  " $folderPath
        }
        Foreach($FptDirectorie in $FptDirectories) {
            $FtpDirectoriesSplit = $FptDirectorie.Split("{//}")    
            $FtpDirectoryName = $FtpDirectoriesSplit[6].Trim()
            If ($folderPathRemplace -match $FtpDirectoryName ){
                $DirectoryExist = $true
                break
            }
        }
        IF($DirectoryExist -eq $false){
            Add-FtpDirectory -ftpFolderPath $ftp$folderPath -username $username -password $password
            Write-host "Creando Directorio *******  " $folderPath
        }  
    
        $FptDirectoriesFiles = Get-FtpChildItem -ftpFolderPath $ftp$folderPath -username $username -password $password -File
        $PathFiles = $folder+"\"+$folderPath+$ArchiveFolder
        $CountLocalFiles = Get-ChildItem $PathFiles -Filter $FileFilterCompress  | %{$_.Count}
        $LocalFiles = Get-ChildItem -Path $bkupFolder\$ArchiveFolder -filter  $FileFilterCompress  | sort LastWriteTime -Descending
        Foreach ($LocalFile in $LocalFiles){
            $FileExist = $false
            Foreach($FptDirectoriesFile in $FptDirectoriesFiles) {
                $FtpFileSplit = $FptDirectoriesFile.Split("{/}")    
                $FtpFileName = $FtpFileSplit[6].Trim()
                If ($LocalFile -match $FtpFileName ){
                    $FileExist = $true
                    break
                }
            }
            IF($FileExist -eq $false){
                Add-FtpFile -ftpFilePath $ftp$folderPath$LocalFile -localFile $PathFiles\$LocalFile -username $username -password $password
            } 
        }
    }
    Write-Host "Upload Files FTP END "
}
function Delete-ServerFile ($folder,$ExcludeFolder,$ArchiveFolder,$username,$password,$amountArchiveServer){
    Write-Host "Remove Files Server START "
    $bckupFolders = Get-ChildItem -Directory -Path $folder -Exclude $ExcludeFolder
    Foreach($bkupFolder in $bckupFolders) {
        $folderPath =  $bkupFolder.FullName + "\" + $ArchiveFolder
        $folderName =  $bkupFolder.Name
        $FptFiles = Get-FtpChildItem -ftpFolderPath $ftp$folderName -username $username -password $password -File | Sort-Object
        $listFile= Get-ChildItem -Path $folderPath | sort LastWriteTime -Descending | Select-Object -Skip $amountArchiveServer 
        $listFilesCount = $listFile.Count
        if($listFilesCount -ge 1){
            For ($i=0; $i -lt $listFilesCount; $i++) {
                $ServerFilesOne =$listFile[$i]
                Foreach($FptFile in $FptFiles) {
                    $FtpFileSplit = $FptFile.Split("{/}")    
                    $FtpFileName = $FtpFileSplit[6].Trim()
                    If ($FtpFileName -match $ServerFilesOne){
                        Write-Host "Remove File ******* " $folderPath\$ServerFilesOne
                        Remove-Item –path $folderPath\$ServerFilesOne
                        break
                    }
                }
            }
        }
    }
    Write-Host "Remove Files Server END"
}

function Delete-FtpFile ($ftpFolderPath,$username,$password,$amountArchiveFtp){
    Write-Host "Delete Files FTP START "
    $FptDirectoryAll = Get-FtpChildItem -ftpFolderPath $ftp -username $username -password $password -Directory
    $CountFptDirectoryAll = $FptDirectoryAll.Count
    Foreach($FptDirectoryOne in $FptDirectoryAll) {
        $FptDirectoryOneSplit = $FptDirectoryOne.Split("{//}")    
        $FptDirectoryOneName = $FptDirectoryOneSplit[6].Trim()
        $FptFilesAll = Get-FtpChildItem -ftpFolderPath $ftp$FptDirectoryOneName -username $username -password $password -File 
        $CountFptFilesAll = $FptFilesAll.Count
        if($CountFptFilesAll -gt $amountArchiveFtp){
            $FptFilesOrder = $FptFilesAll | Sort-Object -Descending
            For ($i=$amountArchiveFtp; $i -lt $CountFptFilesAll; $i++) {
                $FptFilesOne =$FptFilesOrder[$i]
                Remove-FtpFile -ftpFilePath $FptFilesOne -username $username -password $password
                Write-host "DELETE FILE ******* " $FptFilesOne
            }
        }
    }
    Write-Host "Delete Files FTP END "
}

Start-Transcript -path $logPath -append
    CompressArchive_Sql_Bak_Files -folder $folder -archiveFolder $ArchiveFolder -FileFilterCompress $FileFilterCompress -FileFilterBackup $FileFilterBackup -ExcludeFolder $ExcludeFolder -amountArchiveServer $amountArchiveServer
    CopyERP -folder $folder -FileFilterCompress $FileFilterCompress
    RemoveLogFilesBut -folder $folder$folderLog -MaxLog $MaxLog -FileFilterlog $FileFilterlog
    Upload-FtpFile -bckupFolders $bckupFolders -username $username -password $password -FileFilterCompress $FileFilterCompress -ftp $ftp
    Delete-FtpFile ftpFolderPath -$ftp -username $username -password $password -amountArchiveFtp $amountArchiveFtp
    Delete-ServerFile -folder $folder -ExcludeFolder $ExcludeFolder -ArchiveFolder $ArchiveFolder -username $username -password $password -amountArchiveServer $amountArchiveServer
Stop-Transcript