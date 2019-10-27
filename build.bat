@echo off >nul
chcp 1251 >nul
SetLocal EnableExtensions

set c = 0

:: 'Blue','Green','Cyan','Red','Magenta','Yellow','White'

for /f "tokens=1*delims=-" %%a in ('dir "Плагины" /B') do ( 
	@del "Плагины\%%a\*.smx" > nul 2>&1
	@del "Плагины\%%a\*.log" > nul 2>&1
	
	for /f "tokens=1*delims=-" %%b in ('dir "Плагины\%%a\*.sp" /B') do ( 
		if %%c == 1 ( call :EchoColor " %%a [%%b]" Yellow ) else ( echo  %%a [%%b]   )
		
		"_Компилятор SM 1.9\spcomp.exe" "%%b" -D"Плагины\%%a" -i. -i"include" -i"..\..\Custom Includes" >"Плагины\%%a\%%b.log" 
		
		
		findstr /c:"Code" "Плагины\%%a\%%b.log" > nul		
		if ERRORLEVEL 1 ( 
			if %%c == 1 ( call :EchoColor " Ошибка.. Загляните в файл: Плагины\%%a\%%b.log" Red  ) else ( echo Ошибка.. Загляните в файл: Плагины\%%a\%%b.log )
		) else (
			if %%c == 1 ( call :EchoColor " Успешно.." Green  ) else ( echo  Успешно.. )
			
			REM FOR /F "tokens=1,2 skip=5" %%i IN ('DIR "Плагины\%%a\%%b" /tc ') DO ( echo %%i %%j && goto :next ) 
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