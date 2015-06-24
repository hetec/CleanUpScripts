README - ALTDATENLOESCHUNG
==========================

!!!Achtung skaliert nicht mit der Anzahl von Datein --> Nur f�r Verzeichnisse mit relativ wenig Datein 
(400000 lief ca. 13h, 4,5 Mio lief > 6 Tage und wurde abgebrochen da Ende nicht in Sicht war)

Skript l�scht nur Ordner, in denen sich keine aktuelleren Datein oder Unterordner befinden. Dies erfolgt nach dem letzten �nderungsdatum

VERSION 1 -- BEI DIRKETER VERWENDUNG IN DER SHELL
-------------------------------------------------
1) Skript in PowerShell bei Ausf�hrung als Admin �ffnen
2) Parameter nach belieben angeben
	2.1) -Alter: Angabe in Tagen. Entspricht dem Alter der Ordner im -Pfad bezogen auf aktuelles Datum
	2.2) -Pfad: Angabe des gew�nschten Pfades in " "
	2.3) -loeschen: Angabe ob gel�scht werden soll ("true") oder nur geloggt ("false")
	2.4) -ErsteVerzEbeneErhalten: Gibt an ob die erste Verzeichnisebenen unter dem angegebenen Sourceverzeichnis immer
	      erhalten bleibt (true) oder auch gel�scht wird (false).

	Standardwerte der Parameter:
	-Alter 60
	-Pfad ".\"
	-loeschen "false"
	-ErsteVerzErhalten "false"

	Beispiel:

	PS C:\scripte\zeitlicheL�schungScratchbereiche\loeschenAltdaten.ps1 -Alter 60 -Pfad "H:\Scratch" -loeschen "false" -ErsteVerzEbeneErhalten "true"
        PS C:\scripte\zeitlicheL�schungScratchbereiche>loeschenAltdaten.ps1 -Alter 365 -Pfad 'F:\Scratchold' -loeschen 'false' -ErsteVerzEbeneErhalten "false"

4) Logdatein werden nach Verzeichnisnamen angelegt -> im Basispfad C:\scripte\zeitlicheL�schungScratchbereiche
5) Pfad f�r Logdateien �ndern: �nderung im Skript m�glich. Hier muss die Variable $basisPfad g�ndert werden. 
   Die weiteren Untervereichnisse werden automatisch angepasst.

VERSION 2 -- BEI VERWENDUNG IN EINEM TASK
-----------------------------------------
1) Skript als auszuf�hrendes Programm in der Aufgabenplanung angeben
2) Parameter bzw. Argumente in der Aufgabenplanung �bergeben(-Alter, -Pfad, -loeschen)
