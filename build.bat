@echo off >nul
chcp 1251 >nul
SetLocal EnableExtensions

set c = 0

:: 'Blue','Green','Cyan','Red','Magenta','Yellow','White'

for /f "tokens=1*delims=-" %%a in ('dir "�������" /B') do ( 
	@del "�������\%%a\*.smx" > nul 2>&1
	@del "�������\%%a\*.log" > nul 2>&1
	
	for /f "tokens=1*delims=-" %%b in ('dir "�������\%%a\*.sp" /B') do ( 
		if %%c == 1 ( call :EchoColor " %%a [%%b]" Yellow ) else ( echo  %%a [%%b]   )
		
		"_���������� SM 1.9\spcomp.exe" "%%b" -D"�������\%%a" -i. -i"include" -i"..\..\Custom Includes" >"�������\%%a\%%b.log" 
		
		
		findstr /c:"Code" "�������\%%a\%%b.log" > nul		
		if ERRORLEVEL 1 ( 
			if %%c == 1 ( call :EchoColor " ������.. ��������� � ����: �������\%%a\%%b.log" Red  ) else ( echo ������.. ��������� � ����: �������\%%a\%%b.log )
		) else (
			if %%c == 1 ( call :EchoColor " �������.." Green  ) else ( echo  �������.. )
			
			REM FOR /F "tokens=1,2 skip=5" %%i IN ('DIR "�������\%%a\%%b" /tc ') DO ( echo %%i %%j && goto :next ) 
			REM call :BuildProject 
		)
		 
		 
		:next 
		@del temp.txt  > nul 2>&1 
	)
)
pause



:EchoColor [text] [color]
powershell "'%~1'.GetEnumerator()|%%{Write-Host $_ -NoNewline -ForegroundColor %~2}"
exit /B