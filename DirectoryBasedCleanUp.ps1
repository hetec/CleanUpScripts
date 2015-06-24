#Das Script löscht Daten nach ihrem Alter bezogen auf das Änderungsdatum

##### Parameter
param(
    [int]$Alter,
    [string]$Pfad,
    [string]$ErsteVerzEbeneErhalten,
    [string]$loeschen,
    [string]$copyTo
    #[string]$typ
)

$(
$ErrorActionPreference = "Stop"
$OutputEncoding = [Console]::OutputEncoding
#start des Skriptes
$start = Get-Date


#Prüft die Parametereingaben


if(($Pfad.Length -le 0)  -and ($Alter -gt 0)){
    Write-Host -ForegroundColor Red "`r`nEs wurde kein Pfad angegeben!`r`nDer aktuelle Pfad wird verwendet: .\"
    $Pfad = '.\'
}elseif(($Alter -le 0) -and ($Pfad.Length -gt 0)){
    Write-Host -ForegroundColor Red "`r`nEs wurde kein Alter angegeben!`r`nDas Standardalter von 60 Tagen wird verwendet"
    $Alter = 60
}elseif(($Alter -le 0) -and ($Pfad.Length -le 0)){
    Write-Host -ForegroundColor Red "`r`nEs wurde kein Pfad und kein Alter angegeben!`r`nStandardwerte --> Pfad: .\ --> Alter 60 Tage werden verwendet"
    $Alter = 60
    $Pfad = '.\'
}

if($copyTo.Length -le 0){
    Write-Host -ForegroundColor Yellow "`r`nDaten werden nicht kopiert!"
}else{
    Write-Host -ForegroundColor Yellow "`r`nDaten werden nach $copyTo kopiert!"
}

<#
if($typ -eq "lat"){
    $typ = "lat"
}elseif($typ -eq "lwt"){
    $typ = "lwt"
}elseif($typ -ne "lwt" -or $typ -ne "lat"){
    $typ = "lwt" #Default
    Write-Host -ForegroundColor Red "`r`nEs wurde kein Typ angegeben!`r`nDer Standardtyp (lwt) wird verwendet!"
}
#>
$typ = "lwt" #Nur noch lwt möglich

if(($ErsteVerzEbeneErhalten -ne "true") -and ($ErsteVerzEbeneErhalten -ne "false")){
    $ErsteVerzEbeneErhalten = $false #Default
}elseif($ErsteVerzEbeneErhalten -eq "true"){
    $ErsteVerzEbeneErhalten = $true
}elseif($ErsteVerzEbeneErhalten -eq "false"){
    $ErsteVerzEbeneErhalten = $false
}

if(($loeschen -ne "false") -and ($loeschen -ne "true")){
     Write-Host -ForegroundColor Red "`r`nKein Wert fuer loeschen angegeben: Standard wird versendet: 'false'"
     $loeschen = "false"
}elseif($loeschen -eq "true"){
    Write-Host -ForegroundColor Yellow "`r`nAchtung! Löschen ist aktiv!"
    $loeschen = $true
}elseif($loeschen -eq "false"){
    Write-Host -ForegroundColor Yellow "`r`nAchtung! Es wird nur geloggt!"
    $loeschen = $false
}


#Variablen deklarieren und initialisieren

#Startverzeichnisse
$zuPruefendesDir = $Pfad

#Basispfad für das Verzeichnis indem Logs gespeichert werden
$basisPfad = "C:\scripte\zeitlicheLöschungScratchbereiche"

#aktuelles Datum
$datum = Get-Date

#Datumsstempel für Logfile Bezeichnung
$tag = $datum.Day.ToString()
$monat = $datum.Month.ToString()
$jahr = $datum.Year.ToString()
$stunde = $datum.Hour.ToString()
$min = $datum.Minute.ToString()
$sek = $datum.Second.ToString()
$dateStemp = "Datum $tag-$monat-$jahr Zeit $stunde-$min-$sek"

#Gibt die Differnz zum aktullen Datum an (Alter der Daten) in ganzen Tagen
$delta = (-1 * [int]$Alter)
#Berechnet das Datum das die Daten nicht überschreiten dürfen
$kritischesDatum = $datum.AddDays($delta)

$aktuellesdatum = $datum




#Globale Arrays zum zwischenspeichern der zu löschenden Ordner
#Werden Zurückgesetz wenn noch alte bestehen
if((Test-Path variable:\arr) -eq $true){Clear-Variable arr -Force}
if((Test-Path variable:\o) -eq $true){Clear-Variable o -Force}


$global:arr = @() #Zwischenspeicher zu löschender Dir
$global:o = @() #Zwischenspeicher zu löschender Dir - formatiert für Ausgabe
$global:tmp = @()
$eltern = @() #Speichert Änderungsdatum von Elternelementen von gelöschten Dir
$global:gesamtGroesse = 0.0
$global:gesamtAnzahl_f = 0
$global:gesamtAnzahl_o = 0
$global:gesamtAnzahl = 0


$logName = (Get-Item -Path $Pfad -Force).Name.ToString()
#Write-Host -ForegroundColor white "$basisPfad\loeschskripte\tmpLoeschscript_$logName.ps1"


$global:errorEx = $false
$global:errorCode = 0
$errorLog = $basisPfad + "\logs_" + $logName +  "\" + "ErrorLog" + "_" + $dateStemp + ".txt"

###########################################################################################################
###########################################################################################################
##### Funktionen

#Funktion zum Beschaffen der Ordner - Datein werden vernachlässigt da diese nicht geprüft werden sollen
#Leere Verezeichnisse werden zur Notiz auch aufgelistet
function getInahlt($start){
   #try{
   
       # Write-Host -ForegroundColor DarkGray "`r`nInhalt des Verzeichnisses $start wird ermittelt ... "

       ###NEU
       if(Test-Path $start -pathType container){
            $temp = Get-ChildItem $start -Force
            if ($temp){

                #Write-Host -ForegroundColor DarkGreen "Verzeichnis ist nicht leer!"
                return $temp
            
            }else{
                return $false
            }
        }else{
            return $false
        }
    <#}Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in getInhalt!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in GetInhalt"
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorCode = 1
        $global:errorEx = $true
    }#>
  
    
}

##################################################################################################

