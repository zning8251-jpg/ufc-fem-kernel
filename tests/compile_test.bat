@echo off
cd /d d:\TEST7\UFC\ufc_core\Tests

echo ========================================
echo Compiling mock modules...
echo ========================================
gfortran -std=f2003 -c mock_modules.f90 -J.
if %ERRORLEVEL% neq 0 (
    echo Failed to compile mock modules
    exit /b 1
)

echo.
echo ========================================
echo Compiling TEST_PH_Mat_Hill.f90...
echo ========================================
gfortran -std=f2003 -o test_hill.exe TEST_PH_Mat_Hill.f90 mock_modules.f90 -J.
if %ERRORLEVEL% neq 0 (
    echo Failed to compile TEST_PH_Mat_Hill.f90
    exit /b 1
)

echo.
echo ========================================
echo Running test...
echo ========================================
test_hill.exe

echo.
echo Test completed!
pause
