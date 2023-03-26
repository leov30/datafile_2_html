@echo off

rem // build html from xml datafiles, the script will do cross-reference with the other datafiles found in datafiles\ folder
rem // will create a batch script to copy images from latest progettosnaps.net images pack
rem // Require: _bin\[xidel.exe, mamediff.exe, datutil.exe]
rem // optional: sources\progettosnaps\[catver.ini, nplayers.ini, bestgames.ini, languages.ini, series.ini] also, will need the latest Arcade .dat from progettosnaps.net
rem // optional: sources\[datafile file name]\[catver.ini, hiscore.dat, cheat.dat, romstatus.xml, artwork.lst] this are files specific for that datafile
rem // http://www.logiqx.com/Tools/
rem // https://www.videlibri.de/xidel.html

SETLOCAL EnableDelayedExpansion
title Visual Database HTML Builder

md _bin sources datafiles sources\progettosnaps 2>nul

if not exist _bin\datutil.exe set _error=1
if not exist _bin\mamediff.exe set _error=1
if not exist _bin\xidel.exe set _error=1

if "%_error%"=="1" title ERROR&echo This script needs xidel, mamediff, datutil in _bin\&pause&exit

if not exist _temp (md _temp)else (del /q _temp)

rem //build array of datafiles
set _index=0
for %%g in (datafiles\*.xml datafiles\*.dat) do (
	set /a _index+=1
	set "_dat[!_index!]=%%~nxg"	
)
if %_index%==0 cls&title ERROR&echo NO DATAFILES WERE FOUND&pause&exit
set _max=%_index%

echo ------------------------------------------
echo       Choose a datafile to build html
echo ------------------------------------------
echo:
for /l %%g in (1,1,%_max%) do (
	echo %%g. !_dat[%%g]!
)
echo:
set /p "_index=Enter number: " || set _index=1
if "!_dat[%_index%]!"=="" cls&title ERROR&echo NOT A VALID OPTION&pause&exit
set "_dat=!_dat[%_index%]!"

rem //standarize datafiles with datutil for mamediff
for %%g in (datafiles\*.xml datafiles\*.dat) do (
	_bin\datutil -f generic -o "_temp\%%~nxg" "%%g" >nul
	
)

rem //cross refernece datafiles with mamediff
for %%g in (_temp\*.dat _temp\*.xml) do (
	if not "%%~nxg"=="%_dat%" (
		_bin\mamediff -s "_temp\%_dat%" "%%g" >nul
		move mamediff.out "_temp\%%~ng.out" >nul
	)
)
del mamediff.log datutil.log

cls&title building overall status tables...

