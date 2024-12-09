@echo off

:: -----------------------------------------------------------------------------
:: preamble --------------------------------------------------------------------
:: -----------------------------------------------------------------------------

setlocal EnableDelayedExpansion

pushd "%0\.."

:: Needed for colored output
call :setESC

call :isElevated && (
    :: self-elevation
    powershell -Command "Start-Process %0 %* -Verb RunAs"
    goto :end
)

:: -----------------------------------------------------------------------------
:: main ------------------------------------------------------------------------
:: -----------------------------------------------------------------------------

:: Path to download software installer to
set download_path=%USERPROFILE%\Downloads

set targets=registry;7-Zip;notepad++;pwsh

for %%a in ("%targets:;=" "%") do (
    call :info ##### %%~a #####
    call :%%~a && (
        call :success '%%~a' installed!
    ) || (
        call :error '%%~a' failed!
        goto end
    )
)

set newpaths=C:\Run
for %%a in ("%newpaths:;=" "%") do (
    call :info ##### set-path: %%~a #####
    call :ivc call :set-path %%~a
)

:end
popd

exit /b 0

:: -----------------------------------------------------------------------------
:: subroutines -----------------------------------------------------------------
:: -----------------------------------------------------------------------------

:setESC
for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set ESC=%%b
  exit /b 0
)
exit /b 0

:: -----------------------------------------------------------------------------

:verbose
echo %ESC%[7m[VERB] %*%ESC%[0m
exit /b 0

:info
echo %ESC%[96m[INFO] %*%ESC%[0m
exit /b 0

:success
echo %ESC%[92m[SUCC] %*%ESC%[0m
exit /b 0

:warn
echo %ESC%[93m[WARN] %*%ESC%[0m
exit /b 0

:error
echo %ESC%[91m[ERRO] %*%ESC%[0m
exit /b 0

:: -----------------------------------------------------------------------------

:ivc
call :verbose %*
call %*
exit /b !ERRORLEVEL!

:: -----------------------------------------------------------------------------

:isElevated
net file >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    exit /b 0
)
exit /b 1

:: -----------------------------------------------------------------------------

:isWritable
set tmpfile=%~0\..\.deleteme
(> %tmpfile% echo) 2>NUL && del %tmpfile% || exit /b 0
exit /b 1

:: -----------------------------------------------------------------------------

:download
if not exist "%~2" (
	call :verbose Source      '%1'
	call :verbose Destination '%2'
	curl -L "%~1" --output "%~2"
	set curl_error=!ERRORLEVEL!
	if !curl_error! neq 0 (
		:: delete possible corrupt left-over
		del "%~2" /F /Q 2>&1 >nul
	)
	exit /b !curl_error!
) else (
	call :info '%~2' already downloaded.
	exit /b 0
)

:: -----------------------------------------------------------------------------

:set-path
if "%1" == "" (
    call :warn set-path without 'path' parameter.
    exit /b 1
) else (
    call :verbose Adding '%~1' to PATH envrionment.
)
set path | findstr /i "%~1" >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    set PATH=%~1;!PATH! >nul 2>&1
    setx /M PATH "!PATH!" >nul 2>&1
    call :success Path '%~1' is set.
) else (
    call :warn Path '%~1' already set.
)
exit /b

:: -----------------------------------------------------------------------------

:registry
REM stop explorer for the following changes to take effect
call :ivc taskkill /F /IM explorer.exe || set registry_failed=1
REM Open 'This PC'
call :ivc reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v LaunchTo /t REG_DWORD /d 1 /f || set registry_failed=1
REM Show file extensions
call :ivc reg add HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v HideFileExt /t REG_DWORD /d 0 /f || set registry_failed=1
REM Black background
call :ivc reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v WallPaper /t REG_SZ /d "" /f || set registry_failed=1
REM "Normal" right click
call :ivc reg add HKEY_CURRENT_USER\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32 /ve /d "" /f || set registry_failed=1
REM Disable the search bar
call :ivc reg add HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f || set registry_failed=1
REM Combine when taskbar is full
call :ivc reg add  HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v TaskbarGlomLevel /t REG_DWORD /d 1 /f || set registry_failed=1
REM (re-)start the explorer
call :ivc start "" /b explorer.exe || set registry_failed=1
if defined registry_failed (
    exit /b 1
)
exit /b 0

:: -----------------------------------------------------------------------------

:7-Zip
set "app_name=%0" && set "app_name=!app_name:~1!"
set install_path=C:\Apps\!app_name!
if not exist !install_path! (
	for /f "tokens=2 delims= " %%i in ('curl -H "Accept: application/vnd.github+json" "https://api.github.com/repos/ip7z/7zip/releases/latest" ^| findstr /r "browser_download_url.*x64\.exe"') do (
		set url=%%i
		set filename=%%~nxi
	)
	
	call :info Downloading %0
	call :download "!url!" "%download_path%\!filename!" || exit /b 1

	call :info Installing %0
	call :ivc "%download_path%\!filename!" /S /D="!install_path!" || exit /b 1
) else (
	call :info '!install_path!' already installed.
)
set PATH=!install_path!;!PATH!
exit /b 0

:: -----------------------------------------------------------------------------

:Notepad++
set "app_name=%0" && set "app_name=!app_name:~1!"
set install_path=C:\Apps\!app_name!
if not exist !install_path! (
    for /f "tokens=2 delims= " %%i in ('curl -H "Accept: application/vnd.github+json" "https://api.github.com/repos/notepad-plus-plus/notepad-plus-plus/releases/latest" ^| findstr /r "browser_download_url.*Installer\.x64\.exe[^^.]"') do (
        set url=%%i
        set filename=%%~nxi
    )
    call :info Downloading !app_name!
    call :download !url! "%download_path%\!filename!" || exit /b 1
    
    call :info Installing !app_name!
    call :ivc "%download_path%\!filename!" /S /D=!install_path! || exit /b 1
) else (
    call :info '!install_path!' already installed.
)
exit /b 0

:: -----------------------------------------------------------------------------

:pwsh
set "app_name=%0" && set "app_name=!app_name:~1!"
set install_path=C:\Apps\!app_name!
if not exist !install_path! (
    for /f "tokens=2 delims= " %%i in ('curl -H "Accept: application/vnd.github+json" "https://api.github.com/repos/PowerShell/powershell/releases/latest" ^| findstr /r "browser_download_url.*win-x64\.msi"') do (
        set url=%%i
        set filename=%%~nxi
    )
    call :info Downloading !app_name!
    call :download !url! "%download_path%\!filename!" || exit /b 1
    
    call :info Installing !app_name!
    call :ivc "%download_path%\!filename!" /passive INSTALLFOLDER="!install_path!"|| exit /b 1
) else (
    call :info '!install_path!' already installed.
)
exit /b 0

:: -----------------------------------------------------------------------------