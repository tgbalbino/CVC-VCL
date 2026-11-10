@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\rsvars.bat"
cd /d C:\DelphiComponents\CVC-VCL\Demo\Teste
msbuild RelLogoTeste.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /v:minimal /nologo
