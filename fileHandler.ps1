param (
        $root,
        $validDate,
        $action,
        $log,
        $log_errors
    )

$logFile = $log
$errorLog = $log_errors
#$global:volume = 0

function handleOutdatedFiles ($root, $validDate, $action) {
    

    #Write-Host -ForegroundColor Magenta "ROOT: $root"
    #Write-Host -ForegroundColor Magenta "DATE: $validDate"
    #Write-Host -ForegroundColor Magenta "ACTION: $action"
    #Write-Host -ForegroundColor Magenta "ERROR: $errorLog"
    try{
        #Write-Host -ForegroundColor Cyan "ROOT: $root"
        #Write-Host -ForegroundColor Cyan "Processing data (currently processed: " -NoNewline
        $counter = 1
        Get-ChildItem $root -Force -Recurse -ErrorAction Continue | foreach {
            try{
                $item_fullname_real = ($_.FullName).ToString()
                $item_fullname = escapeSpecialChars $item_fullname_real
                #Write-Host -ForegroundColor Yellow $item_fullname
                #Write-Host "`rProcessing data (currently processed: $counter) ... " -NoNewline
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
                        #$logging = "writeFormattedListEntry `"$logPath`""
                        performActionOnOldFiles $item_fullname $outdated $logging
                        performActionOnOldFiles $item_fullname $outdated $action
                    }else{
                        #Write-Host -ForegroundColor Green $logPath
                        $logging = "writeFormattedListEntry"
                        #$logging = "writeFormattedListEntry `"$logPath`""
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
    
        #Write-Host "`n`nFinished File Hanlder`n" -ForegroundColor green
        return '__s__' + $global:volume + '__e__'
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
        #$owner = (Get-Item -LiteralPath $i -Force | Get-Acl).Owner
        $time = ($item_forTime).LastWriteTime

        $size = getSize($item)
        $global:volume += $size

        $formattedSize = formatSizeOutput($size)

        #$command = ("#> Remove-Item -Path '$item' -Recurse -force;  <#") 
        $command = ("#>Copy-Item '$item' 'P:\testLoeschen\toRemove' -Force -Recurse; <#")
        $obj = New-Object PSObject
        $obj | Add-Member NoteProperty Element($command)
        $obj | Add-Member NoteProperty Age($time)
        $obj | Add-Member NoteProperty Owner($owner)
        $obj | Add-Member NoteProperty Size($formattedSize)
        

        $mutex = new-object System.Threading.Mutex $false,'mutex'
        $mutex.WaitOne() > $null
        Out-File -Encoding UTF8 -Append -FilePath $logFile -InputObject ($obj | Format-List) -Width 1000
        $mutex.ReleaseMutex()

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

                Send-MailMessage -to "patrick.hebner@ufz.de" -from "patrick.hebner@ufz.de" -Subject "FileHandler: Removing / logging of items from >$logName< is finished with errors!" -body "Unexpected errors occurred! Please look at: $errorLog" -SmtpServer "smtp.ufz.de" -Port 587 -Credential $cred -UseSsl
        }else{
            $pw = Get-Content C:\scripte\zeitlicheLöschungScratchbereiche\MailPW.txt | ConvertTo-SecureString
            $cred = New-Object System.Management.Automation.PSCredential "hebner", $pw
            Send-MailMessage -to "patrick.hebner@ufz.de" -from "patrick.hebner@ufz.de" -Subject "FileHandler: Removing / logging of items from >$logName< is finished successfully" -body "Script is run without errors!" -SmtpServer "smtp.ufz.de" -Port 587 -Credential $cred -UseSsl
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


$global:errorEx = $false
handleOutdatedFiles $root $validDate $action