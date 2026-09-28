@echo off
echo ========================================================
echo Compilando DecisionRoom G3 a ejecutable standalone
echo ========================================================

pip install -r requirements.txt

python -m eel main.py web --onefile --noconsole --name "DecisionRoom_G3" --icon=NONE

echo ========================================================
echo Compilacion finalizada. Ejecutable generado en: dist/DecisionRoom_G3.exe
echo ========================================================
pause
