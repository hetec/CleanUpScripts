#Das Script löscht Daten nach ihrem Alter bezogen auf das Änderungsdatum

##### Parameter
param(
    [int]$max_age,
    [string]$root_dir,
    [string]$type, #remove, copy --> without just logging
    [string]$copy_dest
)

$(
$ErrorActionPreference = "Stop"
$OutputEncoding = [Console]::OutputEncoding
#start des Skriptes
$start = Get-Date
Write-Host -ForegroundColor Cyan "START: $start"

###########################################################################################################
###########################################################################################################
##### Funktionen




function checkAgePara ($age){
    Write-Host "`nChecking age parameter ..."
    if(($age -le 0)){
        Write-Host -ForegroundColor Red "`r`nNo age was defined!`r`nScript is going to use the default value of 60 days`n"
        return 60
    }else{
        return $age
    }
}

function checkRootPara ($root){
    Write-Host "`nChecking root parameter ..."
    if(($root.Length -le 0)){
        Write-Host -ForegroundColor Red "`r`nNo root directory was defined!`r`nScript is going to use the current directory: .\`n"
        return ".\"
    }else{
        return $root
    }
}

function checkTypeParameter($type, $copy_dest){
    $action = ""
    Write-Host "`nChecking type parameter ..."
    if($type -eq "remove"){
        $action = "removeFile"
        Write-Host -ForegroundColor Red "`r`nType parameter was set to remove!`r`nScirpt is going to run in remove mode!`n"
    }elseif($type -eq "copy"){
        $action = "copyFile '$copy_dest'"
       Write-Host -ForegroundColor Red "`r`nType parameter was set to copy!`r`nScirpt is going to run in copy mode!`n"
    }elseif($type -eq "log"){
       Write-Host -ForegroundColor Red "`r`nType parameter was set to log!`r`nScirpt is going to run in logging mode!`n"
    }elseif(!($type -eq "remove" -or $type -eq "copy" -or $type -eq "logging")){
        $type = "log only"
        Write-Host -ForegroundColor Red "`r`nType parameter was not defined!`r`nScirpt is going to run in logging mode!`n"
    }

    return $action
}



function getTimeStamp ($date){
    $day = $date.Day.ToString()
    $month = $date.Month.ToString()
    $year = $date.Year.ToString()
    $hour = $date.Hour.ToString()
    $min = $date.Minute.ToString()
    $sec = $date.Second.ToString()
    $stamp = "Datum $day-$month-$year Zeit $hour-$min-$sec"
    return $stamp
}



function getCriticalDate($date){
    $diff = (-1 * [int]$age)
    $criticalDate = $date.AddDays($diff)
    return $criticalDate
}

function checkLogPath(){
    try{
        if((Test-Path "$basePath\logs_$logName") -eq $false){
        #Write-Host -ForegroundColor Yellow "`r`nErstelle Log- Verzeichnis:`r`n"
                    mkdir "$basePath\logs_$logName" -Force
        }
        if((Test-Path "$basePath\loeschskripte") -eq $false){
        #Write-Host -ForegroundColor Yellow "`r`nErstelle Lösch- Verzeichnis:`r`n"
                    mkdir "$basePath\loeschskripte" -Force
        }
        if($type -eq "copy"){
            Write-Host "Create new directory for copied files ... `n"
            $exists = Test-Path $copy_dest
            if($exists -eq $true){
                Write-Host -ForegroundColor red "Destination for copying already exists -> Removing existing driectory ...`n"
                Remove-Item $copy_dest -Recurse -Force
            }
            New-Item -Type directory -Force -Path $copy_dest
        }
        #Write-Host "`r`n"
        Out-File -FilePath $errorLog -Append -InputObject "***** ERROR LOG  *****"
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: checkLogPath"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in function: checkLogPath"
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
    }
}


function writeMetaInfo($date){
    try{
        $currentDate = $date
        $criticalDate = getCriticalDate($currentDate)
        $criticalDate = $criticalDate.ToShortDateString()
        $currentDate = $currentDate.ToShortDateString()
        if($type -eq ""){$type = "log only"}
        Write-Host -ForegroundColor Cyan  "`n`n-- New Process was started -----------------------------------------`n"
        Out-File -Encoding utf8 -FilePath $log -InputObject "#### LOG FILE --> $logName ####"
        Out-File -Encoding utf8 -FilePath $log -Append -InputObject "<#"
        Out-File -Encoding utf8 -FilePath $log -Append -InputObject "Used parameter: `r`nValid age: $age"
        Out-File -Encoding utf8 -FilePath $log -Append -InputObject "Root directory: $root"
        Out-File -Encoding utf8 -FilePath $log -Append -InputObject "type: $type`n"
        Out-File -Encoding utf8 -FilePath $log -Append -InputObject "`nCurrent date:    $currentDate"
        Out-File -Encoding utf8 -FilePath $log -Append -InputObject "`nCritical date:   $criticalDate`n"
        Out-File -Encoding utf8 -FilePath $log -Append -InputObject  "`n`nREMARK: For the size the script displays decimal units. This is to confirm with the Windows way of displaying units.`n"
        Out-File -Encoding utf8 -FilePath $log -Append -InputObject  "         Nevertheless the calculation uses binary units such as KiB, MiB or GiB `n"
        Write-Host  "Valid age: $age"
        Write-Host  "Root directory: $root"
        Write-Host  "type: $type"
        Write-Host  "Current date:  " $currentDate
        Write-Host  "Critical date: " $criticalDate "`n"
        Write-Host  "`n" 
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: writeMetaInfo"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in function: writeMetaInfo"
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
    }
}


function checkErrors(){
    $errors = $error.Count
    if($errors -gt 0){
        Write-Host -ForegroundColor Red "$errors uncaught ERRORs occured"
        $global:errorEx = $true
        foreach($e in $error){
            Out-File -FilePath $errorLog -Append -InputObject "--- Uncaught errors -------------------------------------------" -ErrorAction stop
            Out-File -FilePath $errorLog -Append -InputObject $e.TargetObject -ErrorAction stop
            Out-File -FilePath $errorLog -Append -InputObject $e -ErrorAction stop
            Out-File -FilePath $errorLog -Append -InputObject "----------------------------------------------" -ErrorAction stop
        }
    }

    try{
        if($global:errorEx -eq $true){
                #Falls der Nutzer nicht mehr aktuell ist muss einmal pwCreator mit einem aktuellen Nutzer ausgeführt werden (liegt in scripte\zeitlicheLöschung...)
                $pw = Get-Content C:\scripte\zeitlicheLöschungScratchbereiche\MailPW.txt | ConvertTo-SecureString
                $cred = New-Object System.Management.Automation.PSCredential "hebner", $pw

                Send-MailMessage -to "patrick.hebner@ufz.de" -from "patrick.hebner@ufz.de" -Subject "MSG: Removing / logging of items from >$logName< is finished with errors!" -body "Unexpected errors occurred! Please look at: $errorLog" -SmtpServer "smtp.ufz.de" -Port 587 -Credential $cred -UseSsl
        }else{
            $pw = Get-Content C:\scripte\zeitlicheLöschungScratchbereiche\MailPW.txt | ConvertTo-SecureString
            $cred = New-Object System.Management.Automation.PSCredential "hebner", $pw
            Send-MailMessage -to "patrick.hebner@ufz.de" -from "patrick.hebner@ufz.de" -Subject "MSG: Removing / logging of items from >$logName< is finished successfully" -body "Script is run without errors!" -SmtpServer "smtp.ufz.de" -Port 587 -Credential $cred -UseSsl
        }
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: checkErrors"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in function: checkErrors"
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
    }
}

function writeStatistic(){
    try{
        $end = Get-Date
        $runTime = $end - $start
        Out-File -Encoding UTF8 -FilePath $log -Append -InputObject "Needed time = $runTime"
        $message = "Entire size = " + (formatSizeOutput $entire_size)
        Write-Host $message
        Out-File -Encoding UTF8 -FilePath $log -Append -InputObject $message
        Out-File -Encoding UTF8 -FilePath $log -Append -InputObject "#>"
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: writeStatistic"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in function: writeStatistic"
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
    }
}

function ani ($job) {
Write-Host "                                          " -NoNewline
    while(!($job.State -eq "Completed")){
        for($i=1;$i-lt 40;$i++){
             Write-Host "/" -NoNewline -ForegroundColor Cyan
             Start-Sleep -m 50
             if($i -eq 39){
                Write-Host " " -NoNewline -ForegroundColor Cyan
             }  
        }
        for($i=1;$i-lt 40;$i++){
             Write-Host "`b`b\" -NoNewline -ForegroundColor Red
             Start-Sleep -m 50
             if($i -eq 39){
                Write-Host "`b" -NoNewline -ForegroundColor Red
             }
        }

    }
    Write-Host ""
    Write-Host "                                                          Finished`n`n" -NoNewline -ForegroundColor Green


}

function formatSizeOutput($s){
    try{
        $s_formatiert = 0
        if($s -le 0){
            $s_formatiert = "0 B"
        }elseif(($s / 1024) -lt 1){
            $s_formatiert = "{0:N0}" -f $s + " B"
        }elseif(($s / 1024 / 1024) -lt 1){
            $s_formatiert = "{0:N0}" -f ($s / 1KB) + " KB"
        }elseif(($s / 1024 / 1024 / 1024) -lt 1){
            $s_formatiert = "{0:N0}" -f ($s / 1MB) + " MB"
        }elseif(($s / 1024 / 1024 / 1024 /1024) -lt 1){
            $s_formatiert = "{0:N0}" -f ($s / 1GB) + " GB"
        }
        return $s_formatiert
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: formatSizeOutput"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in function: formatSizeOutput"
        Out-File -FilePath $errorLog -Append -InputObject "Item: $s"
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
    }
}

#############################################################################################################################################################
#############################################################################################################################################################
##### Programmablauf
if((Test-Path variable:\errorEx) -eq $true){Clear-Variable errorEx -Force}
if((Test-Path variable:\gesamtGroesse) -eq $true){Clear-Variable gesamtGroesse -Force}
$error.Clear()
Write-Host "Cleared error: " $error.Count
$global:errorEx = $false
try{
    $today = Get-Date
    $root = checkRootPara $root_dir
    $age = checkAgePara $max_age
    $action = checkTypeParameter $type $copy_dest
    Write-Host "Root: $root"
    Write-Host "Action from parameter: $action"



    $basePath = "C:\scripte\zeitlicheLöschungScratchbereiche"
    $logName = (Get-Item -Path $root -Force).Name.ToString()
    $errorLog = $basePath + "\logs_" + $logName +  "\" + "ErrorLog" + "_" + (getTimeStamp $today) + ".txt"
}Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in preperation tasks"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in preperation tasks"
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
}

