README - ALTDATENLOESCHUNG
==========================

Anwendungs Hinweise

!!! Das Update der  LastAccessTime muss in der Regestry unter dem Pfad: 

HKEY_LOCAL_MASHINE/SYSTEM/CurrentControlSet/Control/FileSystem/NtfsDisableLastAccessUpdate=0
erm�glicht werden !!!

Aufruf des Scripts

VERSION 1 -- BEI DIRKETER VERWENDUNG IN DER SHELL
-------------------------------------------------
1) Skript in PowerShell bei Ausf�hrung als Admin �ffnen
2) Parameter nach belieben angeben
	2.1) -Alter: Angabe in Tagen. Entspricht dem Alter der Ordner im -Pfad bezogen auf aktuelles Datum
	2.2) -Pfad: Angabe des gew�nschten Pfades in " "
	2.3) -loeschen: Angabe ob gel�scht werden soll ("true") oder nur geloggt ("false")
	2.4) -typ: Angabe von "lwt" f�r LastWriteTime oder "lat" f�r LastAccessTime m�glich. "lat" ist als Standard 
	2.5) -ErsteVerzEbeneErhalten: Gibt an ob die erste Verzeichnisebenen unter dem angegebenen Sourceverzeichnis immer
	      erhalten bleibt (true) oder auch gel�scht wird (false). Bei true werden die Verzeichnisse jedoch durch das
	      L�schen aktuallisiert (auch LWT). Z.B. um automatisch gemountete Nutzerverzeichnisse nicht w�hrend einer
	      Anmeldung zu l�schen usw. 

	Standardwerte der Parameter:
	-Alter 60
	-Pfad ".\"
	-loeschen "false"
	-typ "lwt"
	-ErsteVerzErhalten "false"

	Beispiel:

	PS C:\scripte\zeitlicheL�schungScratchbereiche\loeschenAltdaten.ps1 -Alter 60 -Pfad "H:\Scratch" -loeschen "false" -typ "lwt" -ErsteVerzEbeneErhalten "true"
        PS C:\scripte\zeitlicheL�schungScratchbereiche>loeschenAltdaten.ps1 -Alter 365 -Pfad 'F:\Scratchold' -loeschen 'false' -typ 'lwt' -ErsteVerzEbeneErhalten "false"

4) Veraltete Daten, die gel�scht werden sollen, werden in 'loeschskripte' tempor�r zwischengespeichert 
   (immer nur das aktuellste File)
5) Logdatein werden nach Verzeichnisnamen angelegt -> im Basispfad C:\scripte\zeitlicheL�schungScratchbereiche
6) Pfad f�r Logdateien �ndern: �nderung im Skript m�glich. Hier muss die Variable $basisPfad g�ndert werden. 
   Die weiteren Untervereichnisse werden automatisch angepasst.

VERSION 2 -- BEI VERWENDUNG IN EINEM TASK
-----------------------------------------
1) Skript als auszuf�hrendes Programm in der Aufgabenplanung angeben
2) Parameter bzw. Argumente in der Aufgabenplanung �bergeben(-Alter, -Pfad, -loeschen)

Hinweis: Wird das Skript f�r H:\Scratch ausgef�hrt, folgt am Ende die Ausf�hrung eines Virenscans auf dem Verzeichnis. Das Log dazu liegt im Logverzeichnis von Scratch