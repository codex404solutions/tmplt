@echo off
setlocal
:: ---- OPTIONAL SETTINGS (edit here, no prompts) ----
:: SITE_DIR = folder to deploy, "." = repo root (example: public_html)
:: BUILD_GRAPH = 1 builds the graphify graph during setup, 0 skips it
set "SITE_DIR=."
set "BUILD_GRAPH=0"
for %%I in ("%cd%") do set "SITE_NAME=%%~nxI"
:: ----------------------------------------------------
set "PATH_GLOB=%SITE_DIR%/**"
if "%SITE_DIR%"=="." set "PATH_GLOB=**"
echo =====================================
echo CodeX404 project setup (PHP + MySQL + graphify)
echo =====================================



:: -------------------------------
:: Create virtual environment
:: -------------------------------
if not exist ".venv" (
    echo Creating virtual environment...
    python -m venv .venv
    echo [OK] .venv created
) else (
    echo [SKIP] .venv already exists
)

:: Activate virtual environment
call .venv\Scripts\activate
echo [OK] .venv activated

:: -------------------------------
:: Upgrade pip
:: -------------------------------
echo Upgrading pip...
python -m pip install --upgrade pip
if %errorlevel%==0 (
    echo [OK] pip upgraded
) else (
    echo [ERROR] pip upgrade failed
)

:: -------------------------------
:: Install dependencies
:: -------------------------------
if exist requirements.txt (
    echo Installing dependencies from requirements.txt...
    pip install -r requirements.txt
    if %errorlevel%==0 (
        echo [OK] requirements installed
    ) else (
        echo [ERROR] requirements installation failed
    )
) else (
    echo [SKIP] requirements.txt not found
)



:: -------------------------------
:: .gitignore (append missing lines, never overwrite)
:: -------------------------------
echo Updating .gitignore...
call :addline ".gitignore" ".env"
call :addline ".gitignore" ".env.*"
call :addline ".gitignore" "!.env.example"
call :addline ".gitignore" "graphify-out/"
call :addline ".gitignore" "node_modules/"
call :addline ".gitignore" ".venv/"
call :addline ".gitignore" "__pycache__/"
call :addline ".gitignore" "*.pyc"
call :addline ".gitignore" "*.log"
call :addline ".gitignore" "backup*.sql"
call :addline ".gitignore" "*.dump"
call :addline ".gitignore" ".idea/"
call :addline ".gitignore" ".vscode/"
call :addline ".gitignore" ".DS_Store"
echo [OK] .gitignore checked

:: -------------------------------
:: .graphifyignore (keeps noise out of the graph)
:: -------------------------------
echo Updating .graphifyignore...
call :addline ".graphifyignore" "graphify-out/"
call :addline ".graphifyignore" ".git/"
call :addline ".graphifyignore" ".github/"
call :addline ".graphifyignore" ".agents/"
call :addline ".graphifyignore" ".claude/"
call :addline ".graphifyignore" ".venv/"
call :addline ".graphifyignore" "node_modules/"
call :addline ".graphifyignore" "vendor/"
call :addline ".graphifyignore" "**/uploads/"
call :addline ".graphifyignore" "**/*.min.js"
call :addline ".graphifyignore" "**/*.min.css"
call :addline ".graphifyignore" "**/*.map"
call :addline ".graphifyignore" "*.log"
call :addline ".graphifyignore" "*.jpg"
call :addline ".graphifyignore" "*.jpeg"
call :addline ".graphifyignore" "*.png"
call :addline ".graphifyignore" "*.svg"
call :addline ".graphifyignore" "*.webp"
echo [OK] .graphifyignore checked
echo [NOTE] Add *.sql to .graphifyignore only if the agent must NOT see the schema.

:: -------------------------------
:: .env.example (placeholders only, safe to commit)
:: -------------------------------
if not exist ".env.example" (
    >".env.example" echo DB_HOST=localhost
    >>".env.example" echo DB_NAME=
    >>".env.example" echo DB_USER=
    >>".env.example" echo DB_PASS=
    >>".env.example" echo SMTP_HOST=
    >>".env.example" echo SMTP_PORT=587
    >>".env.example" echo SMTP_USER=
    >>".env.example" echo SMTP_PASS=
    echo [OK] .env.example created
) else (
    echo [SKIP] .env.example already exists
)
if not exist ".env" echo [WARN] No .env yet. Copy .env.example to .env and fill it in. Never commit .env.

