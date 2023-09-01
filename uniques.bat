@echo off
setlocal enabledelayedexpansion

if not exist _bin\xidel.exe title ERROR&echo This script needs _bin\xidel.exe&pause&exit
if not exist _bin\datutil.exe title ERROR&echo This script needs _bin\datutil.exe&pause&exit

if not exist _temp (md _temp)else (del /q /s _temp >nul)
rem //use folders by datafile
for %%g in (datafiles\*.xml datafiles\*.dat) do (
	echo %%~ng
	for %%h in (datafiles\*.xml datafiles\*.dat) do (
		if not "%%~ng"=="%%~nh" (
			echo 	%%~nh
			call :mamediff "%%g" "%%h"
			
		)
	)
)
del mamediff.log datutil.log dat.1 dat.2




title searching throug gamelist...
rem //unique games
rem //just print games thaa only shows up in that emulator
for %%g in (_temp\*.lst) do (
	echo ^>%%~ng
	rem //read the gamelist
	for /f "usebackq" %%h in ("%%g") do (
		REM echo %%h
		set _found=0
		for /f "delims=" %%i in ('findstr /mrb /c:"%%h	[a-z0-9_].*" "_temp\%%~ng\*.out"') do (
			REM echo 	%%~ni
			set /a _found+=1
		)
		
		if !_found! equ 0 findstr /rb /c:" *%%h  *" "_temp\%%~ng.txt" >>"_temp\unique_%%~ng.equ"
	
	)
	
	
)




rem //games by found datafile
for %%g in (_temp\*.lst) do (
	echo ^>%%~ng
	REM (echo ;; %%~ng ;; indented games are CLONES&echo: >>"_temp\%%~ng.equ"
	rem //read the gamelist
	for /f "usebackq" %%h in ("%%g") do (
		REM echo %%h
		findstr /rb /c:" *%%h  *" "_temp\%%~ng.txt" 
		for /f "delims=" %%i in ('findstr /mrb /c:"%%h	[a-z0-9_].*" "_temp\%%~ng\*.out"') do echo 	%%~ni
	
	) >>"_temp\%%~ng.equ"
)



pause&exit



:mamediff

rem //mamediff has issues with sha1 in datafiles, try other formats? hangs if there are no matches?...
_bin\datutil -f romcenter2 -o dat.1 "%~1" >nul
_bin\datutil -f romcenter2 -o dat.2 "%~2" >nul

rem //titles list
_bin\datutil -f titles -o "_temp\%~n1.txt" "%~1" >nul

REM _bin\xidel -s "%~1" -e "replace( $raw, ' sha1=\""[a-f\d]{40}\""|^\t\t<disk name.+?>\r\n', '', 'm')" >dat.1
REM _bin\xidel -s "%~2" -e "replace( $raw, ' sha1=\""[a-f\d]{40}\""|^\t\t<disk name.+?>\r\n', '', 'm')" >dat.2

_bin\mamediff -s dat.1 dat.2 >nul || echo failed "%~n2"

if not exist "_temp\%~n1.lst" for /f %%i in ('findstr /br /c:"[a-z0-9_][a-z0-9_]*	" mamediff.out') do echo %%i>>"_temp\%~n1.lst"

md "_temp\%~n1" 2>nul
move /y mamediff.out "_temp\%~n1\%~n2.out">nul



exit /b