#Funktion zum prüfen des Alters bei LWT
#Veraltete Verzeichnisse werden in globalem Array: $global:arr zwischengespeichert


function pruefeVeraltetAlleElemente_lwt($inhalt){
    try{

        #Liste als Zwischenspeicher
        $liste = New-Object System.Collections.ArrayList
        $newList = New-Object System.Collections.ArrayList
        #Liste mit zu Löschenden Verz
        $resultList = New-Object System.Collections.ArrayList
        #initiales Befüllen der Liste
        foreach($el in $inhalt){
            $buffer = $liste.Add($el) 
            if(pruefeVeraltet $el){
                ###NEU
                if(Test-Path ($el.Fullname).toString() -pathType container){
                    $resultList.Add(($el.Fullname).toString())
                }

                ###OLD### $resultList.Add(($el.Fullname).toString())
            }
        }
        $size = $resultList.Count;
        #Write-Host -ForegroundColor yellow ("Result-Size(Initial): $size")
        #Write-Host "`n-- Anfangsinhalt des Verzeichnisses: --------------------------------`n"
        #Write-Host "$resultList"
        #$resultList | Format-List
        #Write-Host "`n---------------------------------------------------------------------`n"
        $listenLaenge = $liste.Count
        $ebenenConter = 1
        while($listenLaenge -gt 0){
            #write-host  -ForegroundColor green "`nAkteueller Zwischenstand"
            #Write-Host "----------------------------------------------------"
            #Write-Host "Inhalt: $resultList`n"

            #write-host -BackgroundColor red -ForegroundColor white "`nNeue Liste der Länge $listenLaenge wird verarbeitet"
            #Write-Host "----------------------------------------------------"
            #Write-Host "Inhalt: $liste`n"
            Write-Host "Prüfe Ordnerebene #$ebenenConter"
            pruefeVerzeichnisse $liste
            $ebenenConter++
            #$liste = $newList
            $liste.Clear()
            $listenLaenge1 = $liste.Count
            #Write-Host -BackgroundColor red -ForegroundColor White "Liste leer?: $listenLaenge1"
            foreach($e in $newList){
                $x = $liste.Add($e) 
            }
            #Write-Host -BackgroundColor red -ForegroundColor White "LISTE: $liste"
            $listenLaenge = $liste.Count 
            $newList.Clear()

       
            #Write-Host -BackgroundColor red -ForegroundColor White "LISTENLAENGE: $listenLaenge"
 
        }
    
 
    
        #Write-Host "`n-- Resultat: ----------------------------------------------`n"
        #Write-Host "$resultList"
        #$resultList | sort -Descending |Format-List | Out-Host
        #write-Host "`n-----------------------------------------------------------`n"    
        #Write-Host -ForegroundColor White "`n`nÜbertrage Elemente ... `n"  
        #foreach($el in $resultList){
            #Write-Host $el
            #$tmp = ($el.Fullname)
            #$global:arr = 
        #}
        $global:arr = $resultList.toArray()
        #Write-Host "Global Array:  $global:arr"
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in pruefeVeraltetAlleElemente_lwt!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in pruefeVeraltetAlleElemente_lwt"
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorCode = 1
        $global:errorEx = $true
    }
}

#funktion zum Prüfen des Alters eines Elements
function pruefeVeraltet($element){
    try{

        #Write-Host "Starte: pruefeVeraltet auf :: $element"
        $lwt = $element.lastwritetime
        if(($element.lastWriteTime) -lt $kritischesDatum){
            #Write-Host -ForegroundColor red "Veraltet ---> $element"
            return $true
            }else{
            #Write-Host -ForegroundColor green "Aktuell ----> $element"
            return $false
            }
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in pruefeVeraltet!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in pruefeVeraltet"
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorCode = 1
        $global:errorEx = $true
    }
}