:: -------------------------------
:: Python (only needed for graphify and optional requirements.txt)
:: -------------------------------
where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found. Install Python 3.10+ and run again.
    goto :done
)

if exist requirements.txt (
    if not exist ".venv" (
        python -m venv .venv
        echo [OK] .venv created
    ) else (
        echo [SKIP] .venv already exists
    )
    call .venv\Scripts\activate
    python -m pip install --upgrade pip
    pip install -r requirements.txt
    if errorlevel 1 (echo [ERROR] requirements install failed) else (echo [OK] requirements installed)
) else (
    echo [SKIP] requirements.txt not found, no venv needed for a PHP project
)

:: -------------------------------
:: graphify (installed globally so the Antigravity terminal can always find it)
:: PyPI package name is graphifyy, the command is graphify
:: -------------------------------
where graphify >nul 2>&1
if not errorlevel 1 (
    echo [SKIP] graphify already installed
    goto :graphbuild
)
where uv >nul 2>&1
if not errorlevel 1 (
    uv tool install graphifyy
) else (
    where pipx >nul 2>&1
    if not errorlevel 1 (
        pipx install graphifyy
    ) else (
        python -m pip install --user graphifyy
    )
)
where graphify >nul 2>&1
if errorlevel 1 (
    echo [WARN] graphify installed but not on PATH yet. Close and reopen the terminal, then run: graphify .
    goto :workflow
) else (
    echo [OK] graphify installed
)

:graphbuild
if exist "graphify-out\graph.json" (
    echo [SKIP] graph already built. Use: graphify update .
    goto :workflow
)
if "%BUILD_GRAPH%"=="1" (
    graphify .
) else (
    echo [SKIP] Graph not built. Later, run: graphify .
)

:: -------------------------------
:: CODEOWNERS
:: -------------------------------
:workflow
if not exist ".github\CODEOWNERS" (
    mkdir .github 2>nul
    >".github\CODEOWNERS" echo # Code owners for this repository
    >>".github\CODEOWNERS" echo * @CodeX404Solutions/core-reviewers
    echo [OK] CODEOWNERS created
) else (
    echo [SKIP] CODEOWNERS already exists
)

