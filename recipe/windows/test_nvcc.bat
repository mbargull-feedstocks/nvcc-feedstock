@echo on

:: Verify the cuda stub library exists.
if not exist "%LIBRARY_LIB%\cuda.lib" (
    echo "%LIBRARY_LIB%\cuda.lib is not a file"
    exit 1
)

if not exist "%PREFIX%\etc\conda\activate.d\%PKG_NAME%_activate.bat" (
    echo "%PREFIX%\etc\conda\activate.d\%PKG_NAME%_activate.bat is not a file"
    exit 1
)

if not exist "%PREFIX%\etc\conda\deactivate.d\%PKG_NAME%_deactivate.bat" (
    echo "%PREFIX%\etc\conda\deactivate.d\%PKG_NAME%_deactivate.bat is not a file"
    exit 1
)

:: Try using the activation scripts.
if defined CUDA_HOME (
    echo "CUDA_HOME is set to '%CUDA_HOME%'"
) else (
    echo "CUDA_HOME is unset after activation"
    exit 1
)

call %PREFIX%\etc\conda\deactivate.d\%PKG_NAME%_deactivate.bat
if errorlevel 1 exit 1

if "%CUDA_HOME%"=="" (
    if "%TEST_CUDA_HOME_INITIAL%"=="" (
        echo "CUDA_HOME correctly unset after deactivation"
    )
) else (
    if not "%TEST_CUDA_HOME_INITIAL%"=="" (
        echo "CUDA_HOME correctly maintained as '%CUDA_HOME%' after deactivation"
    ) else (
        echo "CUDA_HOME is incorrectly set to '%CUDA_HOME%' after deactivation"
        exit 1
    )

)


:: Set some CFLAGS to make sure we're not causing side effects
set "CFLAGS_CONDA_NVCC_TEST_BACKUP=%CFLAGS%"
set "CFLAGS=%CFLAGS% -I\path\to\test\include"
set "CFLAGS_CONDA_NVCC_TEST=%CFLAGS%"

:: Manually trigger the activation script
call %PREFIX%\etc\conda\activate.d\%PKG_NAME%_activate.bat
if errorlevel 1 exit 1

:: Check activation worked as expected, then deactivate
if "%CUDA_HOME%"=="" (
    echo "CUDA_HOME is unset after activation"
    exit 1
) else (
    echo "CUDA_HOME is set to '%CUDA_HOME%'"
)
call %PREFIX%\etc\conda\deactivate.d\%PKG_NAME%_deactivate.bat
if errorlevel 1 exit 1

:: Make sure there's no side effects
if "%CFLAGS%"=="%CFLAGS_CONDA_NVCC_TEST%" (
    echo "CFLAGS correctly maintained as '%CFLAGS%'"
    set "CFLAGS_CONDA_NVCC_TEST="
    set "CFLAGS=%CFLAGS_CONDA_NVCC_TEST_BACKUP%"
    set "CFLAGS_CONDA_NVCC_TEST_BACKUP="
) else (
    echo "CFLAGS is incorrectly set to '%CFLAGS%', should be set to '%CFLAGS_CONDA_NVCC_TEST%'"
    exit 1
)
@REM :: If no previous cuda.lib was present, there shouldn't be any!
@REM if "%CUDALIB_CONDA_NVCC_BACKUP%" == "" (
@REM     if exist "%LIBRARY_LIB%\cuda.lib" (
@REM         echo "%LIBRARY_LIB%\cuda.lib" should not exist!
@REM         exit 1
@REM     )
@REM )

:: Reactivate
call %PREFIX%\etc\conda\activate.d\%PKG_NAME%_activate.bat
if errorlevel 1 exit 1

:: Try building something
nvcc test.cu
