#Include, %A_ScriptDir%\libraries\VA.ahk
#Include, %A_ScriptDir%\libraries\read-ini.ahk

#Persistent

; Read and groom settings
ReadIni("settings.ini")
global headphones := GeneralHeadphones
global speakers := GeneralSpeakers

; Set the icon
SwapAudioDevice(headphones, speakers, False)

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
            SwapAudioDevice(headphones, speakers, True)
    }
Return

NotifyTrayClick(P*) { ;  v0.41 by SKAN on D39E/D39N @ tiny.cc/notifytrayclick
    Static Msg, Fun:="NotifyTrayClick", NM:=OnMessage(0x404,Func(Fun),-1), Chk,T:=-250,Clk:=1
    If ( (NM := Format(Fun . "_{:03X}", Msg := P[2])) && P.Count()<4 )
        Return ( T := Max(-5000, 0-(P[1] ? Abs(P[1]) : 250)) )
    Critical
    If ( ( Msg<0x201 || Msg>0x209 ) || ( IsFunc(NM) || Islabel(NM) )=0 )
        Return
    Chk := (Fun . "_" . (Msg<=0x203 ? "203" : Msg<=0x206 ? "206" : Msg<=0x209 ? "209" : ""))
    SetTimer, %NM%, % (Msg==0x203 || Msg==0x206 || Msg==0x209)
    ? (-1, Clk:=2) : ( Clk=2 ? ("Off", Clk:=1) : ( IsFunc(Chk) || IsLabel(Chk) ? T : -1) )
Return True
}

SwapAudioDevice(headphone, speaker, actually_swap) {
    ; Get device IDs.
    A := VA_GetDevice(headphone), VA_IMMDevice_GetId(A, A_id)
    B := VA_GetDevice(speaker), VA_IMMDevice_GetId(B, B_id)
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

+Pause:: ; Shift+Pause Hotkey
    SwapAudioDevice(headphones, speakers, True)