#Funktion sucht die veralteteten Verzeichnisse aus dem Verzeichnisbaum
function pruefeVerzeichnisse($list){
    for($i = 0; $i -lt $list.Count; $i++){

        #$p = ($list[$i].Fullname).toString()
        #if((Test-Path $p) -eq $true){

        try{

            $name = ($list[$i]).toString()
            $nameFull = (($list[$i]).Fullname).toString()
            #Write-Host "`nElternelement:" $list[$i].Fullname
            #Write-Host "`nGeholte Kindelemente: $kinder`n"
            $alleKinderAlt = $true
            $isNoItem = $true
        
            $zuPr = ($list[$i]).toString();
            Write-Progress -Activity "Suche veraltete Verzeichnisse in $Pfad" -PercentComplete (($i * 100)/($list.Count)) -Status "Aktuell zu prüfen: $zuPr"
            #Zu erst prüfen ob alle Kinder eines Elements veraltet sind
            #JA --> Element bleibt --> Kinder weiter prüfen
            #NEIN --> Element muss aus Liste entfernt werden
            $kinder
            if(Test-Path ($list[$i].Fullname).toString() -pathType container){
                #Hole alle Kinder
                $kinder = getInahlt  $list[$i].Fullname   
            }else{
                $kinder = Get-Item $list[$i].Fullname  -Force
                $isNoItem = $false
            }

           
            if($kinder){
                foreach($k in $kinder){
                    if((pruefeVeraltet $k) -eq $false){
                        $alleKinderAlt = $false
                    }
                }
                #Block -- alle veraltet
                #Alle kinder der neuen Prüfliste hinzufügen
                #Veraltete direkt zur Result Liste, da das Elternelement nicht
                #mehr gelöscht werden darf --> es gibt ein aktuelles darunter
                if($alleKinderAlt){
                    #Write-Host "Alle veraltet"
                    foreach($k in $kinder){
                            $test = (Test-Path ($k.Fullname).toString() -pathType container)
                            #Write-Host "Ist Ordner " $k $test
                    
                            if((Test-Path ($k.Fullname).toString() -pathType container) -and $isNoItem){
                            #Write-Host "Wird hinzugefügt: " $k
                            $buffer = $newList.Add($k)
                            $buffer = $resultList.Add($k.Fullname)
                            }
                    }
                }
                #Block -- mind. eins aktuell
                elseif(!$alleKinderAlt){
                    #Write-Host "Min eines aktuell"
                    foreach($k in $kinder){
                        $istVeraltet = pruefeVeraltet $k
                        #Element ist veraltet
                        if($istVeraltet){
                        #Write-Host -ForegroundColor red "veraltet --> " $k
                            ###NEU###
                                if((Test-Path ($k.Fullname).toString() -pathType container) -and $isNoItem){
                                    $buffer = $newList.Add($k)
                                }
                                $isin = isInList $k.Fullname $resultList
                                if(!$isin){
                                ###NEU###
                                    if(Test-Path ($K.Fullname).toString() -pathType container){
                                        #Write-Host -ForegroundColor green "Hinzugefügt " ($K.Fullname).toString()
                                        $buffer = $resultList.Add($k.Fullname)
                                    }
                                    #Write-Host -ForegroundColor green "Kindelemente eines aktellen Nodes zu Result hinzugefügt"
                                    #Write-Host -ForegroundColor yellow "INFO --> Dh. Löschebene wurde geändert!"
                                    $size = $resultList.Count;
                                    #Write-Host "Result-Size: $size"
                                    }
                         
                        }
                        #Element ist aktuell
                        if(!$istVeraltet){
                            #Write-Host -ForegroundColor green "aktuell --> " $k
                            if((Test-Path ($k.Fullname).toString() -pathType container) -and $isNoItem){
                                $buffer = $newList.Add($k)
                            }
                            #Lösche Elternknoten über dem aktuellen Knoten aus Result
                            #Write-Host -BackgroundColor magenta "Element zum aus Liste Löschen: $name"
                            $parentname = $nameFull
                            #$isin = isInList $nameFull $resultList
                            while($true -and (Test-Path $parentname -pathType container)){
                                #Write-Host "Parentname =" $parentname
                                $isin = isInList $parentname $resultList
                                $isinroot = isInList $parentname $zuPruefendesDir
                                #Write-Host -BackgroundColor magenta "$parentname in Result? $isin"
                                #Write-Host -BackgroundColor magenta "$parentname in RootPaths? $isinroot"
                                #Write-Host -BackgroundColor magenta "NameFull: $nameFull"
                                #$n = $resultList.IndexOf($nameFull)
                                #Write-Host -BackgroundColor magenta "Index of $name in Result: $n"
                                #Write-Host -BackgroundColor red "Inhalt result: $resultList"
                                if($isinroot){
                                    break
                                }
                                if($isin){
                                    if(!$isinroot){
                                        #Write-Host -BackgroundColor green "Is in result List"
                                        $index = $resultList.IndexOf($parentname)
                                        #Write-Host -BackgroundColor magenta "Index zum löschen: $index"
                                        $resultList.RemoveAt($index)
                                        #Write-Host -ForegroundColor red ("`nElternelement aus Resultat gelöscht")
                                        $size = $resultList.Count;
                                        #Write-Host "Result-Size: $size"
                                    }
                                }

                                $parentname = (((Get-Item $parentname -Force).Parent).FullName).ToString()
                        
                            }
                        
                        
                            #Kind Elemente des Kindes prüfen und veraltete Result hinzufügen
                            #diese bilden neuen Ansatzpunkt für das Löschen
                            #Hohle Kindelemente und füge Liste hinzu
                            $inhalt = getInahlt $k.Fullname
                            #Write-Host "Kinder aus $k"
                            if($inhalt){
                                foreach($k in $inhalt){
                                    #Write-Host "Kind: " $k
                                    if(pruefeVeraltet $k){
                                        $isin = isInList $k.Fullname $resultList
                                        if(!$isin){
                                            if(Test-Path ($K.Fullname).toString() -pathType container){
                                                #Write-Host -ForegroundColor green "Hinzugefügt " ($K.Fullname).toString()
                                                $buffer = $resultList.Add($k.Fullname)
                                            }
                                            #Write-Host -ForegroundColor green "Kindelemente eines aktellen Nodes zu Result hinzugefügt"
                                            #Write-Host "INFO --> Dh. Löschebene wurde geändert!"
                                            $size = $resultList.Count;
                                            #Write-Host "Result-Size: $size"
                                        }
                                    }else{
                                        #Write-Host -ForegroundColor yellow "INFO: Der aktuelle Node hat keine weiteren Kinder"
                                    }
                                }
                            }
                        }
                    }
                

                }else{
                    Write-Host -ForegroundColor red "FEHLER"
                }
            }else
            {
                #Write-Host -ForegroundColor yellow "INFO: Ausgangsliste hat keine Kinder!"
            }
       <#}else{
            Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler! Der Pfad kann nicht korrekt zugegriffen werden!"
            Write-Host -BackgroundColor Yellow -ForegroundColor red "Pfad: $p"
            Write-Host -BackgroundColor Yellow -ForegroundColor red "Löschen wird nicht durchgeführt!"
            $loeschen = "false"
            $d = get-Date
            Out-File -FilePath $errorLog -InputObject "#### Errror Log vom $d ####"
            Out-File -FilePath $errorLog -InputObject "Fehler! Der Pfad kann nicht korrekt zugegriffen werden!"
            Out-File -FilePath $errorLog -InputObject "Pfad: $p"
            Out-File -FilePath $errorLog -InputObject "Löschen wird nicht mehr durchgeführt!"

            #Falls der Nutzer nicht mehr aktuell ist muss einmal pwCreator mit einem aktuellen Nutzer ausgeführt werden (liegt in scripte\zeitlicheLöschung...)
            $pw = Get-Content C:\scripte\zeitlicheLöschungScratchbereiche\MailPW.txt | ConvertTo-SecureString
            $cred = New-Object System.Management.Automation.PSCredential "hebner", $pw
            Send-MailMessage -to "patrick.hebner@ufz.de" -from "patrick.hebner@ufz.de" -Subject "Error while removing old files form scratch" -body "Please look at: $errorLog" -SmtpServer "smtp.ufz.de" -Port 587 -Credential $cred -UseSsl

            }#>
            }Catch {
                $global:errorEx = $true
                $global:errorCode = 0
                $nameFull = (($list[$i]).Fullname).toString()
                $parentname = $nameFull#getParentPathFromString($nameFull) #(((Get-Item $nameFull).Parent).FullName).ToString()
                Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler beim prüfen der Items! Starte Suche nach Eleternelementen im Pfad ..."
                Write-Host -ForegroundColor Yellow "Pfad: $nameFull"
                
                #$isin = isInList $nameFull $resultList
                while($true){
                    Write-Host -ForegroundColor Cyan "Aktuell zu prüfendes Eltenelement: $parentname"
                    #Write-Host "Parentname =" $parentname
                    $isin = isInList $parentname $resultList
                    $isinroot = isInList $parentname $zuPruefendesDir
                    #Write-Host -BackgroundColor magenta "$parentname in Result? $isin"
                    #Write-Host -BackgroundColor magenta "$parentname in RootPaths? $isinroot"
                    #Write-Host -BackgroundColor magenta "NameFull: $nameFull"
                    #$n = $resultList.IndexOf($nameFull)
                    #Write-Host -BackgroundColor magenta "Index of $name in Result: $n"
                    #Write-Host -BackgroundColor red "Inhalt result: $resultList"
                    if($isinroot){
                        Write-Host -ForegroundColor green "SUCHE BEENDET! Kein Element in Liste --> Root errreicht:"
                        Write-Host -ForegroundColor green "--> $parentname"
                        Write-Host -ForegroundColor green "***"
                        break
                    }else{
                        Write-Host "Nicht in Rootliste"
                    }
                    if($isin){
                        if(!$isinroot){
                            #Write-Host -BackgroundColor green "Is in result List"
                            $index = $resultList.IndexOf($parentname)
                            #Write-Host -BackgroundColor magenta "Index zum löschen: $index"
                            $resultList.RemoveAt($index)
                            #Write-Host -ForegroundColor red ("`nElternelement aus Resultat gelöscht")
                            $size = $resultList.Count;
                            #Write-Host "Result-Size: $size"
                            Write-Host -ForegroundColor red "Aus Result Liste gelöscht: "
                            Write-Host -ForegroundColor red "--> $parentname"
                            Write-Host -ForegroundColor red "***"
                        }
                    }else{
                        Write-Host "Nicht in Resultliste"
                    }



                    Write-Host -ForegroundColor Cyan "`r`nAktulles Element nicht in den Listen, prüfe nächst höhere Pfadebene`r`n"
                    $parentname = getParentPathFromString($parentname) #(((Get-Item $parentname).Parent).FullName).ToString()


                $errMess = $_.Exception.Message
                Out-File -FilePath $errorLog -Append -InputObject "Fehler beim Prüfen von Item: $nameFull"
                Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
                $m = $_.Exception|format-list -force
                Out-File -FilePath $errorLog -Append -InputObject $m
                Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"

            }
        }
    }
}

