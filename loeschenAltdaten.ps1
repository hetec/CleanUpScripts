#Das Script löscht Daten nach ihrem Alter bezogen auf das Änderungsdatum

##### Parameter
param(
    [int]$Alter,
    [string]$Pfad,
    [string]$loeschen,
    [string]$typ
)

$(

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

if($typ -ne "lwt"){
    $typ = "lat"
    #Write-Host -ForegroundColor White "`r`n$typ`r`n"
}else{
    $typ = "lwt"
    #Write-Host -ForegroundColor White "`r`n$typ`r`n"
}

if(($loeschen -ne "false") -and ($loeschen -ne "true")){
     Write-Host -ForegroundColor Red "`r`nBitte Wert für -loeschen angeben! 'true' oder 'false'"
     break
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
$eltern = @{} #Speichert Änderungsdatum von Elternelementen von gelöschten Dir


$logName = (Get-Item -Path $Pfad -Force).Name.ToString()
#Write-Host -ForegroundColor white "$basisPfad\loeschskripte\tmpLoeschscript_$logName.ps1"

###########################################################################################################
###########################################################################################################
##### Funktionen

#Funktion zum Beschaffen der Ordner - Datein werden vernachlässigt da diese nicht geprüft werden sollen
#Leere Verezeichnisse werden zur Notiz auch aufgelistet
function getInahlt($start){
   # Write-Host -ForegroundColor DarkGray "`r`nInhalt des Verzeichnisses $start wird ermittelt ... "
    $temp = Get-ChildItem $start | Where-Object {$_.psiscontainer -eq $true}
   # Write-Host "temp: $temp"
    if($temp){
        #Write-Host -ForegroundColor DarkGreen "Verzeichnis ist nicht leer!"
        return $temp
    }else{
       # Write-Host ""
       # Write-Host -ForegroundColor DarkRed "Leer    --- $start"
       # Write-Host ""                        
        return $false
    }
    
}

###############################################################################################

#Funktion zum prüfen des Alters bei LAT
#Veraltete Verzeichnisse werden in globalem Array: $global:arr zwischengespeichert
function pruefeVeraltet($inhalt, $typ){
    $aktuelleOrdner = @()
    foreach($obj in $inhalt){
    #Write-Host -ForegroundColor Yellow $i
    if($typ -like "lat"){
        $lat = $obj.lastAccesstime
        
        if(($obj.lastAccessTime) -lt $kritischesDatum){
            #Schreibe veraltete (LAT) direkt in arr --> werden nicht weiter rekursiv durchsucht
           # Write-Host -ForegroundColor Red "Veraltet --- $obj --- $lat"
            $tmp = ($obj.Fullname)
            $global:arr += @($tmp) 
        }else{
            #Schreibe aktuelle (LAT) in $aktuelleOrdner --> werden rekursiv weiter durchsucht
            #Write-Host -ForegroundColor Green "Aktuell --- $obj --- $lat"
            $aktuelleOrdner += $obj.fullname 
        }
        }else{
            Write-Host -ForegroundColor Red "ERROR"
            break
         }
    }
    #$aktuelleOrdner entählt die aktuellen Verzeichnisse --> werden als Eingabe für rekusieven Methodenaufruf verwendet
    #da diese weiter untersucht werden müssen
    return $aktuelleOrdner
}

##################################################################################################

#Funktion zum prüfen des Alters bei LWT
#Veraltete Verzeichnisse werden in globalem Array: $global:arr zwischengespeichert


function pruefeVeraltetAlleElemente_lwt($inhalt){
    #Liste als Zwischenspeicher
    $liste = New-Object System.Collections.ArrayList
    $newList = New-Object System.Collections.ArrayList
    #Liste mit zu Löschenden Verz
    $resultList = New-Object System.Collections.ArrayList
    #initiales Befüllen der Liste
    foreach($el in $inhalt){
         $buffer = $liste.Add($el) 
        if(pruefeVeraltet $el){
            $resultList.Add(($el.Fullname).toString())
        }
    }
    $size = $resultList.Count;
    #Write-Host -ForegroundColor yellow ("Result-Size(Initial): $size")
    #Write-Host "`n-- Anfangsinhalt des Verzeichnisses: --------------------------------`n"
    #Write-Host "$resultList"
    #$resultList | Format-List
    #Write-Host "`n---------------------------------------------------------------------`n"
    $listenLaenge = $liste.Count
    while($listenLaenge -gt 0){
        #write-host "`nNeue Liste der Länge $listenLaenge wird verarbeitet"
        #Write-Host "----------------------------------------------------"
        #Write-Host "Inhalt: $liste`n"
        
        pruefeVerzeichnisse $liste
        $liste = $newList
        #Write-Host "LISTE: $liste"
        $newList.Clear()

        $listenLaenge = $liste.Count 
 
    }
    
 
    
    Write-Host -ForegroundColor green "`n`nSUCHE ABGESCHLOSSEN --> kein Kindelemente mehr verfügbar!`n"
    Write-Host "`n-- Resultat: ----------------------------------------------`n"
    #Write-Host "$resultList"
    $resultList | sort -Descending |Format-List | Out-Host
    write-Host "`n-----------------------------------------------------------`n"    
    Write-Host -ForegroundColor White "`n`nÜbertrage Elemente ... `n"  
    foreach($el in $resultList){
        #Write-Host $el
        #$tmp = ($el.Fullname)
        #$global:arr = 
    }
    $global:arr = $resultList.toArray()
    #Write-Host "Global Array:  $global:arr"
}

#funktion zum Prüfen des Alters eines Elements
function pruefeVeraltet($element){
    #Write-Host "Starte: pruefeVeraltet auf :: $element"
    $lwt = $element.lastwritetime
    if(($element.lastWriteTime) -lt $kritischesDatum){
        #Write-Host -ForegroundColor red "Veraltet ---> $element"
        return $true
        }else{
        #Write-Host -ForegroundColor green "Aktuell ----> $element"
        return $false
        }
}

#Funktion sucht die veralteteten Verzeichnisse aus dem Verzeichnisbaum
function pruefeVerzeichnisse($list){
    for($i = 0; $i -lt $list.Count; $i++){
        $zuPr = ($list[$i]).toString();
        Write-Progress -Activity "Suche veraltete Verzeichnisse in $Pfad" -PercentComplete (($i * 100)/($list.Count)) -Status "Aktuell zu prüfen: $zuPr"
        #Zu erst prüfen ob alle Kinder eines Elements veraltet sind
        #JA --> Element bleibt --> Kinder weiter prüfen
        #NEIN --> Element muss aus Liste entfernt werden
        
        #Hole alle Kinder
        $kinder = getInahlt  $list[$i].Fullname
        $name = ($list[$i]).toString()
        $nameFull = (($list[$i]).Fullname).toString()
        #Write-Host "`nGeholte Kindelemente: $kinder`n"
        $alleKinderAlt = $true
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
                foreach($k in $kinder){
                    $buffer = $newList.Add($k)
                    
                }
            }
            #Block -- mind. eins aktuell
            elseif(!$alleKinderAlt){
                foreach($k in $kinder){
                    $istVeraltet = pruefeVeraltet $k
                    #Element ist veraltet
                    if($istVeraltet){
                        $buffer = $newList.Add($k)
                        $isin = isInList $k.Fullname $resultList
                        if(!$isin){
                             $buffer = $resultList.Add($k.Fullname)
                            
                            #Write-Host -ForegroundColor green "Kindelemente eines aktellen Nodes zu Result hinzugefügt"
                            #Write-Host -ForegroundColor yellow "INFO --> Dh. Löschebene wurde geändert!"
                            $size = $resultList.Count;
                            #Write-Host "Result-Size: $size"
                         }
                    }
                    #Element ist aktuell
                    if(!$istVeraltet){
                        #Aktuelle El der neuen Liste hinzu
                         $buffer = $newList.Add($k)
                        #Lösche Elternknoten über dem aktuellen Knoten aus Result
                        
                        #Write-Host -BackgroundColor magenta "Element zum Löschen: $name"
                        $isin = isInList $nameFull $resultList
                        #Write-Host -BackgroundColor magenta "$name in Result? $isin"
                        #Write-Host -BackgroundColor magenta "NameFull: $nameFull"
                        #$n = $resultList.IndexOf($nameFull)
                        #Write-Host -BackgroundColor magenta "Index of $name in Result: $n"
                        #Write-Host -BackgroundColor red "Inhalt result: $resultList"
                        if($isin){
                            #Write-Host -BackgroundColor green "Is in result List"
                            $index = $resultList.IndexOf($nameFull)
                            #Write-Host -BackgroundColor magenta "Index zum löschen: $index"
                            $resultList.RemoveAt($index)
                            #Write-Host -ForegroundColor red ("`nElternelement aus Resultat gelöscht")
                            $size = $resultList.Count;
                            #Write-Host "Result-Size: $size"
                        }
                        
                        #Kind Elemente des Kindes prüfen und veraltete Result hinzufügen
                        #diese bilden neuen Ansatzpunkt für das Löschen
                        #Hohle Kindelemente und füge Liste hinzu
                        $inhalt = getInahlt $k.Fullname
                        if($inhalt){
                            foreach($k in $inhalt){
                                if(pruefeVeraltet $k){
                                    $isin = isInList $k.Fullname $resultList
                                    if(!$isin){
                                        $buffer = $resultList.Add($k.Fullname)
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

    }
}

#Testet ob ein Element in einer bestimmten Liste enthalten ist(=> contains())
function isInList($eingang, $list){
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
    
}

##########################################################################################################

#Funktionen zum formatieren der Ausgabedatei
#Formatiert die einzelnen Zeilen eines Eingangsarray und speichert sie in einem neuen
function makeTable ($i){
    $owner = (Get-Acl $i).Owner
    if($typ -eq "lat"){
    $time = (Get-Item $i | select LastAccessTime) 
    }elseif($typ -eq "lwt"){
    $time = (Get-Item $i | select LastWriteTime) 
    }
    $leng = [int]($i.Length - 1)
    #Write-Host -BackgroundColor red $leng
    
    $start = [int]($Pfad.Length + 1)
    #Write-Host -BackgroundColor red $start
    $istr = $i.ToString()
    #Write-Host -BackgroundColor red $istr
    $j= $istr.SubString($start)

    $tmpBez = ("   Veraltet: $time --- Owner: $owner")
    $tmpPath = ("#> Write-Host 'Lösche: $i'; Remove-Item -Path '$i' -Recurse -force;  <#") 
    $obj = New-Object PSObject
    $obj | Add-Member NoteProperty Löschbefehl($tmpPath)
    $obj | Add-Member NoteProperty Notiz($tmpBez)
    $global:o += @($obj)
}


#Exportfunktion
function exportierenLöschbefehle () {

    foreach($i in $Global:arr){   
        #Null Prüfung
        if($i){
            makeTable $i
        } 
    }
}


###################################################################################################################

#Prüft ob Log Verzeichnisse als auch das Löschverzeichnis existieren und erstellt sie wenn dies nicht der Fall ist
function checkLogPath(){
    if((Test-Path "$basisPfad\logs_$logName") -eq $false){
    #Write-Host -ForegroundColor Yellow "`r`nErstelle Log- Verzeichnis:`r`n"
                mkdir "$basisPfad\logs_$logName"
    }
    if((Test-Path "$basisPfad\loeschskripte") -eq $false){
    #Write-Host -ForegroundColor Yellow "`r`nErstelle Lösch- Verzeichnis:`r`n"
                mkdir "$basisPfad\loeschskripte"
    }
    #Write-Host "`r`n"
}



function writeMetaInfo(){
    Write-Host  "`n`n-- NEUER PROZESS -----------------------------------------`n"
    Out-File -FilePath $logPath -InputObject "#### LOG FILE $logName ####"
    Out-File -FilePath $logPath -Append -InputObject ""
    Out-File -FilePath $logPath -Append -InputObject "#Verwendete Parameter: `r`n#Alter: $Alter"
    Out-File -FilePath $runScript -InputObject "#### Temporaeres Loeschfile (wird ueberschrieben) ####"
    Out-File -FilePath $runScript -Append -InputObject ""
    Out-File -FilePath $runScript -Append -InputObject "#Verwendete Parameter: `r`n#Alter: $Alter"
    Write-Host  "Alter: $Alter"
    Write-Host  "Pfad: $Pfad"
    Write-Host  "Löschen: $loeschen"
    Write-Host  "Typ: $typ"
    Out-File -FilePath $logPath -Append -InputObject "#Pfad: $Pfad "
    Out-File -FilePath $logPath -Append -InputObject "#Loeschen: $loeschen "
     Out-File -FilePath $logPath -Append -InputObject "#Type: $typ "
    Out-File -FilePath $logPath -Append -InputObject ""
     Out-File -FilePath $runScript -Append -InputObject "#Pfad: $Pfad "
    Out-File -FilePath $runScript -Append -InputObject ""
     Out-File -FilePath $runScript -Append -InputObject "#Type: $typ "
    Out-File -FilePath $runScript -Append -InputObject ""
    Write-Host  "AKTUELLES DATUM $aktuellesdatum"
    Out-File -FilePath $logPath -Append -InputObject "#AKTUELLES DATUM $aktuellesdatum"
    Write-Host  "KRITISCHES DATUM" $kritischesDatum "`n"
    Out-File -FilePath $logPath -Append -InputObject "#KRITISCHES DATUM $kritischesDatum"
}

###################################################################################################################

#Funktion zum rekusiven analysieren der Verzeichisse
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

         Write-Host -ForegroundColor cyan "`n`n`n`nEs werden veraltete Verzeichnisse gesucht ...`n`n`n`n"
    
        $inhaltDir = getInahlt $folder

        if($typ -like "lat"){
            if($inhaltDir -ne $false){
                $zuPruefendeDir = @();
                $zuPruefendeDir = (pruefeVeraltet $inhaltDir $typ)
                if($zuPruefendeDir -gt 0){
                    (findeAlteOrder $zuPruefendeDir)
                }
            }
        }

         if($typ -like "lwt"){
            if($inhaltDir -ne $false){
               
                pruefeVeraltetAlleElemente_lwt $inhaltDir
            }
         }else{
            #Write-Host "INFO: LWT Erweiterung für das Finden alter Ordner wird NICHT ausgeführt"
        }
        
    }
    
      
}

function datumEleternelementeSpeichern(){
    foreach($item in $global:arr){
        echo $global:arr
        if($item){
            $parent = (Get-Item $item -Force).parent.fullname
            $lwtStamp = (Get-Item $parent -Force).LastWriteTime
            if(!$eltern.Get_Item(($parent.toString()))){
                $eltern.Add($parent, $lwtStamp)
            }
        }else{
            Write-Host "NULL"
        }
    }
}

function datumZuruecksetzen (){
    $eltern.GetEnumerator() | % {
        $verzName = $_.key
        Write-Host "`n`nVerzeichnis: $verzName"
        $item = $_.key
        $gesetztesDatum = (Get-Item $item -Force).LastWriteTime
        $gespeichertesDatum = $_.Value
        (Get-Item $item -Force).LastWriteTime = $gespeichertesDatum
        Write-Host -ForegroundColor red "`nAktelles Datum:        $gesetztesDatum"
        Write-Host "                              \/"
        Write-Host "                              \/  Wird zurück gesetzt"
        Write-Host "                              \/"
        Write-Host -ForegroundColor green "Gespeicherts Datum:    $gespeichertesDatum`n"
        
    }

    
}

function getSize($directory){
    $size = Get-ChildItem $directory -Recurse -Force| Measure-Object -Property Length -Sum
    $size = "{0:N2}" -f ($size.sum / 1MB) + " MB"
    return $size
}


#############################################################################################################################################################
#############################################################################################################################################################
##### Programmablauf




#Pruefen ob Log- Pfad existierte bzw. erstellen wenn nicht
checkLogPath


#Variable Log Pfad setzen - nach aktuellen Eingangsverzeichnis
$logPath = "$basisPfad\logs_$logName\LOG_$dateStemp.ps1"
#Temporärer Pfad für aktuell auszuführendes Löschscript
$runScript = "$basisPfad\loeschskripte\tmpLoeschscript_$logName.ps1"

writeMetaInfo

#Funktionsaufrufe und Dateiexporte
findeAlteOrder $zuPruefendesDir

Write-Host "Exportiere Daten ... `r`n"
exportierenLöschbefehle $Global:arr
#Out-File -FilePath $logPath -Append -InputObject "`n`ncd $Pfad"
Out-File -FilePath $logPath -Append -InputObject "<#"
$global:o | Format-List | Out-File -FilePath $logPath -Append -Width 1000
Out-File -FilePath $logPath -Append -InputObject "#>"
#Out-File -FilePath $runScript -Append -InputObject "`n`ncd $Pfad"
Out-File -FilePath $runScript -Append -InputObject "<#"
$global:o | Format-List | Out-File -FilePath $runScript -Append -Width 1000
Out-File -FilePath $runScript -Append -InputObject "#>"


datumEleternelementeSpeichern
Write-Host "`n`n`n`nVerzeichnisse mit aktuallisierter LWT (zurücksetzen):"
Write-Host "-----------------------------------------------------"
$eltern | Format-List | Out-Host

#Generiertes Löschskript ausführen
$loschskript = Get-ChildItem -Path "$basisPfad\loeschskripte"
        $currentDate = Get-Date
        if(($logName -like 'Scratch') -and ($loeschen -eq $true)){
                Write-Host "Lösche von Scratch"
                Invoke-Expression "&'$basisPfad\loeschskripte\tmpLoeschscript_$logName.ps1'"
                Write-Host ""
                Write-Host -ForegroundColor green "ERFOLGREICH VON SCRATCH GELÖSCHT!"
                Write-Host ""
                Write-Host ""

                #LWT der Elternverzeichisse zurücksetzen
                datumZuruecksetzen

        }elseif(($logName -like 'Scratchold') -and ($loeschen -eq $true)){
                Write-Host "Lösche von ScratchOld"
                Invoke-Expression "&'$basisPfad\loeschskripte\tmpLoeschscript_$logName.ps1'"
                Write-Host ""
                Write-Host -ForegroundColor green "ERFOLGREICH VON SCRATCHOLD GELÖSCHT!"
                Write-Host ""
                Write-Host ""

                #LWT der Elternverzeichisse zurücksetzen
                datumZuruecksetzen
           
        }elseif(($logName -notlike 'Scratchold') -and ($logName -notlike 'Scratch') -and ($loeschen -eq $true)){
               
                Write-Host "Lösche von $Pfad"
                Write-Host -BackgroundColor yellow -ForegroundColor Black $log
                Invoke-Expression  "&'$basisPfad\loeschskripte\tmpLoeschscript_$logName.ps1'"
                Write-Host ""
                Write-Host -ForegroundColor green "ERFOLGREICHE REINIGUNG VON $logName`r`n"
 
                Write-Host ""

                #LWT der Elternverzeichisse zurücksetzen
                datumZuruecksetzen
           
        }elseif($loeschen -eq $false){
                Write-Host -ForegroundColor Yellow "KEINE LÖSCHUNG, NUR LOGGING"
        }

#datumZuruecksetzen

if($logName -like "Scratch"){
    #Stoeßt ESET Scan für H:\Scratch an nachdem das Skript durchgelaufen ist

    Out-File -FilePath $logPath -Append -InputObject "`r`nESET Scan wurde für $logName angestoßen! Siehe Logverzeichnis!"

    Start-Process "C:\Program Files\ESET\ESET NOD32 Antivirus\ecls.exe" -ArgumentList "H:\scratch", "/log-file=$basisPfad\logs_$logName\ESET_LOG_$dateStemp.txt"
}

) | Out-Null
