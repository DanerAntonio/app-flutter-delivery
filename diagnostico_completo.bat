@echo off
title 🔍 Diagnóstico Completo del Proyecto Flutter
echo ==================================================
echo     INICIANDO DIAGNOSTICO COMPLETO DEL PROYECTO
echo ==================================================
setlocal EnableDelayedExpansion

:: Crear carpeta de salida
set OUTPUT_DIR=diagnostico_flutter
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo [1/6] 🔧 Ejecutando flutter doctor...
flutter doctor -v > "%OUTPUT_DIR%\flutter_doctor.txt"

echo.
echo [2/6] 🗂️  Generando estructura completa del proyecto...
tree /F > "%OUTPUT_DIR%\estructura_completa.txt"

echo.
echo [3/6] 📂 Mostrando estructura específica de lib...
tree /F lib > "%OUTPUT_DIR%\estructura_lib.txt"

echo.
echo [4/6] 📦 Copiando dependencias del pubspec.yaml...
type pubspec.yaml > "%OUTPUT_DIR%\pubspec.txt"

echo.
echo [5/6] 🔍 Analizando código Dart con flutter analyze...
flutter analyze > "%OUTPUT_DIR%\analisis_codigo.txt"

echo.
echo [6/6] 🧠 Unificando todo el código .dart en un solo archivo...
if exist "%OUTPUT_DIR%\codigo_completo.txt" del "%OUTPUT_DIR%\codigo_completo.txt"
for /r lib %%f in (*.dart) do (
    echo.>> "%OUTPUT_DIR%\codigo_completo.txt"
    echo ========== %%f ========== >> "%OUTPUT_DIR%\codigo_completo.txt"
    type "%%f" >> "%OUTPUT_DIR%\codigo_completo.txt"
)

echo.
echo ==================================================
echo ✅ DIAGNOSTICO COMPLETO FINALIZADO
echo 📁 Carpeta creada: %OUTPUT_DIR%
echo ==================================================
pause