function getParentPathFromString($path){
    try{
        $tmp = $path.Split("\\")
        $tmp[$tmp.Length -1] = ""
        $tmp = $tmp -join "\"
        $tmp = $tmp.Substring(0,$tmp.Length - 1)
        return $tmp
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in getParentPathFromSring!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in getParentPathFromSring"
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorCode = 1
        $global:errorEx = $true
    }
}

function removeNotExistingPathesFromResult(){
    Write-Host -ForegroundColor green "********************************************************"
    Write-Host -ForegroundColor green "Entferne nicht existierende Verzeichnisse ..."
    $tmpList = New-Object System.Collections.ArrayList
    try{
        foreach($i in $global:arr){
            $exists = Test-Path $i
            if($exists -eq $true){
                #Write-Host -ForegroundColor Green "Exists: $i"
                $tmpList.Add($i)
            }#else{
                #Write-Host -ForegroundColor red "Does not exist: $i"
            #}
        }

        $global:arr = @()
        foreach($i in $tmpList){
            $global:arr += $i
        }
    }Catch{
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler beim Entfernen nicht existierender Verzeichnisse aus der Result Liste"
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorCode = 1
        $global:errorEx = $true
    }
    
    Write-Host -ForegroundColor green "Fertig"
    Write-Host -ForegroundColor green "********************************************************"
}

#Testet ob ein Element in einer bestimmten Liste enthalten ist(=> contains())
function isInList($eingang, $list){
    try{

       # Write-Host -ForegroundColor red -BackgroundColor yellow "List: $list"
        foreach($listElem in $list){
            #Write-Host -ForegroundColor red -BackgroundColor yellow "ListElem: $listElem"
            #Write-Host -ForegroundColor red -BackgroundColor yellow "Input: $eingang"
            if($listElem -and $eingang){
                if($listElem.toString() -like $eingang.toString()){
                return $true
                }
            }else{
                Write-Host -ForegroundColor red "Fehler"
            }
        }
    
        return $false
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in isInList!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in isInList"
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorCode = 1
        $global:errorEx = $true
    }

}

##########################################################################################################

#Funktionen zum formatieren der Ausgabedatei
#Formatiert die einzelnen Zeilen eines Eingangsarray und speichert sie in einem neuen
function makeTableEntry ($i){
    try{
        $owner = (Get-Acl $i).Owner
        if($typ -eq "lat"){
        $time = (Get-Item $i -Force).LastAccessTime
        #$time = (Get-Item $i | select LastAccessTime) 
        }elseif($typ -eq "lwt"){
        #$time = (Get-Item $i | select LastWriteTime) 
        $time = (Get-Item $i -Force).LastWriteTime
        }
        $leng = [int]($i.Length - 1)
        #Write-Host -BackgroundColor red $leng
    
        $start = [int]($Pfad.Length + 1)
        #Write-Host -BackgroundColor red $start
        $istr = $i.ToString()
        #Write-Host -BackgroundColor red $istr
        $j= $istr.SubString($start)

        $size = getSize($i)
        $num = getCountofFiles $i
        $files = $num[0]
        $dirs = $num[1]

        <#
        $global:gesamtGroesse += $size
        $global:gesamtAnzahl_f += $files
        $global:gesamtAnzahl_o += $dirs
        $global:gesamtAnzahl += ($files + $dirs)
        #>

        #$sf = groesseAusgabeAnpassen($size)

        #$tmpPath = ("#> Remove-Item -Path '$i' -Recurse -force;  <#") 
        $obj = New-Object PSObject
        $obj | Add-Member NoteProperty Element($i)
        $obj | Add-Member NoteProperty Datum($time)
        $obj | Add-Member NoteProperty Besizter($owner)
        $obj | Add-Member NoteProperty Groesse($size)
        $obj | Add-Member NoteProperty Anzahl_Dirs($dirs)
        $obj | Add-Member NoteProperty Anzahl_files($files)
        $obj | Add-Member NoteProperty Anzahl_gesamt($dirs + $files)
        $global:o += @($obj)
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in makeTableEntry!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in MakeTable"
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorCode = 1
        $global:errorEx = $true
    }
}