rem //build description and "overall" status tables for every datafile found
for %%g in (datafiles\*.xml datafiles\*.dat) do (
	echo %%~xng
	_bin\xidel -s "%%g" -e "replace( $raw, '^<\WDOCTYPE mame \[.+?\]>', '', 'ms')" >"_temp\%%~xng"

	set _tag=game
	for /f %%h in ('_bin\xidel -s "_temp\%%~nxg" -e "matches( $raw, '<machine name=\""\w+\""')"') do if %%h==true set _tag=machine
	for /f %%h in ('_bin\xidel -s "_temp\%%~nxg" -e "matches( $raw, '<driver status=\""good\""')"') do set _driver=%%h

	if !_driver!==true (
		for /f %%h in ('_bin\xidel -s "_temp\%%~nxg" -e "matches( $raw, '<driver status=\""protection\""')"') do if %%h==true (
			_bin\xidel -s "_temp\%%~nxg" -e "//!_tag!/driver[@status='protection' or @status='preliminary' or @graphic='preliminary' or @color='preliminary' or @sound='preliminary']/../(@name|description)" >_temp\preliminary.lst	
			_bin\xidel -s "_temp\%%~nxg" -e "//!_tag!/driver[not(@status='protection') and not(@status='preliminary') and not(@graphic='preliminary') and not(@color='preliminary') and not(@sound='preliminary') and (@color='imperfect' or @sound='imperfect' or @graphic='imperfect')]/../(@name|description)" >_temp\imperfect.lst
			_bin\xidel -s "_temp\%%~nxg" -e "//!_tag!/driver[@status='good' and @color='good' and @sound='good' and @graphic='good']/../(@name|description)" >_temp\good.lst

		)else (
			_bin\xidel -s "_temp\%%~nxg" -e "//!_tag!/driver[@status='preliminary']/../(@name|description)" >_temp\preliminary.lst
			_bin\xidel -s "_temp\%%~nxg" -e "//!_tag!/driver[@status='imperfect']/../(@name|description)" >_temp\imperfect.lst
			_bin\xidel -s "_temp\%%~nxg" -e "//!_tag!/driver[@status='good']/../(@name|description)" >_temp\good.lst
		)
		
		_bin\xidel -s _temp\preliminary.lst -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	red	$2', 'm')" >"_temp\%%~ng.txt"
		_bin\xidel -s _temp\imperfect.lst -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	darkorange	$2', 'm')" >>"_temp\%%~ng.txt"

	)else (
		_bin\xidel -s "_temp\%%~nxg" -e "//!_tag!/(@name|description)" >_temp\good.lst
		
	)

	_bin\xidel -s _temp\good.lst -e "replace( $raw, '^(\w+)\r\n(.+?)$', '$1	green	$2', 'm')" >>"_temp\%%~ng.txt"

)

cls&title getting info about datafile...

for /f "delims=" %%g in ('_bin\xidel -s --output-format=cmd "_temp\%_dat%"
		-e "_tag:=matches( $raw, '<machine name=\""\w+\""')"
		-e "_drv:=matches( $raw, '<driver status=\""\w+\""')"
		-e "_drv_spl:=matches( $raw, '<driver status=\""\w+\""/>')"
		-e "_drv_old:=matches( $raw, '<driver status=\""protection\""')"
		-e "_isbios:=matches( $raw, 'isbios=\""yes\""')"') do %%g

if %_tag%==true (set _tag=machine)else (set _tag=game)
if %_isbios%==true (set _isbios=@isbios)else (set _isbios=@runnable)

echo color, sound, graphic
_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[not(@cloneof)]/driver/(../@name|@color|@sound|@graphic)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(\w+)\r\n(\w+)\r\n(\w+)', '$1	$2	$3	$4', 'm')" >_temp\temp.2
_bin\xidel -s _temp\temp.2 -e "replace( $raw, 'preliminary', 'red')" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, 'imperfect', 'darkorange')" >_temp\temp.2
_bin\xidel -s _temp\temp.2 -e "replace( $raw, 'good', 'green')" >_temp\status.txt

echo protection, emulation
if %_drv_old%==true (
	_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[not(@cloneof)]/driver[@status='proection']/../@name" >_temp\protection.lst
	_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[not(@cloneof)]/driver[@status='preliminary']/../@name" >_temp\emulation.lst
)else (
	_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[not(@cloneof)]/driver[@protection='preliminary']/../@name" >_temp\protection.lst
	_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[not(@cloneof)]/driver[@emulation='preliminary']/../@name" >_temp\emulation.lst
)

echo cloneof table
_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[@cloneof]/(@name|@cloneof)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(\w+)', '$1	$2', 'm')" >_temp\cloneof.txt

echo sourcefile
_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[@sourcefile and not(@cloneof)]/(@name|@sourcefile)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+)', '$1	$2', 'm')" >_temp\sourcefile.txt

echo manufacturer
_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[manufacturer and not(@cloneof)]/(@name|manufacturer)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+)', '$1	$2', 'm')" >_temp\manuf.txt

echo year
_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[year and not(@cloneof)]/(@name|year)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(.+)', '$1	$2', 'm')" >_temp\year.txt

echo nodump/badump
_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[not(@cloneof)]/rom[@status='baddump']/../@name" >_temp\baddump.lst
_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[not(@cloneof)]/rom[@status='nodump']/../@name" >_temp\nodump.lst

