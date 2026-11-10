@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\rsvars.bat"
cd /d C:\DelphiComponents\CVC-VCL\Demo\Teste
msbuild DBLookupEditEnterTeste.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /v:minimal /nologo
