Anwendungs Hinweise

!!! Das Update der  LastAccessTime muss in der Regestry unter dem Pfad: 

HKEY_LOCAL_MASHINE/SYSTEM/CurrentControlSet/Control/FileSystem/NtfsDisableLastAccessUpdate=0
ermöglicht werden !!!

Aufruf des Scripts

VERSION 1 -- BEI DIRKETER VERWENDUNG IN DER SHELL
-------------------------------------------------
1) Skript in PowerShell bei Ausführung als Admin öffnen
2) Parameter nach belieben angeben
	2.1) -Alter: Angabe in Tagen. Entspricht dem Alter der Ordner im -Pfad bezogen auf aktuelles Datum
	2.2) -Pfad: Angabe des gewünschten Pfades in " "
	2.3) -loeschen: Angabe ob gelöscht werden soll ("true") oder nur geloggt ("false")
	2.4) -type: Angabe von "lwt" für LastWriteTime oder "lat" für LastAccessTime möglich. "lat" ist als Standard angegeben

	Beispiel:

	PS C:\scripte\zeitlicheLöschungScratchbereiche\loeschenAltdaten.ps1 -Alter 60 -Pfad "H:\Scratch" -loeschen "false"
        PS C:\scripte\zeitlicheLöschungScratchbereiche>loeschenAltdaten.ps1 -Alter 365 -Pfad 'F:\Scratchold' -loeschen 'false' -typ 'lwt'

4) Veraltete Daten, die gelöscht werden sollen, werden in 'loeschskripte' temporär zwischengespeichert (immer nur das aktuellste File)
5) Logdatein werden nach Verzeichnisnamen angelegt -> im Basispfad C:\scripte\zeitlicheLöschungScratchbereiche
6) Pfad für Logdateien ändern: Änderung im Skript möglich. Hier muss die Variable $basisPfad gändert werden. Die weiteren Untervereichnisse werden automatisch angepasst.

VERSION 2 -- BEI VERWENDUNG IN EINEM TASK
-----------------------------------------
1) Skript als auszuführendes Programm in der Aufgabenplanung angeben
2) Parameter bzw. Argumente in der Aufgabenplanung übergeben(-Alter, -Pfad, -loeschen)

Hinweis: Wird das Skript für H:\Scratch ausgeführt, folgt am Ende die Ausführung eines Virenscans auf dem Verzeichnis. Das Log dazu liegt im Logverzeichnis von Scratch