echo games with disk/chd
_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[disk]/@name" >_temp\disk.lst

echo games that need samples and its sample file
_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[@sampleof]/(@name|@sampleof)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(\w+)', '$1	$2', 'm')" >_temp\sample-file.txt

_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[sample and not(@sampleof)]/@name" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)', '$1	$1', 'm')" >>_temp\sample-file.txt

echo list of bios
_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[%_isbios%]/@name" >_temp\bios.lst

echo romof bios, and games that need bios
_bin\xidel -s "_temp\%_dat%" -e "//%_tag%[@romof and not(@cloneof)]/(@name|@romof)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(\w+)', '$1	$2', 'm')" >_temp\temp.2
for /f %%g in (_temp\bios.lst) do findstr /e /c:"	%%g" _temp\temp.2 >>_temp\romof-bios.txt

echo list of all parents games that contain roms minus bios
_bin\xidel -s "_temp\%_dat%" -e "//!_tag![not(@cloneof) and not(%_isbios%) and not(@isdevice) and rom]/@name" >_temp\parents.lst
sort _temp\parents.lst /o _temp\parents.lst

echo rebuild datafile table for easy extraction
for /f %%g in (_temp\parents.lst) do findstr /b /c:"%%g	" "_temp\%_dat:~0,-4%.txt" >>_temp\parents.txt

cls&title building progettosnaps.net files...
for %%g in (sources\progettosnaps\*.dat) do (
	_bin\datutil -f generic -o _temp\temp.1 "%%g" >nul
	_bin\mamediff -s "_temp\%_dat%" _temp\temp.1 >nul
	move mamediff.out "_temp\MAME_latest.out" >nul
	del mamediff.log datutil.log
)
if not exist _temp\MAME_latest.out type nul>_temp\MAME_latest.out

rem //if not found create emtpy files***
for %%g in (catver.ini nplayers.ini bestgames.ini languages.ini series.ini) do (
	if exist "sources\progettosnaps\%%g" (copy /y sources\progettosnaps\%%g _temp)else (type nul>_temp\%%g)
)

echo catver.ini
_bin\xidel -s _temp\catver.ini --input-format=html -e "extract( $raw, '^\w+=[A-Z].+', 0, 'm*')" >_temp\cat.txt
_bin\xidel -s _temp\catver.ini --input-format=html -e "extract( $raw, '^\w+=[\d.]+', 0, 'm*')" >_temp\ver.txt
echo nplayers.ini
_bin\xidel -s _temp\nplayers.ini --input-format=html -e "extract( $raw, '^\w+=.+', 0, 'm*')" >_temp\nplayers.txt

call :convert_ini _temp\bestgames.ini
call :convert_ini _temp\languages.ini
call :convert_ini _temp\series.ini


cls&title building custom xml files... 
rem //if not found create emtpy files***
for %%g in (catver.ini hiscore.dat cheat.dat romstatus.xml artwork.lst) do (
	if exist "sources\%_dat:~0,-4%\%%g" (copy /y "sources\%_dat:~0,-4%\%%g" _temp)else (type nul>_temp\%%g)
)

echo catver.ini
rem //variable to prioritize custom catver.ini over progettosnaps
if exist "sources\%_dat:~0,-4%\catver.ini" (set _cat2=1)else (set _cat2=0)
_bin\xidel -s _temp\catver.ini --input-format=html -e "extract( $raw, '^\w+=[A-Z].+', 0, 'm*')" >_temp\cat2.txt

echo romstatus.xml
rem //this show error if xml file empty
_bin\xidel -s _temp\romstatus.xml -e "//Rom[Status]/(@name|Status)" >_temp\temp.1
_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^(\w+)\r\n(\w+)', '$1	$2', 'm')" >_temp\romstatus.txt