:: -------------------------------
:: deploy.yml (prod = main, dev = dev). Never overwrites an existing one.
:: -------------------------------
if exist ".github\workflows\deploy.yml" (
    echo [SKIP] deploy.yml already exists, not touching a live deploy file
    goto :readme
)
mkdir .github\workflows 2>nul
set "DF=.github\workflows\deploy.yml"
>"%DF%"  echo name: Auto Deploy to Hostinger (%SITE_NAME%)
>>"%DF%" echo(
>>"%DF%" echo on:
>>"%DF%" echo   push:
>>"%DF%" echo     branches:
>>"%DF%" echo       - main
>>"%DF%" echo       - dev
>>"%DF%" echo     paths:
>>"%DF%" echo       - '%PATH_GLOB%'
>>"%DF%" echo       - '.github/workflows/deploy.yml'
>>"%DF%" echo   workflow_dispatch:
>>"%DF%" echo(
>>"%DF%" echo concurrency:
>>"%DF%" echo   group: deploy-${{ github.ref }}
>>"%DF%" echo   cancel-in-progress: false
>>"%DF%" echo(
>>"%DF%" echo jobs:
call :job prod main PROD production
>>"%DF%" echo(
call :job dev dev DEV dev
echo [OK] deploy.yml created (prod + dev)
echo [NOTE] Add GitHub secrets: FTP_SERVER_PROD, FTP_USERNAME_PROD, FTP_PASSWORD_PROD, FTP_SERVER_DEV, FTP_USERNAME_DEV, FTP_PASSWORD_DEV

:readme
:: -------------------------------
:: README tree workflow (only if update_tree.py exists)
:: [skip ci] stops the auto-commit from triggering the FTP deploy again
:: -------------------------------
if not exist "update_tree.py" (
    echo [SKIP] update_tree.py not found, README workflow not created
    goto :done
)
if exist ".github\workflows\update-readme.yml" (
    echo [SKIP] update-readme.yml already exists
    goto :done
)
mkdir .github\workflows 2>nul
set "WF=.github\workflows\update-readme.yml"
>"%WF%"  echo name: Update README Folder Tree (%SITE_NAME%)
>>"%WF%" echo(
>>"%WF%" echo on:
>>"%WF%" echo   push:
>>"%WF%" echo     branches:
>>"%WF%" echo       - main
>>"%WF%" echo     paths-ignore:
>>"%WF%" echo       - README.md
>>"%WF%" echo   workflow_dispatch:
>>"%WF%" echo(
>>"%WF%" echo permissions:
>>"%WF%" echo   contents: write
>>"%WF%" echo(
>>"%WF%" echo jobs:
>>"%WF%" echo   update-readme:
>>"%WF%" echo     runs-on: ubuntu-latest
>>"%WF%" echo     steps:
>>"%WF%" echo       - uses: actions/checkout@v4
>>"%WF%" echo       - uses: actions/setup-python@v5
>>"%WF%" echo         with:
>>"%WF%" echo           python-version: '3.12'
>>"%WF%" echo       - name: Update README.md with folder structure
>>"%WF%" echo         run: python update_tree.py
>>"%WF%" echo       - name: Commit and push changes
>>"%WF%" echo         run: ^|
>>"%WF%" echo           git config user.name "github-actions[bot]"
>>"%WF%" echo           git config user.email "github-actions[bot]@users.noreply.github.com"
>>"%WF%" echo           git add README.md
>>"%WF%" echo           git diff --cached --quiet ^|^| git commit -m "chore: update folder tree [skip ci]"
>>"%WF%" echo           git push
echo [OK] update-readme.yml created

:done
echo =====================================
echo Setup complete!
echo Next: git checkout -b setup-branch   (never work on main)
echo =====================================
pause
endlocal
exit /b 0

:: -------------------------------
:: helper: add a line to a file only if it is missing
:: -------------------------------
:addline
findstr /x /l /c:"%~2" "%~1" >nul 2>&1
if errorlevel 1 >>"%~1" echo %~2
goto :eof

:: -------------------------------
:: helper: write one deploy job. args: name branch SECRETSUFFIX label
:: -------------------------------
:job
>>"%DF%" echo   deploy-%~1:
>>"%DF%" echo     if: github.ref == 'refs/heads/%~2'
>>"%DF%" echo     runs-on: ubuntu-latest
>>"%DF%" echo     steps:
>>"%DF%" echo       - name: Checkout
>>"%DF%" echo         uses: actions/checkout@v4
>>"%DF%" echo       - name: Deploy to %~4
>>"%DF%" echo         uses: SamKirkland/FTP-Deploy-Action@v4.3.5
>>"%DF%" echo         with:
>>"%DF%" echo           server: ${{ secrets.FTP_SERVER_%~3 }}
>>"%DF%" echo           username: ${{ secrets.FTP_USERNAME_%~3 }}
>>"%DF%" echo           password: ${{ secrets.FTP_PASSWORD_%~3 }}
>>"%DF%" echo           port: 21
>>"%DF%" echo           protocol: ftp
>>"%DF%" echo           local-dir: ./%SITE_DIR%/
>>"%DF%" echo           server-dir: /
>>"%DF%" echo           timeout: 60000
>>"%DF%" echo           dangerous-clean-slate: false
>>"%DF%" echo           exclude: ^|
>>"%DF%" echo             **/.git*
>>"%DF%" echo             **/.github/**
>>"%DF%" echo             **/*.md
>>"%DF%" echo             **/.env
>>"%DF%" echo             **/.env.*
>>"%DF%" echo             **/tests/**
>>"%DF%" echo             **/uploads/**
>>"%DF%" echo             **/storage/**
>>"%DF%" echo             **/database/**
>>"%DF%" echo             **/*.sql
>>"%DF%" echo             **/*.dump
>>"%DF%" echo             **/*.log
>>"%DF%" echo             **/*.bak
>>"%DF%" echo             **/graphify-out/**
>>"%DF%" echo             **/node_modules/**
>>"%DF%" echo             **/.venv/**
>>"%DF%" echo             **/.DS_Store
>>"%DF%" echo             **/Thumbs.db
>>"%DF%" echo       - name: Done
>>"%DF%" echo         run: echo "Deployed to %~4 at $(date)"
goto :eof
