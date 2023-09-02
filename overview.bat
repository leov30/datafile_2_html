@echo off
setlocal enabledelayedexpansion

if not exist _bin\xidel.exe title ERROR&echo This script needs _bin\xidel.exe&pause&exit
if not exist _bin\datutil.exe title ERROR&echo This script needs _bin\datutil.exe&pause&exit

rem //no support for mame2003 plus datafile ***********************
if not exist _temp (md _temp)else (del /q /s _temp >nul)

rem //fill in missing tags, convert, and verify datafiles
for %%g in (datafiles\*.xml datafiles\*.dat) do (
	call :add_missing "%%g"
)


if not exist _temp\datafiles.lst title ERROR&echo No datafiles were found, or error converting...&pause&exit


REM goto :skip
rem //datafiles rquire to have: description, manufacturer, year, isbios
for /f "delims=" %%g in (_temp\datafiles.lst) do (
	echo %%~ng
	
	REM _bin\xidel -s "%%~g" -e "replace( $raw, '^<\WDOCTYPE mame \[.+?\]>', '', 'ms')" >_temp\temp.1
	_bin\xidel -s "%%~g" -e "replace( $raw, '<game( isbios=\""yes\"")? name=\""(\w+)\""(.*?)>', '<game$1 name=\""/g$2\""$3>')" >_temp\temp.2
	_bin\xidel -s _temp\temp.2 -e "replace( $raw, 'cloneof=\""(\w+)\""', 'cloneof=\""/c$1\""')" >_temp\temp.1
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, 'romof=\""(\w+)\""', 'romof=\""/r$1\""')" >_temp\temp.2
	_bin\xidel -s _temp\temp.2 -e "replace( $raw, '<description>(.+?)</description>', '<description>/d$1</description>')" >_temp\temp.1
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, '<manufacturer>(.+?)</manufacturer>', '<manufacturer>/m$1</manufacturer>')" >_temp\temp.2
	_bin\xidel -s _temp\temp.2 -e "replace( $raw, '<year>(.+?)</year>', '<year>/y$1</year>')" >_temp\temp.xml
	
	_bin\xidel -s _temp\temp.xml -e "//game[description and year and manufacturer]/(@isbios|@name|@cloneof|@romof|description|year|manufacturer|driver/@status)" >_temp\main.1
	
	
	rem //get a list of parent with romof = bios
	_bin\xidel -s _temp\temp.xml -e "//game[@romof and not(@cloneof)]/(@name|@romof)" >_temp\temp.1
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^/g(\w+)\r\n/r(\w+)', '$1	$2', 'm')" >_temp\index.1
	
	rem //replace all instances of romof = parent with bios
	for /f "tokens=1,2" %%h in (_temp\index.1) do (
		_bin\xidel -s _temp\main.1 -e "replace( $raw, '^/r%%h$', '/b%%i', 'm')" >_temp\temp.1
		del _temp\main.1 & ren _temp\temp.1 main.1

	)
	
	REM echo 	table, th, td {border: 1px solid black; border-collapse: collapse;}
	(echo ^<^^!DOCTYPE html^>
	echo ^<html^>
	echo ^<head^>
	echo ^<style^>
	echo 	body {background-color:powderblue;}
	echo 	table {border-collapse: collapse;width: 100%%;}
	echo 	table td, th {border: 1px solid black;padding: 8px;}
	REM echo 	table tr:nth-child^(even^){background-color: #f2f2f2;}
	echo 	table tr:hover {background-color: #ddd;}
	echo 	table th {padding-top: 12px;padding-bottom: 12px;text-align: center;background-color: #04AA6D;color: white;}
	echo 	table td#preliminary {background-color: #F66767;}
	echo 	table td#imperfect {background-color: #F7CD5E;}
	echo ^</style^>
	echo ^<title^>%%~ng^</title^>
	echo ^</head^>
	echo ^<body^>
	echo ^<table^>
	echo ^<tr^>^<th^>name^</th^>^<th^>cloneof^</th^>^<th^>description^</th^>^<th^>year^</th^>^<th^>manufacturer^</th^>^<th^>status^</th^>^<th^>bios^</th^>^<th^>samples^</th^>^<th^>disk^</th^>^</tr^>) >"_temp\%%~ng.html"
	
	set "_driver="
	for /f %%h in ('_bin\xidel -s _temp\temp.xml -e "matches( $raw, '<driver status=\""good\""')"') do if %%h==true set "_driver=\r\n([a-z]+)"
	
	
	rem //bios
	_bin\xidel -s _temp\main.1 -e "replace( $raw, '^yes\r\n/g(\w+)\r\n/d(.+?)\r\n/y(.+?)\r\n/m(.+)!_driver!', '<tr><td>$1</td><td></td><td>$2</td><td>$3</td><td>$4</td><td id=\""$5\"">$5</td><td>bios</td><td>sample=\""$1\""</td><td>disk=\""/g$1\""</td></tr>', 'm')" >_temp\temp.1
	
	rem //cloneof
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^/g(\w+)\r\n/c(\w+)\r\n/r\w+\r\n/d(.+?)\r\n/y(.+?)\r\n/m(.+)!_driver!', '<tr><td>$1</td><td>$2</td><td>$3</td><td>$4</td><td>$5</td><td id=\""$6\"">$6</td><td></td><td>sample=\""$1\""</td><td>disk=\""/g$1\""</td></tr>', 'm')" >_temp\temp.2
	
	rem //cloneof with bios
	_bin\xidel -s _temp\temp.2 -e "replace( $raw, '^/g(\w+)\r\n/c(\w+)\r\n/b(\w+)\r\n/d(.+?)\r\n/y(.+?)\r\n/m(.+)!_driver!', '<tr><td>$1</td><td>$2</td><td>$4</td><td>$5</td><td>$6</td><td id=\""$7\"">$7</td><td>$3</td><td>sample=\""$1\""</td><td>disk=\""/g$1\""</td></tr>', 'm')" >_temp\temp.1
	
	rem //parent with bios
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^/g(\w+)\r\n/r(\w+)\r\n/d(.+?)\r\n/y(.+?)\r\n/m(.+)!_driver!', '<tr><td>$1</td><td></td><td>$3</td><td>$4</td><td>$5</td><td id=\""$6\"">$6</td><td>$2</td><td>sample=\""$1\""</td><td>disk=\""/g$1\""</td></tr>', 'm')" >_temp\temp.2

	rem //parents
	_bin\xidel -s _temp\temp.2 -e "replace( $raw, '^/g(\w+)\r\n/d(.+?)\r\n/y(.+?)\r\n/m(.+)!_driver!', '<tr><td>$1</td><td></td><td>$2</td><td>$3</td><td>$4</td><td id=\""$5\"">$5</td><td></td><td>sample=\""$1\""</td><td>disk=\""/g$1\""</td></tr>', 'm')" >>"_temp\%%~ng.html"

	(echo ^</table^>
	echo ^</body^>
	echo ^</html^>) >>"_temp\%%~ng.html"
	
	rem //get games that require samples, but are not sample of another game
	_bin\xidel -s _temp\temp.xml -e "//game[not(@sampleof) and sample]/@name" >_temp\temp.1
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^/g(\w+)', '$1	$1', 'm')" >_temp\index.1
	
	rem //get all games that are sample of another game
	_bin\xidel -s _temp\temp.xml -e "//game[@sampleof]/(@name|@sampleof)" >_temp\temp.1
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^/g(\w+)\r\n(\w+)', '$1	$2', 'm')" >>_temp\index.1
	
	for /f "tokens=1,2" %%h in (_temp\index.1) do (
		_bin\xidel -s "_temp\%%~ng.html" -e "replace( $raw, 'sample=\""%%h\""', '%%i')" >_temp\temp.1
		del "_temp\%%~ng.html" & ren _temp\temp.1 "%%~ng.html"
	
	)
	
	rem //get all games with disk 
	for /f %%h in ('_bin\xidel -s _temp\temp.xml -e "//game[disk]/@name"') do (
		_bin\xidel -s "_temp\%%~ng.html" -e "replace( $raw, 'disk=\""%%h\""', 'disk')" >_temp\temp.1
		del "_temp\%%~ng.html" & ren _temp\temp.1 "%%~ng.html"
	
	)
	
	rem //delete leftovers
	_bin\xidel -s "_temp\%%~ng.html" -e "replace( $raw, 'sample=\""\w+\""|disk=\""/g\w+\""| id=\""\""', '')" >_temp\temp.1
	del "_temp\%%~ng.html" & ren _temp\temp.1 "%%~ng.html"
	
	
)

rem // make table.html
call :count_xml

rem //make status info, no support for mame2003plus, only for games with full driver status
for /f "delims=" %%g in (_temp\datafiles.lst) do call :make_status %%g


rem //clean empty sapces, remove unescesary id tag from html files
for %%g in (_temp\*.html) do (
	_bin\xidel -s "%%g" -e "replace( $raw, '^\r\n[\r\n]+', codepoints-to-string((13,10)), 'm')" >_temp\temp.1
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, ' id=\""good\""', '')" >"%%g"
)

rem //delete last column if no disk in datafile
for %%g in (_temp\*.html) do (
	for /f %%h in ('_bin\xidel -s "%%g" -e "matches( $raw, '<td>disk</td></tr>$', 'm')"') do if %%h==false (
		_bin\xidel -s "%%g" -e "replace( $raw, '<td></td></tr>$', '</tr>', 'm')" >_temp\temp.1
		_bin\xidel -s _temp\temp.1 -e "replace( $raw, '<th>disk</th></tr>$', '</tr>', 'm')" >"%%g"
	)
)



cls
rem //add the header back 
for /f "delims=" %%g in (_temp\datafiles.lst) do (
	_bin\datutil -k -f listxml -o _temp\temp.1 "%%~g" >nul
	del "%%~g" & ren _temp\temp.1 "%%~ng.xml"

)
del datutil.log

pause&exit



:make_status
	rem //only support full status driver
	for /f %%g in ('_bin\xidel -s "%~1" -e "matches( $raw, 'emulation=\""good\""')"') do if %%g==false exit /b


	_bin\xidel -s "%~1" -e "replace( $raw, '<game name=\""(\w+)\""(.*?)>', '<game name=\""/g$1\""$2>')" >_temp\temp.2
	_bin\xidel -s _temp\temp.2 -e "replace( $raw, 'cloneof=\""(\w+)\""', 'cloneof=\""/c$1\""')" >_temp\temp.1
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, '<description>(.+?)</description>', '<description>/d$1</description>')" >_temp\temp.xml

	REM <driver status="preliminary" emulation="preliminary" color="good" sound="good" graphic="good" protection="preliminary"/>
	
	
	
	
	(echo ^<^^!DOCTYPE html^>
	echo ^<html^>
	echo ^<head^>
	echo ^<style^>
	echo 	body {background-color:powderblue;}
	echo 	table {border-collapse: collapse;width: 100%%;}
	echo 	table td, th {border: 1px solid black;padding: 8px;}
	echo 	table tr:hover {background-color: #ddd;}
	echo 	table th {padding-top: 12px;padding-bottom: 12px;text-align: center;background-color: #04AA6D;color: white;}
	echo 	table td#preliminary {background-color: #F66767;}
	echo 	table td#imperfect {background-color: #F7CD5E;}
	echo ^</style^>
	echo ^<title^>%~n1^</title^>
	echo ^</head^>
	echo ^<body^>
	echo ^<table^>
	echo ^<tr^>^<th^>name^</th^>^<th^>cloneof^</th^>^<th^>description^</th^>^<th^>emulation^</th^>^<th^>color^</th^>^<th^>sound^</th^>^<th^>graphic^</th^>^<th^>protection^</th^>^</tr^>) >"_temp\status_%~n1.html"
	
	rem //no bios, and has roms
	_bin\xidel -s _temp\temp.xml -e "//game[driver and not(@isbios) and rom]/driver/(../@name|../@cloneof|../description|@status|@emulation|@color|@sound|@graphic)" >_temp\main.1
	
		
	rem //clones, skipng overall status
	_bin\xidel -s _temp\main.1 -e "replace( $raw, '^/g(\w+)\r\n/c(\w+)\r\n/d(.+?)\r\n([a-z]+)\r\n([a-z]+)\r\n([a-z]+)\r\n([a-z]+)\r\n([a-z]+)', '<tr><td>$1</td><td>$2</td><td>$3</td><td id=\""$5\"">emulation=\""$5\""</td><td id=\""$6\"">color=\""$6\""</td><td id=\""$7\"">sound=\""$7\""</td><td id=\""$8\"">graphic=\""$8\""</td><td>protection=\""/g$1\""</td></tr>', 'm')" >_temp\temp.1
	rem //parents, skipng overall status
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^/g(\w+)\r\n/d(.+?)\r\n([a-z]+)\r\n([a-z]+)\r\n([a-z]+)\r\n([a-z]+)\r\n([a-z]+)', '<tr><td>$1</td><td></td><td>$2</td><td id=\""$4\"">emulation=\""$4\""</td><td id=\""$5\"">color=\""$5\""</td><td id=\""$6\"">sound=\""$6\""</td><td id=\""$7\"">graphic=\""$7\""</td><td>protection=\""/g$1\""</td></tr>', 'm')" >>"_temp\status_%~n1.html"
	
	(echo ^</table^>
	echo ^</body^>
	echo ^</html^>) >>"_temp\status_%~n1.html"
	
	rem //get all games with protection
	for /f %%h in ('_bin\xidel -s _temp\temp.xml -e "//game[driver]/driver[@protection='preliminary']/../@name"') do (
		_bin\xidel -s "_temp\status_%~n1.html" -e "replace( $raw, '<td>protection=\""%%h\""</td>', '<td id=\""preliminary\"">bad protection</td>')" >_temp\temp.1
		del "_temp\status_%~n1.html" & ren _temp\temp.1 "status_%~n1.html"
	)
	

	
	rem //give descreptive status information
	for %%h in (emulation color sound graphic) do (
		_bin\xidel -s "_temp\status_%~n1.html" -e "replace( $raw, '%%h=\""preliminary\""', 'bad %%h')" >_temp\temp.1
		_bin\xidel -s _temp\temp.1 -e "replace( $raw, '%%h=\""imperfect\""', 'imperfect %%h')" >"_temp\status_%~n1.html"
	
	)
	
	
	rem //delete leftovers
	_bin\xidel -s "_temp\status_%~n1.html" -e "replace( $raw, '<td>protection=\""/g\w+\""</td>', '<td id=\""good\"">good</td>')" >_temp\temp.1
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, '[a-z]+=\""good\""', 'good')" >"_temp\status_%~n1.html"
	

exit /b


:add_missing
	echo %1
	
	rem //detect mame2003plus driver
	copy "%~1" _temp\temp.xml
	
	
	for /f %%g in ('_bin\xidel -s _temp\temp.xml -e "matches( $raw, '<driver status=\""protection\""')"') do if %%g==true (
	
		_bin\xidel -s _temp\temp.xml -e "replace( $raw, ' palettesize=\""\d+\""', '', 'm')" >_temp\temp.1
		_bin\xidel -s _temp\temp.1 -e "replace( $raw, '<driver status=\""(\w+)\""', '<driver status=\""good\"" emulation=\""$1\""', 'm')" >_temp\temp.2


		_bin\xidel -s _temp\temp.2 -e "replace( $raw, '<driver status=\""good\""( emulation=\""preliminary\"" color=\""\w+\"" sound=\""\w+\"" graphic=\""\w+\"")/>', '<driver status=\""preliminary\"" $1/>', 'm')" >_temp\temp.1
		_bin\xidel -s _temp\temp.1 -e "replace( $raw, '<driver status=\""good\""( emulation=\""\w+\"" color=\""preliminary\"" sound=\""\w+\"" graphic=\""\w+\"")/>', '<driver status=\""preliminary\"" $1/>', 'm')" >_temp\temp.2
		_bin\xidel -s _temp\temp.2 -e "replace( $raw, '<driver status=\""good\""( emulation=\""\w+\"" color=\""\w+\"" sound=\""preliminary\"" graphic=\""\w+\"")/>', '<driver status=\""preliminary\"" $1/>', 'm')" >_temp\temp.1
		_bin\xidel -s _temp\temp.1 -e "replace( $raw, '<driver status=\""good\""( emulation=\""\w+\"" color=\""\w+\"" sound=\""\w+\"" graphic=\""preliminary\"")/>', '<driver status=\""preliminary\"" $1/>', 'm')" >_temp\temp.xml


		_bin\xidel -s _temp\temp.xml -e "replace( $raw, '<driver status=\""good\""( emulation=\""imperfect\"" color=\""\w+\"" sound=\""\w+\"" graphic=\""\w+\"")/>', '<driver status=\""imperfect\"" $1/>', 'm')" >_temp\temp.1
		_bin\xidel -s _temp\temp.1 -e "replace( $raw, '<driver status=\""good\""( emulation=\""\w+\"" color=\""imperfect\"" sound=\""\w+\"" graphic=\""\w+\"")/>', '<driver status=\""imperfect\"" $1/>', 'm')" >_temp\temp.2
		_bin\xidel -s _temp\temp.2 -e "replace( $raw, '<driver status=\""good\""( emulation=\""\w+\"" color=\""\w+\"" sound=\""imperfect\"" graphic=\""\w+\"")/>', '<driver status=\""imperfect\"" $1/>', 'm')" >_temp\temp.1
		_bin\xidel -s _temp\temp.1 -e "replace( $raw, '<driver status=\""good\""( emulation=\""\w+\"" color=\""\w+\"" sound=\""\w+\"" graphic=\""imperfect\"")/>', '<driver status=\""imperfect\"" $1/>', 'm')" >_temp\temp.2

		rem //not_working status its lost 
		_bin\xidel -s _temp\temp.2 -e "replace( $raw, '<driver status=\""\w+\"" emulation=\""protection\"" (color=\""\w+\"" sound=\""\w+\"" graphic=\""\w+\"")/>', '<driver status=\""preliminary\"" emulation=\""good\"" $1 protection=\""preliminary\""/>', 'm')" >_temp\temp.xml

	)
	
	rem //convert to xml and keep the driver field, if fail use generic xml format and loose driver field
	_bin\datutil -k -f listxml -o _temp\temp.1 _temp\temp.xml >nul || (
		_bin\datutil -f generic -o _temp\temp.1 _temp\temp.xml >nul || exit /b
	
	)
	
	
	rem //remove this because it breaks xidel...
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^<\WDOCTYPE mame \[.+?\]>', '', 'ms')" >_temp\temp.xml
	
	
	rem //check if there are games with missing "description"
	for /f %%h in ('_bin\xidel -s _temp\temp.xml -e "//game[not(description)]/@name"') do (
		echo %%~ng ^< added missing "description"
		_bin\xidel -s _temp\temp.xml -e "replace( $raw, '(<game(?: isbios=\""yes\"")? name=\""%%h\"".*?>)(\r\n)', '$1$2		<description>????</description>$2')" >_temp\temp.1
		del _temp\temp.xml & ren _temp\temp.1 temp.xml
			
	)
	
	rem //check if there are games with missing "manufacturer"
	for /f %%h in ('_bin\xidel -s _temp\temp.xml -e "//game[not(manufacturer)]/@name"') do (
		echo %%~ng ^< added missing "manufacturer"
		_bin\xidel -s _temp\temp.xml -e "replace( $raw, '(<game(?: isbios=\""yes\"")? name=\""%%h\"".*?>)(\r\n)', '$1$2		<manufacturer>????</manufacturer>$2')" >_temp\temp.1
		del _temp\temp.xml & ren _temp\temp.1 temp.xml
			
	)
	
	rem //check if there are games with missing "year"
	for /f %%h in ('_bin\xidel -s _temp\temp.xml -e "//game[not(year)]/@name"') do (
		echo %%~ng ^< added missing "year"
		_bin\xidel -s _temp\temp.xml -e "replace( $raw, '(<game(?: isbios=\""yes\"")? name=\""%%h\"".*?>)(\r\n)', '$1$2		<year>????</year>$2')" >_temp\temp.1
		del _temp\temp.xml & ren _temp\temp.1 temp.xml
			
	)
	
	rem //check if xml has driver
	for /f %%h in ('_bin\xidel -s _temp\temp.xml -e "matches( $raw, '<driver status=\""\w+\"".+')"') do if %%h==true (
	
		rem //check if its simple or full
		for /f %%h in ('_bin\xidel -s _temp\temp.xml -e "matches( $raw, '<driver status=\""\w+\""/>')"') do if %%h==true set "_driver=status=\""good\"""
		for /f %%h in ('_bin\xidel -s _temp\temp.xml -e "matches( $raw, '<driver status=\""\w+\"".+/>')"') do if %%h==true set "_driver=status=\""good\"" emulation=\""good\"" color\""good\"" sound=\""good\"" graphic=\""good\"""
	
		rem //check if there are games with missing "driver"
		for /f %%h in ('_bin\xidel -s _temp\temp.xml -e "//game[not(driver)]/@name"') do (
			echo %%~ng ^< added missing "driver status"
			echo %%h >>_temp\driver.txt
			
			_bin\xidel -s _temp\temp.xml -e "replace( $raw, '(<game(?: isbios=\""yes\"")? name=\""%%h\"".*?>)(\r\n)', '$1$2		<driver !_driver!/>$2')" >_temp\temp.1
			del _temp\temp.xml & ren _temp\temp.1 temp.xml
				
		)
		
	)
	
	rem //add to good datafile list
	(echo "_temp\%~n1.xml") >>_temp\datafiles.lst
	
	rem //use datutil again to put everything togheter, and sort
	REM _bin\datutil -s -l -k -f listxml -o "_temp\%~n1.xml" _temp\temp.xml >nul
	
	
	_bin\datutil -s -l -k -f listxml -o _temp\temp.1 _temp\temp.xml >nul
	_bin\xidel -s _temp\temp.1 -e "replace( $raw, '^<\WDOCTYPE mame \[.+?\]>', '', 'ms')" >"_temp\%~n1.xml"
	
	del _temp\temp.xml


exit /b


:count_xml

title Making table.html...

rem //build a single table html with info on all found datafiles
(echo ^<table^>
echo ^<tr^>^<th^>Datafile^</th^>^<th^>Parents^</th^>^<th^>Clones^</th^>^<th^>BIOS^</th^>^<th^>Samples^</th^>^<th^>Disk^</th^>^</tr^>) >_temp\table.html
 
REM echo datafiles	parents	clones	bios	samples	disk>_temp\report.csv
for /f "delims=" %%g in (_temp\datafiles.lst) do (
	echo %%~g
	
	rem //count parents
	set _parents=0
	for /f %%h in ('_bin\xidel -s "%%~g" -e "//game[not(@cloneof) and not(@isbios) and rom]/@name"') do set /a _parents+=1
	
	rem //count clones
	set _clones=0
	for /f %%h in ('_bin\xidel -s "%%~g" -e "//game[@cloneof and rom]/@name"') do set /a _clones+=1

	rem //count bios
	set _bios=0
	for /f %%h in ('_bin\xidel -s "%%~g" -e "//game[@isbios]/@name"') do set /a _bios+=1
	
	rem //count samples
	set _samples=0
	_bin\xidel -s "%%~g" -e "//game[not(@sampleof) and sample]/@name" >_temp\index.1
	for /f %%h in ('_bin\xidel -s "%%~g" -e "//game[not(@sampleof) and sample]/@name"') do set /a _samples+=1
	
	rem //count disk
	set _disk=0
	_bin\xidel -s "%%~g" -e "//game[disk]/@name" >_temp\index.1
	for /f %%h in ('_bin\xidel -s "%%~g" -e "//game[disk]/@name"') do set /a _disk+=1

	
	(echo ^<tr^>^<td^>%%~ng^</td^>^<td^>!_parents!^</td^>^<td^>!_clones!^</td^>^<td^>!_bios!^</td^>^<td^>!_samples!^</td^>^<td^>!_disk!^</td^>^</tr^>) >>_temp\table.html

)

(echo ^</table^>) >>_temp\table.html


exit /b
