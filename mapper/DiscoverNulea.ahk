#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
#Include Lib\AutoHotInterception.ahk

global AHI := AutoHotInterception()
global Devices := AHI.GetDeviceList()
global LastMouseId := 0
global ConfigPath := A_ScriptDir "\nulea-device.txt"
global MouseCount := 0

for id, device in Devices {
    if device.IsMouse {
        MouseCount += 1
        AHI.SubscribeMouseButtons(id, false, MouseEvent.Bind(id))
    }
}

if MouseCount = 0 {
    MsgBox("No Interception mouse devices were found.`n`nInstall the Interception driver and restart Windows first.", "Nulea discovery")
    ExitApp
}

MsgBox(
    "Use only the Nulea mouse and press one of its buttons.`n`n"
    "When the Nulea event appears in the tooltip, press F8 to select it.`n"
    "Press Esc to cancel.`n`n"
    "This discovery step does not block or remap any input.",
    "Identify the Nulea mouse"
)

MouseEvent(id, button, state) {
    global LastMouseId, Devices
    if state != 1
        return

    LastMouseId := id
    device := Devices[id]
    ToolTip(
        "Last mouse: ID " id
        "`nButton code: " button
        "`nVID: " Format("{:04X}", device.VID)
        "  PID: " Format("{:04X}", device.PID)
        "`nPress F8 if this was the Nulea"
    )
}

F8:: {
    global LastMouseId, Devices, ConfigPath
    if LastMouseId = 0 {
        MsgBox("Press a button on the Nulea mouse first.", "Nothing detected")
        return
    }

    device := Devices[LastMouseId]
    try FileDelete(ConfigPath)
    FileAppend(device.Handle, ConfigPath, "UTF-8")
    ToolTip()
    MsgBox(
        "Saved the selected device as the Nulea mouse.`n`n"
        "Interception ID: " LastMouseId "`n"
        "The mapper is ready to test.",
        "Nulea selected"
    )
    ExitApp
}

Esc::ExitApp