echo hiscore.dat and cheat.dat
_bin\xidel -s _temp\hiscore.dat -e "extract( $raw, '^(\w\w+):', 1, 'm*')" >_temp\hiscore.lst
sort /unique _temp\hiscore.lst /o _temp\hiscore.lst
_bin\xidel -s _temp\cheat.dat -e "extract( $raw, '^(\w\w+):', 1, 'm*')" >_temp\cheat.lst
sort /unique _temp\cheat.lst /o _temp\cheat.lst

rem //make a single list for header items for fast skipping
type _temp\nodump.lst >_temp\header.lst
type _temp\baddump.lst >>_temp\header.lst
type _temp\disk.lst >>_temp\header.lst
type _temp\cheat.lst >>_temp\header.lst
type _temp\hiscore.lst >>_temp\header.lst
type _temp\artwork.lst >>_temp\header.lst
_bin\xidel -s _temp\sample-file.txt -e "extract( $raw, '^(\w+)\t', 1, 'm*')" >>_temp\header.lst
_bin\xidel -s _temp\romof-bios.txt -e "extract( $raw, '^(\w+)\t', 1, 'm*')" >>_temp\header.lst

call :start_html

REM // for image script
(echo @echo off
echo echo Copying images to _IMAGES folder, will exit when done...
echo md _IMAGES) >>_temp\image_batch.txt

REM ****** line counter ************
set _total_lines=0
set _count_lines=0
set _percent=0
for /f "delims=" %%g in (_temp\parents.txt) do set /a _total_lines+=1
title "%_dat%" !_count_lines! / !_total_lines! ^( !_percent! %% ^)
REM *******************************

