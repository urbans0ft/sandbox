@echo off

set url_base=https://gist.githubusercontent.com/urbans0ft/b95ebd49dc7d2fc66b5de2df298b8351/raw/660b4cd1385e7352b9d65e42da3264bf80821cf7
for /f "tokens=1 delims=-" %%i in ("%~0") do (set prefix=%%i)
set setup_file=%prefix%-setup.bat
set sandbox_setup_url=%url_base%/%setup_file%

:: constants
set sandbox_install_dir="..\%~0"
set sandbox_config_file=sandbox-config.wsb
set sandbox_logon_file=LogonCommand.bat
set sandbox_setup_file=Setup-DevEnv.bat

set sandbox_config_path=%sandbox_install_dir%\%sandbox_config_file%
set sandbox_logon_path=%sandbox_install_dir%\%sandbox_logon_file%

mkdir %sandbox_install_dir% >nul 2>&1

:: write logon script which gets executed after starting the sandbox
echo(@echo off>%sandbox_logon_path%
echo(curl "%sandbox_setup_url%" -o"%%TEMP%%\%sandbox_setup_file%" -L>>%sandbox_logon_path%
echo(mklink "%%USERPROFILE%%\Desktop\%sandbox_setup_file%" "%%TEMP%%\%sandbox_setup_file%">>%sandbox_logon_path%

:: write sandbox configuration file
echo(^<Configuration^>>%sandbox_config_path%
echo(    ^<vGPU^>Enable^</vGPU^>>>%sandbox_config_path%
echo(    ^<Networking^>Enable^</Networking^>>>%sandbox_config_path%
echo(    ^<MappedFolders^>>>%sandbox_config_path%
echo(        ^<MappedFolder^>>>%sandbox_config_path%
echo(            ^<HostFolder^>C:\Sandbox^</HostFolder^>>>%sandbox_config_path%
echo(            ^<SandboxFolder^>C:\Sandbox^</SandboxFolder^>>>%sandbox_config_path%
echo(            ^<ReadOnly^>true^</ReadOnly^>>>%sandbox_config_path%
echo(        ^</MappedFolder^>>>%sandbox_config_path%
echo(    ^</MappedFolders^>>>%sandbox_config_path%
echo(    ^<LogonCommand^>>>%sandbox_config_path%
echo(        ^<Command^>C:\Sandbox\LogonCommand.bat^</Command^>>>%sandbox_config_path%
echo(    ^</LogonCommand^>>>%sandbox_config_path%
echo(^</Configuration^>>>%sandbox_config_path%
echo(

:: start the sandbox with its configuration file
start "" "%sandbox_config_path%"