#try{
    
    #Pruefen ob Log- Pfad existierte bzw. erstellen wenn nicht
    checkLogPath

    $entire_size = 0
    #Variable Log Pfad setzen - nach aktuellen Eingangsverzeichnis
    $log = "$basePath\logs_$logName\LOG_" + (getTimeStamp $today) + ".ps1"
    $remPath = "$basePath\logs_$logName\REMOVED_" + (getTimeStamp $today) + ".ps1"
    #Temporärer Pfad für aktuell auszuführendes Löschscript
    $runScript = "$basePath\loeschskripte\tmpLoeschscript_$logName.ps1"

    writeMetaInfo $today
    #Write-Host -ForegroundColor Magenta $log
    #handleOutdatedFiles $root (getCriticalDate $today) $log $action
    #startJob $root (getCriticalDate $today) $action
    Get-Job | Stop-Job
    Get-Job | Remove-Job
    
    Write-Host -ForegroundColor Magenta $root
    $directories = Get-ChildItem $root -force
    
    $num_of_jobs = 0

    foreach ($d in $directories){
        Write-Host "Start job: " $d.BaseName
        $p = ($d.FullName).ToString()
        $job = Start-Job -FilePath "C:\scripte\zeitlicheLöschungScratchbereiche\fileHandler_v1.ps1" -ArgumentList $p, (getCriticalDate $today), $action, $log, $errorLog -Name $d.BaseName
        $num_of_jobs++
    }
    Get-Job | Out-Host
    Write-Host -ForegroundColor Yellow "Wait for $num_of_jobs jobs to be finished ... "
    Get-Job | Wait-Job
    $result = Get-Job | Receive-Job
    $pattern = '(?<=__s__)(\d+)(?=__e__)'
    $i = 0
    Select-String $pattern -input $result -AllMatches | Foreach {
        $tmp = ($_.Matches.Value)
        $arr = $tmp.Split(" ")
        foreach($a in $arr){
            $b = 0
            [int64]::TryParse($a , [ref]$b )
            $entire_size += $b
        }

    }
    #Write-Host -ForegroundColor Magenta $result
    #$job = Start-Job -FilePath "C:\scripte\zeitlicheLöschungScratchbereiche\fileHandler_v1.ps1" -ArgumentList $root, (getCriticalDate $today), $action, $log, $errorLog -Name "handler" 
    #Wait-Job -Job $job
    #$res = Receive-Job -Job $job -Keep
    #Write-Host -ForegroundColor green "Res: $res"

    writeStatistic
    checkErrors
    $end = Get-Date
    Write-Host -ForegroundColor Cyan "END: $end"
    Write-Host -ForegroundColor Cyan "DURATION: " ($end - $start)


    
<#
}Catch{
    Write-Host -BackgroundColor Yellow -ForegroundColor red "`nUnerwarteter FEHLER aufgetreten"
    $errMess = $_
    Out-File -FilePath $errorLog -Append -InputObject "Es ist ein unerwarteter Fehler bei der Durchführung des Skriptes aufgetreten! Es wird abgebrochen."
    Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess"
     
    $m = $_.Exception|format-list -force
    Out-File -FilePath $errorLog -Append -InputObject $m
    Write-Host $m
    Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"


    $pw = Get-Content C:\scripte\zeitlicheLöschungScratchbereiche\MailPW.txt | ConvertTo-SecureString
    $cred = New-Object System.Management.Automation.PSCredential "hebner", $pw
    Send-MailMessage -to "patrick.hebner@ufz.de" -from "patrick.hebner@ufz.de" -Subject "Error while removing old files form scratch on MSG" -body "General Error! Please look at: $errorLog" -SmtpServer "smtp.ufz.de" -Port 587 -Credential $cred -UseSsl

}

#>


) | Out-Null