cls
for /f "tokens=1-3 delims=	" %%g in (_temp\parents.txt) do (
	echo %%g
	
	rem //side titles menu 
	(echo 		^<a href="main.html#%%g" target="main"^>%%i^</a^>^<br^>) >>_temp\side.html
	
	rem //game title
	(echo 	^<a id="%%g"^>^<h1 style="background-color:%%h;"^>%%i [%%g]^</h1^>^</a^>) >>_temp\main.html
	
	rem //heder labels
	findstr /x "%%g" _temp\header.lst >nul &&(
		echo ^<p^>^<center^>^<strong^>
		for /f %%j in ('findstr /x "%%g" _temp\artwork.lst') do echo 		^&emsp;[ARTWORK]
		for /f %%j in ('findstr /x "%%g" _temp\hiscore.lst') do echo 		^&emsp;[HI_SCORE]
		for /f %%j in ('findstr /x "%%g" _temp\cheat.lst') do echo 		^&emsp;[CHEATS]
		for /f %%j in ('findstr /x "%%g" _temp\nodump.lst') do echo 		^&emsp;[NO_DUMP]
		for /f %%j in ('findstr /x "%%g" _temp\baddump.lst') do echo 		^&emsp;[BAD_DUMP]
		for /f %%j in ('findstr /x "%%g" _temp\disk.lst') do echo 		^&emsp;[DISK]
		for /f %%j in ('findstr /b /c:"%%g	" _temp\sample-file.txt') do echo 		^&emsp;[SAMPLES]
		for /f %%j in ('findstr /b /c:"%%g	" _temp\romof-bios.txt') do echo 		^&emsp;[BIOS]
		echo ^</strong^>^</center^>^</p^>
	) >>_temp\main.html
	
	rem //get cross-reference list
	for %%j in (datafiles\*.dat datafiles\*.xml) do (
		if not "%%~nxj"=="%_dat%" (
			for /f "tokens=2" %%k in ('findstr /rb /c:"%%g	." "_temp\%%~nj.out"') do (
				for /f "tokens=1,2,3 delims=	" %%l in ('findstr /b /c:"%%k	" "_temp\%%~nj.txt"') do echo 		^<strong^>%%~nj: ^</strong^>^<font color="%%m"^>%%n [%%l]^</font^>^<br^>
			)
		)
	) >>_temp\main.html
	
	rem //progettosnaps.net ******
	set _alt=%%g
	for /f "tokens=2" %%j in ('findstr /rb /c:"%%g	." _temp\MAME_latest.out') do (
		set _alt=%%j
		echo ^<p^>
		echo 		^<a href="http://adb.arcadeitalia.net/?mame=%%j&lang=en" target="_blank"^>Arcade Database [%%j]^</a^>^<br^>

		if %_cat2% equ 0 for /f "tokens=2 delims==" %%k in ('findstr /b "%%j=" _temp\cat.txt') do echo 		^<strong^>Category:^</strong^> %%k^<br^>
		for /f "tokens=2 delims==" %%k in ('findstr /b "%%j=" _temp\ver.txt') do echo 		^<strong^>Version Added:^</strong^> %%k^<br^>
		for /f "tokens=2 delims==" %%k in ('findstr /b "%%j=" _temp\nplayers.txt') do echo 		^<strong^>Nplayers:^</strong^> %%k^<br^>
		for /f "tokens=2 delims==" %%k in ('findstr /b "%%j=" _temp\series.txt') do echo 		^<strong^>Series:^</strong^> %%k^<br^>
		for /f "tokens=2 delims==" %%k in ('findstr /b "%%j=" _temp\bestgames.txt') do echo 		^<strong^>Rating:^</strong^> %%k^<br^>
		for /f "tokens=2 delims==" %%k in ('findstr /b "%%j=" _temp\languages.txt') do echo 		^<strong^>Language:^</strong^> %%k^<br^>
		echo ^</p^>
	) >>_temp\main.html
	
	rem //copy images from latest progettosnaps pack
	(echo copy /y !_alt!.png _IMAGES\%%g.png^>nul ^|^| echo %%g^>^>notfound.txt) >>_temp\image_batch.txt
	
	(
		rem //custom datafile info
		echo ^<p^>
		for /f "tokens=2 delims=	" %%j in ('findstr /b /c:"%%g	" _temp\romstatus.txt') do echo 		^<strong^>ROMstatus_XML:^</strong^> %%j^<br^>
		if %_cat2% equ 1 for /f "tokens=2 delims==" %%j in ('findstr /b "%%g=" _temp\cat2.txt') do echo 		^<strong^>Category:^</strong^> %%j^<br^>

		rem //xml information
		for /f "tokens=2 delims=	" %%j in ('findstr /b /c:"%%g	" _temp\manuf.txt') do echo 		^<strong^>Manufacturer:^</strong^> %%j^<br^>
		for /f "tokens=2 delims=	" %%j in ('findstr /b /c:"%%g	" _temp\year.txt') do echo 		^<strong^>Year:^</strong^> %%j^<br^>
		for /f "tokens=2 delims=	" %%j in ('findstr /b /c:"%%g	" _temp\sourcefile.txt') do echo 		^<strong^>Sourcefile:^</strong^> %%j^<br^>
		for /f "tokens=2 delims=	" %%j in ('findstr /b /c:"%%g	" _temp\sample-file.txt') do echo 		^<strong^>Samples:^</strong^> %%j.zip^<br^>
		for /f "tokens=2 delims=	" %%j in ('findstr /b /c:"%%g	" _temp\romof-bios.txt') do echo 		^<strong^>BIOS:^</strong^> %%j.zip^<br^>
		
		rem //list clones
		set _flag=0
		for /f "tokens=1" %%j in ('findstr /e /c:"	%%g" _temp\cloneof.txt') do (
			if !_flag! equ 0 echo 		^<strong^>Clones:^</strong^>^<br^>
			for /f "tokens=1,2,3 delims=	" %%k in ('findstr /b /c:"%%j	" "_temp\%_dat:~,-4%.txt"') do echo 		^<font color="%%l"^>^&emsp;%%m [%%k]^</font^>^<br^>
			set _flag=1
		)
		echo ^</p^>
	) >>_temp\main.html
	
	rem //add images
	(echo 	^<img src="snaps\%%g.png" loading="lazy"^>
	echo 	^<img src="titles\%%g.png" loading="lazy"^>) >>_temp\main.html
	
	rem //only show status information if game dosent have good status, overwrite for simple driver field
	if "%_drv_spl%"=="true" (set _status=green)else (set _status=%%h)
	
	if not !_status!==green (
		echo ^<p^>^<center^>^<strong^>
		for /f %%j in ('findstr /x "%%g" _temp\emulation.lst') do echo 		^<font color="red"^>^&emsp;[EMULATION]^</font^>
		for /f "tokens=2-4" %%j in ('findstr /b /c:"%%g	" _temp\status.txt') do echo 		^<font color="%%j"^>^&emsp;[COLORS]^</font^>^<font color="%%k"^>^&emsp;[SOUND]^</font^>^<font color="%%l"^>^&emsp;[GRAPHICS]^</font^>
		for /f %%j in ('findstr /x "%%g" _temp\protection.lst') do echo 		^<font color="red"^>^&emsp;[PROTECTION]^</font^>
		echo ^</strong^>^</center^>^</p^>
	) >>_temp\main.html
	
	
	REM ****** line counter ************	
	set /a _count_lines+=1
	set /a "_percent=(!_count_lines!*100)/!_total_lines!"
	title "%_dat%" !_count_lines! / !_total_lines! ^( !_percent! %% ^)
	REM *****************************
)

