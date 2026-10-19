#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
#Include Lib\AutoHotInterception.ahk

global ConfigPath := A_ScriptDir "\nulea-device.txt"

if !FileExist(ConfigPath) {
    MsgBox(
        "The Nulea device has not been selected yet.`n`n"
        "Run DiscoverNulea.ahk first.",
        "Nulea mapper"
    )
    ExitApp
}

global AHI := AutoHotInterception()
deviceHandle := Trim(FileRead(ConfigPath, "UTF-8"))
global NuleaId := AHI.GetMouseIdFromHandle(deviceHandle)

if !NuleaId {
    MsgBox(
        "The saved Nulea mouse is not currently available.`n`n"
        "Reconnect it, then try again. If that fails, rerun DiscoverNulea.ahk.",
        "Nulea mapper"
    )
    ExitApp
}

; Interception button codes:
; 1 = physical right button, 3 = first side/back button.
AHI.SubscribeMouseButton(NuleaId, 1, true, IgnorePhysicalRight)
AHI.SubscribeMouseButton(NuleaId, 3, true, SideButtonToRightClick)

A_TrayMenu.Add("Nulea mapping status", ShowStatus)
A_TrayMenu.Add("Exit and restore normal buttons", (*) => ExitApp())
TrayTip("Nulea-only mapping active", "Right button disabled; Back side button is now right-click.")

IgnorePhysicalRight(state) {
    ; Intentionally swallow both button-down and button-up.
}

SideButtonToRightClick(state) {
    if state
        Send("{RButton Down}")
    else
        Send("{RButton Up}")
}

ShowStatus(*) {
    global NuleaId
    MsgBox(
        "Nulea-only mapping is active.`n`n"
        "Physical right button: Disabled`n"
        "Back side button: Right-click`n"
        "Interception device ID: " NuleaId "`n`n"
        "Emergency exit: Ctrl+Alt+Shift+F12",
        "Nulea mapper"
    )
}

^!+F12::ExitApp