function groesseAusgabeAnpassen($s){
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
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in groesseAnpassen!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in groessAnpassen"
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorCode = 0
        $global:errorEx = $true
    }
}

function getCountofFiles($element){
    try{
        $num = @(0,0);
        if(Test-Path $element){
            #$size = Get-ChildItem $element -Recurse -Force| Measure-Object -Property Length -Sum
            $x = Get-ChildItem $element -Recurse -Force| Measure-Object -Property psiscontainer -sum
            $num[0] = $x.Count - $x.Sum
            $num[1] = $x.Sum
        }
        #Write-Host "files: "  $num[0]
        #Write-Host "files: "  $num[1]
        return $num
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in getCount!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in getCount"
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorCode = 0
        $global:errorEx = $true
    }
}

#Exportfunktion
function createAllTableEntries() {

    foreach($i in $Global:arr){   
        #Null Prüfung
        if($i){
            makeTableEntry $i
        } 
    }
}


###################################################################################################################

#Prüft ob Log Verzeichnisse als auch das Löschverzeichnis existieren und erstellt sie wenn dies nicht der Fall ist
function checkLogPath(){
    try{
        if((Test-Path "$basisPfad\logs_$logName") -eq $false){
        #Write-Host -ForegroundColor Yellow "`r`nErstelle Log- Verzeichnis:`r`n"
                    mkdir "$basisPfad\logs_$logName" -Force
        }
        if((Test-Path "$basisPfad\loeschskripte") -eq $false){
        #Write-Host -ForegroundColor Yellow "`r`nErstelle Lösch- Verzeichnis:`r`n"
                    mkdir "$basisPfad\loeschskripte" -Force
        }
        #Write-Host "`r`n"
        $errDate = Get-Date
        Out-File -FilePath $errorLog -Append -InputObject "***** ERROR LOG vom $errDate *****************************************"
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in checkLogPath!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in checkLogPath"
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorCode = 1
        $global:errorEx = $true
    }
}


function writeMetaInfo(){
    try{
        $a_date = Get-Date
        $v_date = $a_date.AddDays((-1) * $Alter)
        $v_date = $v_date.ToShortDateString()
        $a_date = $a_date.ToShortDateString()
    
        Write-Host  "`n`n-- NEUER PROZESS -----------------------------------------`n"
        Out-File -Encoding utf8 -FilePath $logPath -InputObject "#### LOG FILE --> $logName ####"
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject ""
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "Verwendete Parameter: `r`n#Alter: $Alter"
        #Out-File -Encoding utf8 -FilePath $runScript -InputObject "#### Temporaeres Loeschfile (wird ueberschrieben) ####"
        #Out-File -Encoding utf8 -FilePath $runScript -Append -InputObject ""
        #Out-File -Encoding utf8 -FilePath $runScript -Append -InputObject "#Verwendete Parameter: `r`n#Alter: $Alter"
        Write-Host  "Alter: $Alter"
        Write-Host  "Pfad: $Pfad"
        Write-Host  "Löschen: $loeschen"
        Write-Host  "Typ: $typ"
        Write-Host  "ErsteVerzEbeneErhalten: $ErsteVerzEbeneErhalten"
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "Pfad: $Pfad "
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "Loeschen: $loeschen "
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "Type: $typ "
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "ErsteVerzEbeneErhalten: $ErsteVerzEbeneErhalten "
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject ""
        #Out-File -Encoding utf8 -FilePath $runScript -Append -InputObject "#Pfad: $Pfad "
        #Out-File -Encoding utf8 -FilePath $runScript -Append -InputObject ""
        #Out-File -Encoding utf8 -FilePath $runScript -Append -InputObject "#Type: $typ "
        #Out-File -Encoding utf8 -FilePath $runScript -Append -InputObject ""
        Write-Host  "AKTUELLES DATUM:  " $a_date
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "`nAKTUELLES DATUM $a_date"
        Write-Host  "KRITISCHES DATUM: " $v_date "`n"
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject "`nKRITISCHES DATUM $v_date"
        Write-Host  "`n" 
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject  "`n`nHINWEIS: Die Angegebenen Einheiten werden mit Dezimalpräfix (MB, GB usw) dargestellt, um windowstypische Merkmale einzuhalten! `n"
        Out-File -Encoding utf8 -FilePath $logPath -Append -InputObject  "         Dir Umrechnung erfoglt aber nach den 2er Potenzen und nicht nach Dezimalstellen und entspricht somit KiB, MiB und GiB `n"
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in writeMethaInfo!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in writeMetaInfo"
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorCode = 0
        $global:errorEx = $true
    }
}

###################################################################################################################

#Funktion zum analysieren der Verzeichisse
function findeAlteOrder($zuPruefendesDir){
   #Write-Host "Starte: findeAlteOrdner"
   
   #ANPASSUNG FÜR LWT EINFÜGEN
   
   #Problem:
   #lwt --> Wenn eine Überverzeichnis veraltet ist, werden die Unterverzeichnisse
   #unabhängig vom Alter gelöscht --> evt. aktuelle Unterverzeichnisse werden gelöscht
   
   #Maßnahme:
   #Prüfung ob lwt vorliegt
   #lwt wird so angepasst, dass nicht nur die aktuellen Ordner weiter durchsucht
   #werden, sondern auch die als veraltet im @arr hinterlegten
   #Veraltete werden nur gelöscht wenn sie keine aktuellen Verz. mehr beinhalten bzw.
   #wird nur ab der Ebene gelöscht, ab der dies gilt

   
    foreach($folder in $zuPruefendesDir){
        $resp = $true
        Write-Host -ForegroundColor green "********************************************************"
        Write-Host -ForegroundColor green "Es werden veraltete Verzeichnisse gesucht ..."
        
        try{
            $inhaltDir = getInahlt $folder

        }Catch{
            Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler beim holen des Inhaltes aus $folder!"
            $errMess = $_.Exception.Message
            Out-File -FilePath $errorLog -Append -InputObject "Fehler beim holen des Inhaltes aus $folder!"
            Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
            $m = $_.Exception|format-list -force
            Out-File -FilePath $errorLog -Append -InputObject $m
            Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
            $global:errorCode = 1
            $global:errorEx = $true

            $inhaltDir = $false
            $resp = $false
        }

         if($typ -like "lwt"){
            if($inhaltDir -ne $false){
                pruefeVeraltetAlleElemente_lwt $inhaltDir
            }else{
                Write-Host -ForegroundColor Yellow -BackgroundColor Red "Kein Inhalt zum prüfen vorhanden"
            }
         }
        Write-Host -ForegroundColor green "Fertig"
        Write-Host -ForegroundColor green "********************************************************"
        $end_afterScan = Get-Date
        $runTime = $end_afterScan - $start
        Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Benötigte Zeit nach dem Scan der alten Daten = $runTime"
        return $resp
    }
    
      
}

