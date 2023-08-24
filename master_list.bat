@echo off

if not exist _temp (md _temp)else (del /q _temp)

for %%g in (datafiles\*.xml) do (
	echo %%g
	 _bin\xidel -s "%%g" -e "replace( $raw, '^<\WDOCTYPE mame \[.+?\]>', '', 'ms')" >_temp\temp.1
	 
	 for /f %%h in ('_bin\xidel -s _temp\temp.1 -e "matches( $raw, '<driver status')"') do if %%h==true (
		_bin\xidel -s _temp\temp.1 -e "//game[description]/driver/(../@name|../description|@status)" >_temp\master.tmp
		_bin\xidel -s _temp\master.tmp -e "replace( $raw, '^(\w+)\r\n(.+?)\r\n(\w+)', '$2	$1	$3	%%~ng', 'm')" >>_temp\master.txt
	 
	 )else (
	 	 _bin\xidel -s _temp\temp.1 -e "//game[description]/(@name|description)" >_temp\master.tmp
		_bin\xidel -s _temp\master.tmp -e "replace( $raw, '^(\w+)\r\n(.+)', '$2	$1	no_info	%%~ng', 'm')" >>_temp\master.txt
	 
	 
	 )
	 


)

sort _temp\master.txt /o _temp\master.txt


	REM (echo ^<^!DOCTYPE html^>
	(echo ^<html^>
	echo ^<head^>
	echo ^<style^>
	echo 	body {background-color:powderblue;}
	echo 	table {border-collapse: collapse;width: 100%%;}
	echo 	table td, th {border: 1px solid black;padding: 8px;}
	echo 	table tr:hover {background-color: #ddd;}
	echo 	table th {padding-top: 12px;padding-bottom: 12px;text-align: center;background-color: #04AA6D;color: white;}
	echo 	table td#preliminary {background-color: F66767;}
	echo 	table td#imperfect {background-color: F7CD5E;}
	echo ^</style^>
	echo ^<title^>MASTER LIST^</title^>
	echo ^</head^>
	echo ^<body^>
	echo ^<table^>
	echo ^<tr^>^<th^>description^</th^>^<th^>name^</th^>^<th^>status^</th^>^<th^>datafile^</th^>^</tr^>) >_temp\master.html


REM echo ^<table^>>>_temp\master.html
_bin\xidel -s _temp\master.txt -e "replace( $raw, '^(.+?)\t(\w+)\t(\w+)\t(.+)', '<tr><td>$1</td><td>$2</td><td id=\""$3\"">$3</td><td>$4</td></tr>', 'm')" >>_temp\master.html
REM echo ^</table^>>>_temp\master.html


(echo ^</table^>
echo ^</body^>
echo ^</html^>) >>_temp\master.html



_bin\xidel -s _temp\master.html -e "replace( $raw, '(?: id=\""no_info\""| id=\""good\"")', '')" >_temp\temp.1
del _temp\master.html & ren _temp\temp.1 master.html