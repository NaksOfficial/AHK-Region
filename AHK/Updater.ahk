#Requires AutoHotkey v2.0

; ============================================================
; UPDATER — проверяет обновления и обновляет AHK.exe
; ============================================================

global currentVersion := "2.0"
global githubRawUrl := "https://raw.githubusercontent.com/NaksOfficial/AHK-Region/main/AHK/"
global versionUrl := githubRawUrl . "Version.txt"
global exeUrl := githubRawUrl . "AHK.exe"

; Путь к основному EXE
mainExePath := A_ScriptDir "\AHK.exe"

; Проверка, запущен ли после обновления
if A_Args.Length > 0 && A_Args[1] = "/updated" {
    MsgBox("✅ Скрипт успешно обновлён до версии " currentVersion, "Обновление", 0x40)
}

CheckForUpdates() {
    global currentVersion, versionUrl, exeUrl, mainExePath
    
    try {
        tempFile := A_Temp "\version_check.txt"
        Download(versionUrl, tempFile)
        latestVersion := Trim(FileRead(tempFile))
        FileDelete(tempFile)
        
        if (latestVersion != "" && latestVersion != currentVersion) {
            result := MsgBox("📢 Доступна новая версия!`n`n" .
                "Текущая: " currentVersion "`nНовая: " latestVersion "`n`n" .
                "Обновить сейчас?", "Доступно обновление", 0x24)
            
            if (result = "Yes") {
                DownloadUpdate()
                return
            }
        }
    } catch as err {
        ; Нет интернета — просто запускаем основной EXE
    }
    
    ; Запускаем основной EXE
    if FileExist(mainExePath) {
        Run(mainExePath)
    } else {
        MsgBox("❌ Не найден основной файл: " mainExePath, "Ошибка", 0x10)
    }
    ExitApp()
}

DownloadUpdate() {
    global exeUrl, mainExePath
    
    newExePath := A_Temp "\AHK_new.exe"
    
    try {
        ; Скачиваем новую версию
        Download(exeUrl, newExePath)
        
        ; Создаём BAT-файл для замены
        batPath := A_Temp "\update_exe.bat"
        batContent := "@echo off`n"
        batContent .= "timeout /t 2 /nobreak >nul`n"
        batContent .= ":loop`n"
        batContent .= "tasklist | find /i `"AHK.exe`" >nul 2>&1`n"
        batContent .= "if %errorlevel% equ 0 (`n"
        batContent .= "    timeout /t 1 /nobreak >nul`n"
        batContent .= "    goto loop`n"
        batContent .= ")`n"
        batContent .= "copy /Y `"" newExePath "`" `"" mainExePath "`" >nul 2>&1`n"
        batContent .= "if %errorlevel% equ 0 (`n"
        batContent .= "    start `"`" `"" mainExePath "`" /updated`n"
        batContent .= ") else (`n"
        batContent .= "    echo Ошибка при копировании > `"" A_Temp "\update_error.log`"`n"
        batContent .= ")`n"
        batContent .= "del `"" newExePath "`" >nul 2>nul`n"
        batContent .= "del `"" batPath "`" >nul 2>nul`n"
        
        FileAppend(batContent, batPath, "UTF-8")
        Run(batPath, , "Hide")
        ExitApp()
        
    } catch as err {
        MsgBox("❌ Не удалось загрузить обновление: " err.Message, "Ошибка", 0x10)
        ; Запускаем старую версию
        if FileExist(mainExePath) {
            Run(mainExePath)
        }
        ExitApp()
    }
}

; Запускаем проверку
CheckForUpdates()