#################################################################################################################################

#Funktion zum erhalten der Toplevel Verzeichnisse

function checkTopLevel(){
    try{
        Write-Host -ForegroundColor green "********************************************************"
        Write-Host -ForegroundColor green "Top Level Verzeichnisse werden erhalten ..."

        $tmpList = New-Object System.Collections.ArrayList
        $storeParents = @()
        $storeNew = New-Object System.Collections.ArrayList
        $rootPath = (Get-Item $zuPruefendesDir -Force).FullName.ToString() 
        #Write-Host -ForegroundColor Yellow "root: $rootPath"
        foreach($i in $Global:arr){
            $tmpList.Add($i)
        }
        $Global:arr = @()
        foreach($subpath in $tmpList){
            $currentItem = Get-Item $subpath -Force
            $parent = Get-Item $currentItem.PSParentPath -Force
            if(($parent.FullName.ToString()) -eq $rootPath){
                $content = Get-ChildItem $currentItem -Force
                $storeParents += $currentItem
                foreach($file in $content){
                    $full = $file.FullName
                    $storeNew.Add($full) 
                }
            }
        }

        #Write-Host -ForegroundColor Yellow "Zu erhaltende Verzeichnisse: "

        foreach($e in $storeParents){ 
            #Write-Host $e
            $index = $tmpList.IndexOf($e.ToString())
            $tmpList.RemoveAt($index)
        }

        $tmpList.Add($storeNew)

        foreach($i in $tmpList){
            $Global:arr += $i
        }
        Write-Host -ForegroundColor green "Fertig"
        Write-Host -ForegroundColor green "********************************************************"

        return $storeParents
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in pruefeTopLevelVerzeichnisse!"
        $errMess = $_.Exception.Message
        Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "`r`n#!!!ACHTUNG!!!`r`n"
        Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "`#Ein Fehler beim erhalten der Top Levelvereichnisse ist aufgetreten. Das Erhalten kann nicht durchgeführt werden --> Löschen wird deaktiviert --> Nur noch Loggen!`r`n"
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in pruefeTopLevelVerzeichnisse: "
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
        $global:errorCode = 1
        $storeParents = New-Object System.Collections.ArrayList
        return $storeParents
    }
}

function preserveTopLevel(){
    if($ErsteVerzEbeneErhalten -eq "true"){
           $verz = New-Object System.Collections.ArrayList
           #$verz = checkTopLevel
           foreach($e in checkTopLevel){
            if(Test-Path $e){
                $buffer = $verz.Add($e)
            }
    
           }        
           Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "`r`n`r`n<#"
           Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "!!!Achtung!!!`r`n`r`n"
           Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Eigentliche veraltete Ordner: "
           if($verz.Count -gt 0){
                #Write-Host $verz | Format-Table
                Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject $verz | Format-Table
           }else{
                #Write-Host "Keine Top-Level Ordner betroffen"
                Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "`r`nKeine Top-Level Ordner betroffen`r`n"
           }
           Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Da diese erhalten werden sollen, werden nur die Inhalte gelöscht!"
           Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Deshalb können auch einzelne Datein auftauchen#>.`r`n`r`n"
           $end_afterPreserving = Get-Date
           $runTime = $end_afterPreserving - $start
           Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Benötigte Zeit nach dem Erhalten der 1.Ebene = $runTime"
        }
}

function getSize($element){
    try{
        $size = 0;
        if(Test-Path $element -PathType Container){
            #$size = Get-ChildItem $element -Recurse -Force| Measure-Object -Property Length -Sum
            $size = Get-ChildItem $element -Recurse -Force| Where-Object {!$_.PSisContainer} | Measure-Object -Property Length -Sum
            $size = $size.sum
        }else{
            $size = (Get-Item $element -Force | Measure-Object -Property Length -Sum)
            $size = $size.sum
        }
        return $size
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in getSize!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in getSize: "
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorCode = 0
        $global:errorEx = $true
    }
}

function getEntireSize(){
    try{
        Write-Host -ForegroundColor green "********************************************************"
        Write-Host -ForegroundColor green "Datenvolumen wird ermittelt ...`n`n"
        $gesamt = 0
        foreach($s in $global:arr){
            $gesamt += getSize($s)

        }
        Write-Host -ForegroundColor green "Fertig"
        Write-Host -ForegroundColor green "********************************************************"
        return $gesamt
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in getEntireSize!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in getEntireSize: "
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
        $global:errorCode = 0
    }
}

