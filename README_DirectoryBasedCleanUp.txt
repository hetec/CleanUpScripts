README - ALTDATENLOESCHUNG
==========================

!!!Achtung skaliert nicht mit der Anzahl von Datein --> Nur für Verzeichnisse mit relativ wenig Datein 
(400000 lief ca. 13h, 4,5 Mio lief > 6 Tage und wurde abgebrochen da Ende nicht in Sicht war)

Skript löscht nur Ordner, in denen sich keine aktuelleren Datein oder Unterordner befinden. Dies erfolgt nach dem letzten Änderungsdatum

VERSION 1 -- BEI DIRKETER VERWENDUNG IN DER SHELL
-------------------------------------------------
1) Skript in PowerShell bei Ausführung als Admin öffnen
2) Parameter nach belieben angeben
	2.1) -Alter: Angabe in Tagen. Entspricht dem Alter der Ordner im -Pfad bezogen auf aktuelles Datum
	2.2) -Pfad: Angabe des gewünschten Pfades in " "
	2.3) -loeschen: Angabe ob gelöscht werden soll ("true") oder nur geloggt ("false")
	2.4) -ErsteVerzEbeneErhalten: Gibt an ob die erste Verzeichnisebenen unter dem angegebenen Sourceverzeichnis immer
	      erhalten bleibt (true) oder auch gelöscht wird (false).

	Standardwerte der Parameter:
	-Alter 60
	-Pfad ".\"
	-loeschen "false"
	-ErsteVerzErhalten "false"

	Beispiel:

	PS C:\scripte\zeitlicheLöschungScratchbereiche\loeschenAltdaten.ps1 -Alter 60 -Pfad "H:\Scratch" -loeschen "false" -ErsteVerzEbeneErhalten "true"
        PS C:\scripte\zeitlicheLöschungScratchbereiche>loeschenAltdaten.ps1 -Alter 365 -Pfad 'F:\Scratchold' -loeschen 'false' -ErsteVerzEbeneErhalten "false"

4) Logdatein werden nach Verzeichnisnamen angelegt -> im Basispfad C:\scripte\zeitlicheLöschungScratchbereiche
5) Pfad für Logdateien ändern: Änderung im Skript möglich. Hier muss die Variable $basisPfad gändert werden. 
   Die weiteren Untervereichnisse werden automatisch angepasst.

VERSION 2 -- BEI VERWENDUNG IN EINEM TASK
-----------------------------------------
1) Skript als auszuführendes Programm in der Aufgabenplanung angeben
2) Parameter bzw. Argumente in der Aufgabenplanung übergeben(-Alter, -Pfad, -loeschen)
