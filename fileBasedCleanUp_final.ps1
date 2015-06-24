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
        Write-Host -ForegroundColor Red "`r`nType parameter was set to remove!`r`nScirpt will run in remove mode!`n"
    }elseif($type -eq "copy"){
        $action = "copyFile '$copy_dest'"
       Write-Host -ForegroundColor Red "`r`nType parameter was set to copy!`r`nScirpt will run in copy mode!`n"
    }elseif($type -eq "log"){
       Write-Host -ForegroundColor Red "`r`nType parameter was set to log!`r`nScirpt will run in logging mode!`n"
    }elseif(!($type -eq "remove" -or $type -eq "copy" -or $type -eq "logging")){
        $type = "log only"
        Write-Host -ForegroundColor Red "`r`nType parameter was not defined!`r`nScirpt will run in logging mode!`n"
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
    $stamp = "Date $day-$month-$year Time $hour-$min-$sec"
    return $stamp
}

function getCriticalDate($date){
    $diff = (-1 * [int]$age)
    $criticalDate = $date.AddDays($diff)
    return $criticalDate
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
        Out-File -Encoding utf8 -FilePath $logPath -InputObject "#### LOG FILE --> $logName ####"
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "<#"
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "Used parameter: `r`nValid age: $age"
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "Root directory: $root"
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "type: $type`n"
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "`nCurrent date:    $currentDate"
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "`nCritical date:   $criticalDate`n"
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject  "`n`nREMARK: For the size the script displays decimal units. This is to confirm with the Windows way of displaying units.`n"
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject  "         Nevertheless the calculation uses binary units such as KiB, MiB or GiB `n"
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


function getSize($element){
    try{
        $size = Get-Item -LiteralPath $element -Force | Measure-Object -Property Length -sum
        return $size.sum
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: getSize"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in function: getSize"
        Out-File -FilePath $errorLog -Append -InputObject "Item: $element"
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
    }
}

function copyFile ($dest, $item) {
    #New-Item -Type directory -Force -Path $dest
    try{
        $it = Get-Item $item -Force
        $ex = ($dest + "\" + $it.BaseName)
        $new_dest = $ex
        if(Test-Path $ex){
            $new_dest = $ex + "_copy"
        }
        Copy-Item $item $new_dest -Force -Recurse

    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: copyFile"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in function: copyFile"
        Out-File -FilePath $errorLog -Append -InputObject "Item: $item"
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
    }   
}


function removeFile ($item) {
    #New-Item -Type directory -Force -Path $dest
    try{
        Remove-Item $item -Force -Recurse
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: removeItem"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in function: copyFile"
        Out-File -FilePath $errorLog -Append -InputObject "Item: $item"
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

function performActionOnOldFiles($item, $tooOld, $action){
    try{
        if($tooOld){
            #Write-Host -ForegroundColor Cyan "nEscaped: $item"
            #$item = escapeSpecialChars $item
            $tmp_action = "$action `"$item`""
            #Write-Host -ForegroundColor Yellow "Old: $tmp_action"
            try{
                Invoke-Expression $tmp_action
            }Catch{
                $tmp_action = "$action '$item'"
                #Write-Host -ForegroundColor red "New: $tmp_action"
                Invoke-Expression $tmp_action
            }
        } 
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: performActionOnOldFiles"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in function: performActionOnOldFiles"
        Out-File -FilePath $errorLog -Append -InputObject "Item: $item"
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
    }
}

function escapeBrackets($string){
    $escaped = $string.Replace("[","``[")
    $escaped = $escaped.Replace("]","``]")

    return $escaped
}

function escapeSpecialChars($string){
    $escaped = $string.Replace("(","`(")
    $escaped = $escaped.Replace(")","`)")
    $escaped = $escaped.Replace("{","`{")
    $escaped = $escaped.Replace("}","`}")
    $escaped = $escaped.Replace("$","``$")
    $escaped = $escaped.Replace("|","`|")
    $escaped = $escaped.Replace("^","`^")
    $escaped = $escaped.Replace("+","`+")
    $escaped = $escaped.Replace("*","`*")
    $escaped = $escaped.Replace("`"",'`"')

    return $escaped

}


function checkAge($actualAge, $validdAge){
    try{
        if($actualAge -lt $validdAge){
            return $true
        }else{
            return $false
        }
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: checkAge"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in function: checkAge"
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
    }
}
#"&'F:\scratchold\meyerm\s2\Mississippi_agricultural_assessment\SSURGO\wss_SSA_AR041_soildb_US_2003_[2013-12-23]\soildb_US_2003.mdb'"
function handleOutdatedFiles ($root, $validDate, $action) {
    try{
        Write-Host -ForegroundColor Cyan "Processing data (currently processed: " -NoNewline
        $counter = 1
        Get-ChildItem $root -Force -Recurse -ErrorAction Continue | foreach {
            try{
                $item_fullname_real = ($_.FullName).ToString()
                $item_fullname = escapeSpecialChars $item_fullname_real
                #Write-Host -ForegroundColor Yellow $item_fullname
                Write-Host "`rProcessing data (currently processed: $counter) ... " -NoNewline
                $counter++
                try{
                    $isFile = !(Test-Path -LiteralPath $item_fullname -PathType Container)
                }Catch{
                    #Write-Host -ForegroundColor Red "Catch Error"
                    #$item_fullname_replaced = $item_fullname.Replace("[","``[")
                    #$item_fullname_replaced = $item_fullname.Replace("]","``]")
                    $item_fullname = escapeBrackets $item_fullname
                    $isFile = !(Test-Path -LiteralPath $item_fullname -PathType Container)
                    #Write-Host -red "ISFILE IN? $isFile"
                    #Write-Host -ForegroundColor Yellow "Replaced: $item_fullname$item_fullname"
                }
                #Write-Host -red "ISFILE OUT? $isFile"
                if($isFile -eq $true){
                    $outdated = checkAge $_.LastWriteTime $validDate
                    if($action.Length -gt 0){
                        #Write-Host -ForegroundColor Green $logPath
                        $logging = "writeFormattedListEntry"
                        performActionOnOldFiles $item_fullname $outdated $logging
                        performActionOnOldFiles $item_fullname $outdated $action
                    }else{
                        #Write-Host -ForegroundColor Green $logPath
                        $logging = "writeFormattedListEntry"
                        performActionOnOldFiles $item_fullname $outdated $logging
                    }
                }
                #Write-Host -ForegroundColor Yellow "done"
            }Catch{
                Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: handleOutdatedFiles while looping through files"
                Out-File -FilePath $errorLog -Append -InputObject "Exception in function: handleOutdatedFiles while looping through files"
                Out-File -FilePath $errorLog -Append -InputObject "Item: $item_fullname_real"
                $m = $_.Exception|format-list -force
                Out-File -FilePath $errorLog -Append -InputObject $m
                Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
                $global:errorEx = $true
            }
        }
    
        Write-Host "`n`nFinished`n" -ForegroundColor green
    
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: handleOutdatedFiles"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in function: handleOutdatedFiles"
        Out-File -FilePath $errorLog -Append -InputObject "Item: $item_fullname_real"
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
    }
}

#Funktionen zum formatieren der Ausgabedatei
#Formatiert die einzelnen Zeilen eines Eingangsarray und speichert sie in einem neuen
function writeFormattedListEntry ($i){
    try{
        #Write-Host -ForegroundColor green "i: $i"
        #$item = escapeSpecialChars $i
        $item = $i
        try{
        $item_forTime = (Get-Item -LiteralPath $item -Force)
        }Catch{
            #Write-Host -ForegroundColor Red "CATCH"
            $item = escapeBrackets $i
            $item_forTime = (Get-Item -LiteralPath $item -Force)
        }
        
        #Write-Host "In Write List: $item"
        #$owner = (Get-Acl ($item)).Owner
        $owner = (Get-Item -LiteralPath $i -Force | Get-Acl).Owner
        $time = ($item_forTime).LastWriteTime

        $size = getSize($item)
        $global:gesamtGroesse += $size

        $formattedSize = formatSizeOutput($size)

        #$command = ("#> Remove-Item -Path '$item' -Recurse -force;  <#") 
        $command = ("#>Copy-Item '$item' 'P:\testLoeschen\toRemove' -Force -Recurse; <#")
        $obj = New-Object PSObject
        $obj | Add-Member NoteProperty Element($command)
        $obj | Add-Member NoteProperty Age($time)
        $obj | Add-Member NoteProperty Owner($owner)
        $obj | Add-Member NoteProperty Size($formattedSize)
        
        Out-File -Encoding UTF8 -Append -FilePath $logPath -InputObject ($obj | Format-List) -Width 1000

    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "`nException in function: formatListEntry"
        Out-File -FilePath $errorLog -Append -InputObject "Exception in function: formatListEntry"
        Out-File -FilePath $errorLog -Append -InputObject "Item: $item"
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
        Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Needed time = $runTime"
        $message = "Entire size = " + (formatSizeOutput $global:gesamtGroesse)
        Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject $message
        Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "#>"
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
    $global:gesamtGroesse = 0.0



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

try{
    
    #Pruefen ob Log- Pfad existierte bzw. erstellen wenn nicht
    checkLogPath


    #Variable Log Pfad setzen - nach aktuellen Eingangsverzeichnis
    $logPath = "$basePath\logs_$logName\LOG_" + (getTimeStamp $today) + ".ps1"
    $remPath = "$basePath\logs_$logName\REMOVED_" + (getTimeStamp $today) + ".ps1"
    #Temporärer Pfad für aktuell auszuführendes Löschscript
    $runScript = "$basePath\loeschskripte\tmpLoeschscript_$logName.ps1"

    writeMetaInfo $today
    handleOutdatedFiles $root (getCriticalDate $today) $action 
    writeStatistic
    checkErrors
    $end = Get-Date
    Write-Host -ForegroundColor Cyan "END: $end"
    Write-Host -ForegroundColor Cyan "DURATION: " ($end - $start)


    

}Catch{
    Write-Host -BackgroundColor Yellow -ForegroundColor red "`nUnerwarteter FEHLER aufgetreten"
    $errMess = $_.Exception.Message
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




) | Out-Null