function remove($list){
    try{

        $tmpList_short = New-Object System.Collections.ArrayList
        foreach($el in $list){
            $tmpList_short.Add($el.Element)
        }

        $removableItems = New-Object System.Collections.ArrayList
        foreach($e in $list){
            #Write-Host -ForegroundColor Cyan $e.Element
            $test = Test-Path $e.Element
            if($test -eq $true){
                $item = ((Get-Item $e.Element -Force).FullName).ToString()
                #Write-Host -ForegroundColor Yellow "Item: " $item
                #$parent = (((Get-Item $et -Force).Parent).FullName).ToString()
                $parent = getParentPathFromString($item)
                #Write-Host -ForegroundColor Yellow "Parent: " $parent
                if(isInList $parent $tmpList_short){
                        $removableItems.Add(<#$item#>$e)
                }
            }
        }
        #Write-Host -ForegroundColor Yellow "Removable"
        #foreach($z in $removableItems){
        #   Write-Host $z.Element
        #}

        foreach($r in $removableItems){
            $index = $list.IndexOf($r)
            #Write-Host -ForegroundColor Cyan $index
            #Write-Host -ForegroundColor Cyan $r
            $list.RemoveAt($index)
        }
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in remove!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in remove: "
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
        $global:errorCode = 1
    }
}

function removeRedundancies(){
    try{
        Write-Host -ForegroundColor green "********************************************************"
        Write-Host -ForegroundColor Green "Redundanzen entfernen von ..."
    
        $tmpList = New-Object System.Collections.ArrayList
        $x = 0
        foreach($i in $global:tmp){
            #Write-Host $x $i.Element
            $tmpList.Add($i)
            $x++
        }

        remove $tmpList
        <#
        Write-Host -ForegroundColor Green "`n`rResultat:`n`r "

        foreach($t in $tmpList){
            Write-Host $t
        }
        #>
        $global:tmp = @()
        foreach($element in $tmpList){
            $global:tmp += $element
        }
        $end_afterRed = Get-Date
        $runTime = $end_afterRed - $start
        Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Benötigte Zeit nach dem Löschen der Redundanzen = $runTime"
        Write-Host -ForegroundColor green "Fertig"
        Write-Host -ForegroundColor green "********************************************************"
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in removeRedundancies!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler in removeRedundancies: "
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
        $global:errorCode = 1
    }
}

function copyTo () {
    if((!$copyTo.Length -le 0) -and ($loeschen -eq $false)){
        Write-Host -ForegroundColor green "********************************************************"
        Write-Host -ForegroundColor Green "Daten werden nach $copyTo kopiert ..."
        Write-Host -ForegroundColor Green "Erstellen von $copyTo ..."
        New-Item -Type directory -Force -Path $copyTo
        Write-Host -ForegroundColor green "Kopiere ..."
        foreach($item in $global:tmp){
            try{
                Write-Host $item.Element
                $it = Get-Item -Force $item.Element
                $ex = ($copyTo + "\" + $it.BaseName)
                #Write-Host "Existis: $ex" 
                $dest = $copyTo
                if(Test-Path $ex){
                    $dest = $ex + "_copy"
                }
                #Write-Host "Dest: " $dest
                Copy-Item $item.Element $dest -Force -Recurse

            }Catch{
                Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler in copyTo!"
                $errMess = $_.Exception.Message
                Out-File -FilePath $errorLog -Append -InputObject "Fehler in copyTo: "
                Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
                $m = $_.Exception|format-list -force
                Out-File -FilePath $errorLog -Append -InputObject $m
                Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
                $global:errorEx = $true
                $global:errorCode = 0
            }
        }
        Write-Host -ForegroundColor Green "Fertig"
        Write-Host -ForegroundColor green "********************************************************"
        $end_afterCopy = Get-Date
        $runTime = $end_afterCopy - $start
        Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Benötigte Zeit nach dem Kopieren = $runTime"
      
    }else{
        Write-Host -ForegroundColor green "********************************************************"
        Write-Host -ForegroundColor Green "Es wird nicht kopiert (Hinweis: Kopieren nur wenn löschen false ist)"
        Write-Host -ForegroundColor green "********************************************************"
    }

}

function removeEntities($elements){
    if($loeschen -eq $true){
        Out-File -FilePath $remPath -InputObject ""              
        Write-Host -ForegroundColor green "********************************************************"
        Write-Host -ForegroundColor Green "Veraltete Daten werden von -> $logName <- GELÖSCHT ..."
        foreach($e in $elements){
            try{
                $ex = Test-Path $e
                if($ex -eq $true){
                    Write-Host -ForegroundColor Green "lösche: $e"
                    Remove-Item -Path $e -Force -Recurse
                    Out-File -FilePath $remPath -Append -InputObject "Gelöscht --> $e"
                }else{
                    Write-Host -ForegroundColor Gray "existiert nicht: $e"
                }
            }Catch{
                Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler beim Löschen von $e!"
                $errMess = $_.Exception.Message
                Out-File -FilePath $errorLog -Append -InputObject "Fehler beim Löschen von $e!"
                Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
                $m = $_.Exception|format-list -force
                Out-File -FilePath $errorLog -Append -InputObject $m
                Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
                $global:errorEx = $true
                $global:errorCode = 0
            }
        }
        
        $end_afterRemoval = Get-Date
        $runTime = $end_afterRemoval - $start
        Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Benötigte Zeit nach dem Löschen = $runTime"
        Write-Host -ForegroundColor Green "Fertig"
        Write-Host -ForegroundColor green "********************************************************"
        $pw = Get-Content C:\scripte\zeitlicheLöschungScratchbereiche\MailPW.txt | ConvertTo-SecureString
        $cred = New-Object System.Management.Automation.PSCredential "hebner", $pw
        Send-MailMessage -to "patrick.hebner@ufz.de" -from "patrick.hebner@ufz.de" -Subject "Removing old directories from >$logName< was finished!" -body  "Old directories were removed ---> tmpLoeschscript_$logName.ps1 was run! Logging was stated." -SmtpServer "smtp.ufz.de" -Port 587 -Credential $cred -UseSsl
    }elseif($loeschen -eq $false){
        Write-Host -ForegroundColor green "********************************************************"
        Write-Host -ForegroundColor Green "Veraltete Daten werden nicht von -> $logName <- gelöscht - NUR LOGGING"
        Write-Host -ForegroundColor green "********************************************************"
    }

    
}

function logEntities(){

    Write-Host -ForegroundColor green "********************************************************"
    Write-Host -ForegroundColor Green "Veraltete Daten werden in Datei geschrieben ..."
    foreach($entry in $global:tmp){
        $global:gesamtGroesse += $entry.Groesse
        $global:gesamtAnzahl_f += $entry.Anzahl_files
        $global:gesamtAnzahl_o += $entry.Anzahl_Dirs
        $global:gesamtAnzahl += ($entry.Anzahl_files + $entry.Anzahl_Dirs)
        $sf = groesseAusgabeAnpassen($entry.Groesse)
        $entry.Groesse = $sf
    }

    $global:tmp | Format-List | Out-File -Encoding UTF8 -FilePath $logPath -Append -Width 1000
    $global:gesamtGroesse = groesseAusgabeAnpassen($global:gesamtGroesse)
    Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Gesamtgroesse = $global:gesamtGroesse"
    Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Anzahl Dirs = $global:gesamtAnzahl_o"
    Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Anzahl Files = $global:gesamtAnzahl_f"
    Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Gesamtanzahl = $global:gesamtAnzahl"
    $end_afterLogging = Get-Date
    $runTime = $end_afterLogging - $start
    Out-File -Encoding UTF8 -FilePath $logPath -Append -InputObject "Benötigte Zeit nach dem Loggen der Einträge = $runTime"
    Write-Host -ForegroundColor Green "Fertig"
    Write-Host -ForegroundColor green "********************************************************"
}

function checkErrors(){
    try{
        if($global:errorEx -eq $true){
                    #Falls der Nutzer nicht mehr aktuell ist muss einmal pwCreator mit einem aktuellen Nutzer ausgeführt werden (liegt in scripte\zeitlicheLöschung...)
                $pw = Get-Content C:\scripte\zeitlicheLöschungScratchbereiche\MailPW.txt | ConvertTo-SecureString
                $cred = New-Object System.Management.Automation.PSCredential "hebner", $pw

                if($global:errorCode -eq 0){
                    Send-MailMessage -to "patrick.hebner@ufz.de" -from "patrick.hebner@ufz.de" -Subject "MSG: Removing / logging items from >$logName< is finished with errors!" -body "Non critical errors occurred and were handled by the script! Please look at: $errorLog" -SmtpServer "smtp.ufz.de" -Port 587 -Credential $cred -UseSsl

                }
                if($global:errorCode -eq 1){
                    Send-MailMessage -to "patrick.hebner@ufz.de" -from "patrick.hebner@ufz.de" -Subject "MSG: Removing / logging items from >$logName< with errors!" -body "Unexpected errors with unknown consequences occurred! If enabled, removing old directories will be changed to logging, since handling by the script is not possible. Please look at: $errorLog" -SmtpServer "smtp.ufz.de" -Port 587 -Credential $cred -UseSsl
                    $loeschen = $false
                    Write-Host -ForegroundColor Yellow "Status loeschen = $loeschen"
                }
        
        }else{
            $pw = Get-Content C:\scripte\zeitlicheLöschungScratchbereiche\MailPW.txt | ConvertTo-SecureString
            $cred = New-Object System.Management.Automation.PSCredential "hebner", $pw
             Send-MailMessage -to "patrick.hebner@ufz.de" -from "patrick.hebner@ufz.de" -Subject "MSG: Removing / logging items from >$logName< is finished successfully" -body "Script is run without errors!" -SmtpServer "smtp.ufz.de" -Port 587 -Credential $cred -UseSsl
        }
    }Catch{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Fehler beim Mail senden!"
        $errMess = $_.Exception.Message
        Out-File -FilePath $errorLog -Append -InputObject "Fehler beim Mail senden! "
        Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
        $m = $_.Exception|format-list -force
        Out-File -FilePath $errorLog -Append -InputObject $m
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"
        $global:errorEx = $true
        $global:errorCode = 0
    }
}

#############################################################################################################################################################
#############################################################################################################################################################
##### Programmablauf


try{

    #Pruefen ob Log- Pfad existierte bzw. erstellen wenn nicht
    checkLogPath


    #Variable Log Pfad setzen - nach aktuellen Eingangsverzeichnis
    $logPath = "$basisPfad\logs_$logName\LOG_$dateStemp.ps1"
    $remPath = "$basisPfad\logs_$logName\REMOVED_$dateStemp.ps1"
    #Temporärer Pfad für aktuell auszuführendes Löschscript
    $runScript = "$basisPfad\loeschskripte\tmpLoeschscript_$logName.ps1"

    writeMetaInfo

    #Funktionsaufrufe und Dateiexporte
    $resp = findeAlteOrder $zuPruefendesDir

    if($resp -eq $true){

        removeNotExistingPathesFromResult

        preserveTopLevel

        createAllTableEntries $Global:arr

        foreach($el in $global:o){
            $global:tmp += $el
        }

        removeEntities $global:arr

        removeRedundancies
        
        logEntities

        copyTo

        checkErrors

        #Write-Host -ForegroundColor green "********************************************************"
        #Write-Host -ForegroundColor Green "Veraltete Order: "
        #$global:tmp | sort -Descending |  Format-List | Out-Host
        #Write-Host -ForegroundColor green "********************************************************"

        Write-Host -ForegroundColor Yellow "`n`nFINISHED`n"



     
    }else{
        Write-Host -BackgroundColor Yellow -ForegroundColor red "Skript wurde abgebrochen - Kein Inhalt (moeglicherweise aufgrund eines Fehlers)"
        Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"

        $pw = Get-Content C:\scripte\zeitlicheLöschungScratchbereiche\MailPW.txt | ConvertTo-SecureString
        $cred = New-Object System.Management.Automation.PSCredential "hebner", $pw
        Send-MailMessage -to "patrick.hebner@ufz.de" -from "patrick.hebner@ufz.de" -Subject "Script on MSG was canceled!" -body "Skript was canceled because of missing content or an error! Please look at: $errorLog" -SmtpServer "smtp.ufz.de" -Port 587 -Credential $cred -UseSsl
    }

}Catch{
    Write-Host -BackgroundColor Yellow -ForegroundColor red "Unerwarteter FEHLER aufgetreten"
    $errMess = $_.Exception.Message
    Out-File -FilePath $errorLog -Append -InputObject "Es ist ein unerwarteter Fehler bei der Durchführung des Skriptes aufgetreten! Es wird abgebrochen."
    Out-File -FilePath $errorLog -Append -InputObject "Meldung: $errMess" 
    $m = $_.Exception|format-list -force
    Out-File -FilePath $errorLog -Append -InputObject $m
    Out-File -FilePath $errorLog -Append -InputObject "------------------------------------------------------------------"


    $pw = Get-Content C:\scripte\zeitlicheLöschungScratchbereiche\MailPW.txt | ConvertTo-SecureString
    $cred = New-Object System.Management.Automation.PSCredential "hebner", $pw
    Send-MailMessage -to "patrick.hebner@ufz.de" -from "patrick.hebner@ufz.de" -Subject "Error while removing old files form scratch on MSG" -body "General Error! Please look at: $errorLog" -SmtpServer "smtp.ufz.de" -Port 587 -Credential $cred -UseSsl

}

) | Out-Null