call :end_html

md output 2>nul
md "output\%_dat:~0,-4%" 2>nul
md "output\%_dat:~0,-4%\visual_database" 2>nul
md "output\%_dat:~0,-4%\visual_database\titles" 2>nul
md "output\%_dat:~0,-4%\visual_database\snaps" 2>nul

copy /y _temp\image_batch.txt "output\%_dat:~0,-4%\image_batch.bat"

copy /y _temp\main.html "output\%_dat:~0,-4%\visual_database"
copy /y _temp\side.html "output\%_dat:~0,-4%\visual_database"
copy /y _temp\index.html "output\%_dat:~0,-4%"


title FINISHED
pause&exit


:convert_ini
echo converting %~nx1...

type nul>_temp\%~n1.txt
for /f "delims=" %%g in (%1) do (
	set "_str=%%g"
	if "!_str:~0,1!"=="[" (
		for /f "delims=][" %%h in ("%%g") do set "_temp=%%h"
		
	)else (
		for %%h in ("%%g=!_temp!") do echo %%~h
	)

) >>_temp\%~n1.txt

exit /b


:end_html

REM // main html document - close
(echo ^</body^>
echo ^</html^>) >>_temp\main.html

REM // side titles menu - close
(echo 	^</p^>
echo ^</body^>
echo ^</html^>) >>_temp\side.html

exit /b


:start_html

REM //lancher
(echo ^<^^!DOCTYPE html^>
echo ^<html^>
echo ^<head^>
for %%g in ("%_dat:~0,-4%") do echo 	^<title^>%%~g^</title^>
echo ^</head^>
echo ^<frameset frameborder="1" cols="20%%,80%%"^>
echo 	^<frame name="side" src="visual_database\side.html"/^>
echo 	^<frame name="main" src="visual_database\main.html"/^>
echo 	^<noframes^>
echo		 ^<body^>Your browser does not support frames.^</body^>
echo 	^</noframes^>
echo ^</frameset^>
echo ^</html^>) >_temp\index.html

REM //side titles menu - start 
(echo ^<^^!DOCTYPE html^>
echo ^<html^>
echo ^<head^>
REM echo 	^<title^>"%_option%"^</title^>
echo 	^<style^>
echo 		p { white-space:nowrap; }
echo 		a { color:#5F2F03; text-decoration:none; }
echo 		body { background-color:powderblue; }
echo 	^</style^>
echo ^</head^>
echo ^<body^>
echo 	^<p^>) >_temp\side.html

REM // main html document - start
(echo ^<^^!DOCTYPE html^>
echo ^<html^>
echo ^<head^>
REM echo    ^<title^>"%_option%"^</title^>
echo 	^<style^>
echo 		body { background-color:powderblue; }
echo 	^</style^>
echo ^</head^>
echo ^<body^>) >_temp\main.html



exit /b