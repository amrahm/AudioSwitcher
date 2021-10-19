#Include, %A_ScriptDir%\libraries\VA.ahk
#Include, %A_ScriptDir%\libraries\read-ini.ahk

#Persistent

; Read and groom settings
ReadIni("settings.ini")
global headphones := GeneralHeadphones
global speakers := GeneralSpeakers

hkComboSwitchDevice := KeyboardShortcutsCombinationsSwitchDevice
arrayS := Object(), arrayR := Object()
arrayS.Insert("\s*|,"), arrayR.Insert("")
arrayS.Insert("L(Ctrl|Shift|Alt|Win)"), arrayR.Insert("<$1")
arrayS.Insert("R(Ctrl|Shift|Alt|Win)"), arrayR.Insert(">$1")
arrayS.Insert("Ctrl"), arrayR.Insert("^")
arrayS.Insert("Shift"), arrayR.Insert("+")
arrayS.Insert("Alt"), arrayR.Insert("!")
arrayS.Insert("Win"), arrayR.Insert("#")

for index in arrayS {
    hkComboSwitchDevice := RegExReplace(hkComboSwitchDevice, arrayS[index], arrayR[index])
}
setUpHotkeyWithCombo(hkComboSwitchDevice, "SwapAudioDevice", "[KeyboardShortcutsCombinations] SwitchDevice")

; Set the icon
SwapAudioDevice(False)

; Setup the tray
DblClickSpeed := DllCall("GetDoubleClickTime") , firstClick := 0
Menu, Tray, NoStandard
Menu, Tray, Add, Swap Device, ClickHandler
Menu, Tray, Default, Swap Device
Menu, Tray, Add, Open Windows Sound Settings, OpenWindowsSoundSettings
Menu, Tray, Add, Reload Settings, Reload
Menu, Tray, Add, Exit, Exit
Menu, Tray, Click, 1

return

SwapAudioDevice(actually_swap:=True) {
    ; Get device IDs.
    A := VA_GetDevice(headphones), VA_IMMDevice_GetId(A, A_id)
    B := VA_GetDevice(speakers), VA_IMMDevice_GetId(B, B_id)
    if A && B {
        ; Get ID of default playback device.
        default := VA_GetDevice("playback")
        VA_IMMDevice_GetId(default, default_id)
        ObjRelease(default)

        id_to_use := actually_swap ? A_id : B_id
        if StrGet(&default_id,,"UTF-16") == StrGet(&id_to_use,,"UTF-16"){ ;idk why direct comparison didn't work
            Device_Name := VA_GetDeviceName(B)
            Menu, Tray, Icon, %A_WorkingDir%\speaker.ico,,1
        } else {
            Device_Name := VA_GetDeviceName(A)
            Menu, Tray, Icon, %A_WorkingDir%\headset.ico,,1
        }
        Menu, Tray, Tip, %Device_Name%

        if actually_swap {
            ; If device A is default, set device B; otherwise set device A.
            VA_SetDefaultEndpoint(default_id == A_id ? B : A, 0)
            VA_SetDefaultEndpoint(default_id == A_id ? B : A, 2) ; also set default communication device
        }
    }
    ObjRelease(B)
    ObjRelease(A)
    if !(A && B)
        throw Exception("Unknown audio device", -1, A ? speakers : headphones)
}

Reload() {
    Reload
}

Exit() {
    ExitApp
}

OpenWindowsSoundSettings() {
    run mmsys.cpl
}

ClickHandler:
    If ((A_TickCount-firstClick) < DblClickSpeed) { ; double click
        firstClick = 0
        OpenWindowsSoundSettings()

    }
    Else { ; Single click
        firstClick := A_TickCount
        KeyWait, LButton
        KeyWait, LButton, % "D T" . DblClickSpeed/1000
        If (ErrorLevel && firstClick)
            SwapAudioDevice()
    }
Return

setUpHotkey(hk, handler, settingPaths) {
    Hotkey, %hk%, %handler%, UseErrorLevel
    if (ErrorLevel <> 0) {
        MsgBox, 16, Error, One or more keyboard shortcut settings have been defined incorrectly in the settings file: `n%settingPaths%. `n`nPlease read the README for instructions.
            Exit
    }
}
setUpHotkeyWithCombo(combo, handler, settingPaths) {
    combo <> "" ? setUpHotkey(combo, handler, settingPaths) : ""
}
