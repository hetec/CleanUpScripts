README - File based clean up
============================

Description:

The script removes outdated files which are older than the defined amount of days. 
To determine the age of a file last write time is used.
The script also handles some problems with special characters in file paths and duplicated files while copying.
The results and errors are logged.

Steps to run the script in the console
-------------------------------------------------
1) Open PowerShell as administrator
2) Run the script with following parameters:
	2.1) -max_age: Maximum age as number of days
	2.2) -root_dir: All outdated files contained by this directory will are removed
	2.4) -type: Choose log, copy or remove to run the script in the specified mode. If copy is choosen, you need to speciefy copy_dest to.
	            The copy_dest parameter defines an >existing< directory to which the script will copy outdated files

	Standardwerte der Parameter:
	- max_age: 60 days
	- root_dir: .\
	- type: log

	Example:

	PS C:\scripte\zeitlicheLöschungScratchbereiche\loeschenAltdaten.ps1 -max_age 60 -root_dir "H:\scratch" -type "remove"

3) Log files are stored with the base path: C:\scripte\zeitlicheLöschungScratchbereiche as 'LOG + current date' and 'Error_log + current date'

