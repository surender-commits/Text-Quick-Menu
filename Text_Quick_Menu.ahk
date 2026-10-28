#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ============================================================
; TEXT QUICK MENU  (AutoHotkey v2)
;
; ` key (SC029)   -> show / hide the selection menu at the cursor
; Hold left mouse -> show the hold menu (Paste / Paste & Go)
;                    (only in apps allowed by the allow/block lists)
; Allowed apps   -> double/triple click or click-and-drag shows the selection menu
;                  (see AutoShowAllowed / AutoShowBlocked below)
; Esc             -> close the menu (only while it is visible)
; Ctrl+Alt+T      -> enable / disable the whole utility
; ============================================================

; ---- Speed: remove AutoHotkey's built-in delays ----
SetWinDelay -1
SetControlDelay -1
SetKeyDelay -1, -1
ListLines false

; MouseGetPos defaults to window-relative coordinates; we need screen.
CoordMode "Mouse", "Screen"

; ============================================================
; CONFIGURATION
; ============================================================

; ---- Behaviour ----
HoldTime := 250                 ; ms the left button must be held
HoldMoveThreshold := 5          ; px of movement that cancels the hold
HideHoldMenuOnRelease := false  ; true = hold menu vanishes when you release

; ---- Auto-show when you select text (double/triple click, click-drag) ----
AutoShowEnabled := true

; Apps are matched by process name (case-insensitive).
; To find an app's name: Task Manager -> Details tab -> "Name" column.
; Rules, in order:
;   1. App in the BLOCK list   -> never show (block always wins)
;   2. App in the ALLOW list   -> show
;   3. Any other app           -> follows AutoShowUnlistedApps
; These lists apply to the selection auto-show AND the click-and-hold menu
; (the hold menu can be exempted with HoldMenuUseAppLists below).
; Add or remove lines freely (keep a comma after every line except the last).
AutoShowAllowed := [
    "chrome.exe",         ; Google Chrome
    "msedge.exe",         ; Microsoft Edge
    "zen.exe",            ; Zen Browser
    "notepad.exe",        ; Notepad
    "MDHero.exe",         ; MD Hero      (verify the exact name in Task Manager)
    "Stacher7.exe"        ; Stacher7     (verify the exact name in Task Manager)
]

AutoShowBlocked := [
    "Photoshop.exe",              ; Adobe Photoshop
    "Adobe Premiere Pro.exe",     ; Adobe Premiere Pro
    "AfterFX.exe",                ; Adobe After Effects
    "Illustrator.exe",            ; Adobe Illustrator
    "Adobe Media Encoder.exe",    ; Adobe Media Encoder
    "Lightroom.exe",              ; Adobe Lightroom Classic
    "Resolve.exe",                ; DaVinci Resolve
    "blender.exe",                ; Blender
    "Figma.exe",                  ; Figma desktop
    "Krita.exe",                  ; Krita
    "CapCut.exe",                 ; CapCut
    "mspaint.exe"                 ; Paint
]

AutoShowUnlistedApps := false   ; true = work everywhere except the block list

HoldMenuUseAppLists := true     ; true  = hold menu follows the allow/block lists above
                                ; false = hold menu works in every app (old behaviour)

AutoShowOnMultiClick := true    ; double-click / triple-click
AutoShowOnDrag := true          ; click and drag
DragMinDistance := 12           ; px the mouse must travel to count as a drag
RequireIBeamCursor := true      ; only when the press started on text (I-beam cursor).
                                ; Ignores tab / scrollbar / image / link drags.
                                ; Set to false if the menu never appears in your browser.

; ---- Timing (ms). Lower = faster, raise only if an app misbehaves ----
CopyTimeout := 0.4              ; seconds to wait for Ctrl+C (returns as soon as ready)
PasteGoDelay := 100              ; gap between Ctrl+V and Enter in Paste & Go (0 = none)
ClipRestoreDelay := 150         ; wait before restoring your clipboard after a case change

; ---- Size (in 96-DPI units, scaled automatically) ----
MenuButtonSize := 36
MenuPadding := 5
MenuGap := 2
DividerWidth := 9
MainMenuOffsetY := 10
HoldMenuOffsetY := 10

; ---- Colours (RGB hex) ----
BarColor := "1F1F1F"
BorderColor := "474747"
DividerColor := "444444"
TextColor := "EDEDED"
BtnHoverColor := "383838"
BtnPressColor := "505050"

; ---- Fonts ----
IconFont := "Segoe MDL2 Assets"   ; crisp icon glyphs (built into Windows 10/11)
TextFont := "Segoe UI Semibold"

GoogleSearchURL := "https://www.google.com/search?q="

Enabled := true

; ============================================================
; BUTTONS
;   type:    "button" or "divider"
;   enabled: false = hidden completely
;   icon:    text or glyph shown on the button
;   font:    "icon" = use IconFont, anything else = TextFont
;   action:  name handled in RunAction()
;
; Icon glyphs: E8C8 copy, E77F paste, E72A forward, E721 search
; ============================================================

SelectionButtons := [
    { type: "button", icon: Chr(0xE8C8), font: "icon", action: "Copy", enabled: true },
    { type: "button", icon: Chr(0xE77F), font: "icon", action: "Paste", enabled: true },
    { type: "button", icon: Chr(0xE72A), font: "icon", action: "PasteGo", enabled: true },
    { type: "button", icon: Chr(0xE721), font: "icon", action: "Search", enabled: true },
    { type: "divider", enabled: true },
    { type: "button", icon: "Aa", action: "TitleCase", enabled: true },
    { type: "button", icon: "AA", action: "UpperCase", enabled: true },
    { type: "button", icon: "aa", action: "LowerCase", enabled: true }
]

HoldButtons := [
    { type: "button", icon: Chr(0xE77F), font: "icon", action: "Paste", enabled: true },
    { type: "button", icon: Chr(0xE72A), font: "icon", action: "PasteGo", enabled: true }
]

; ============================================================
; GLOBAL STATE
; ============================================================

Menus := Map()          ; prebuilt menus: "Selection" / "Hold"
ActiveMenu := ""
MenuVisible := false
MenuType := ""

OriginalHwnd := 0
PendingClip := ""

HoldActive := false
HoldTriggered := false
HoldStartX := 0
HoldStartY := 0
HoldStartTime := 0

; Click counting / drag detection (for auto-show)
ClickCount := 0
LastClickTime := 0
LastClickX := 0
LastClickY := 0
DragStartX := 0
DragStartY := 0
DownCursor := ""
SuppressAutoShow := false

; ============================================================
; HOTKEYS
; ============================================================

; SC029 is the key left of "1" on a US keyboard (` / ~).
; Use "+SC029::" to fire only on Shift+` (~).
; (Manual trigger: works in every app, the allow/block lists don't apply.)
#HotIf Enabled
SC029:: {
    if MenuVisible
        HideMenus()
    else
        ShowSelectionMenu()
}
#HotIf

; Esc is only intercepted while the menu is open.
#HotIf MenuVisible
Esc:: HideMenus()
#HotIf

^!t:: ToggleEnabled()

; Left button down: close menu on outside click, start hold detection.
~LButton:: {
    global HoldActive, HoldTriggered, HoldStartX, HoldStartY, HoldStartTime
    global SuppressAutoShow, ClickCount, LastClickTime, LastClickX, LastClickY
    global DragStartX, DragStartY, DownCursor

    if !Enabled
        return

    MouseGetPos &mx, &my

    if MenuVisible {
        if IsPointInsideCurrentMenu(mx, my) {
            ; Clicking a menu button must not re-open the menu on release.
            SuppressAutoShow := true
            return
        }
        HideMenus()
    }

    ; ---- Click counting (double / triple click) and drag origin ----
    SuppressAutoShow := false

    if A_TickCount - LastClickTime <= DllCall("GetDoubleClickTime", "UInt")
        && Abs(mx - LastClickX) <= 4 && Abs(my - LastClickY) <= 4
        ClickCount++
    else
        ClickCount := 1

    LastClickTime := A_TickCount
    LastClickX := mx
    LastClickY := my
    DragStartX := mx
    DragStartY := my
    DownCursor := A_Cursor

    HoldActive := true
    HoldTriggered := false
    HoldStartX := mx
    HoldStartY := my
    HoldStartTime := A_TickCount

    SetTimer CheckMouseHold, 20
}

~LButton Up:: {
    global HoldActive, HoldTriggered

    wasHold := HoldTriggered

    HoldActive := false
    SetTimer CheckMouseHold, 0

    if HoldTriggered {
        HoldTriggered := false
        if HideHoldMenuOnRelease && MenuType = "Hold"
            HideMenus()
    }

    ; Double/triple click or drag in the browser -> show the selection menu.
    if !wasHold
        MaybeAutoShow()
}

CheckMouseHold() {
    global HoldActive, HoldTriggered

    if !HoldActive {
        SetTimer CheckMouseHold, 0
        return
    }

    MouseGetPos &mx, &my

    if Abs(mx - HoldStartX) > HoldMoveThreshold
        || Abs(my - HoldStartY) > HoldMoveThreshold {
        HoldActive := false
        SetTimer CheckMouseHold, 0
        return
    }

    if A_TickCount - HoldStartTime >= HoldTime {
        HoldActive := false
        SetTimer CheckMouseHold, 0

        ; Allow/block lists. Checked here (after the hold time) rather than on
        ; button-down, so the window you just clicked is already the active one.
        if HoldMenuUseAppLists && !IsAllowedApp()
            return

        HoldTriggered := true
        ShowHoldMenu(HoldStartX, HoldStartY)
    }
}

; ============================================================
; APP ALLOW / BLOCK LISTS
; Used by the selection auto-show and the click-and-hold menu.
; ============================================================

; Turns a list of names into a case-insensitive lookup table.
ToSet(list) {
    set := Map()
    set.CaseSense := false
    for name in list
        set[name] := true
    return set
}

; Block list wins, then allow list, then AutoShowUnlistedApps.
IsAllowedApp() {
    try {
        exe := WinGetProcessName("A")
    } catch {
        return false
    }

    if AutoShowBlockedSet.Has(exe)
        return false

    if AutoShowAllowedSet.Has(exe)
        return true

    return AutoShowUnlistedApps
}

; ============================================================
; AUTO-SHOW ON TEXT SELECTION
; Called on every left-button release.
; ============================================================

MaybeAutoShow() {
    if !Enabled || !AutoShowEnabled || SuppressAutoShow
        return

    if !IsAllowedApp()
        return

    ; Text selections start on an I-beam cursor. This ignores dragging
    ; tabs, scrollbars, images, links and window edges.
    if RequireIBeamCursor && DownCursor != "IBeam"
        return

    MouseGetPos &x, &y

    moved := Abs(x - DragStartX) >= S(DragMinDistance)
        || Abs(y - DragStartY) >= S(DragMinDistance)

    isMultiClick := AutoShowOnMultiClick && ClickCount >= 2
    isDrag := AutoShowOnDrag && moved

    if isMultiClick || isDrag
        ShowSelectionMenu()
}

; ============================================================
; MENU CREATION  (built once at startup, then just shown/hidden)
; ============================================================

; DPI helper: converts 96-DPI units to real pixels.
S(n) => Round(n * A_ScreenDPI / 96)

RgbToBgr(hex) {
    c := Integer("0x" hex)
    return ((c & 0xFF) << 16) | (c & 0xFF00) | (c >> 16)
}

BuildMenu(buttons) {
    pad := S(MenuPadding)
    size := S(MenuButtonSize)
    gap := S(MenuGap)
    divW := S(DividerWidth)

    ; ---- Measure ----
    contentW := 0
    count := 0

    for item in buttons {
        if !item.enabled
            continue
        count++
        contentW += (item.type = "divider") ? divW : size
    }

    if count = 0
        return ""

    contentW += gap * (count - 1)
    w := contentW + pad * 2
    h := size + pad * 2

    ; ---- Window ----
    ; -DPIScale: we scale ourselves, so all values are real screen pixels
    ; (matching MouseGetPos and the monitor work area).
    ; +E0x08000000 = WS_EX_NOACTIVATE, the menu never steals focus.
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000")
    g.MarginX := 0
    g.MarginY := 0

    ; Windows 11: native rounded corners + coloured border.
    nativeRound := false
    try nativeRound := (DllCall("dwmapi\DwmSetWindowAttribute"
        , "Ptr", g.Hwnd, "Int", 33, "Int*", 2, "Int", 4, "Int") = 0)

    if nativeRound {
        DllCall("dwmapi\DwmSetWindowAttribute"
            , "Ptr", g.Hwnd, "Int", 34, "Int*", RgbToBgr(BorderColor), "Int", 4)
        g.BackColor := BarColor
    } else {
        ; Windows 10 fallback: 1px border drawn by an inset panel + rounded region.
        g.BackColor := BorderColor
        g.Add("Text", Format("x1 y1 w{} h{} Background{}", w - 2, h - 2, BarColor))
        d := S(12)
        rgn := DllCall("gdi32\CreateRoundRectRgn"
            , "Int", 0, "Int", 0, "Int", w + 1, "Int", h + 1, "Int", d, "Int", d, "Ptr")
        DllCall("user32\SetWindowRgn", "Ptr", g.Hwnd, "Ptr", rgn, "Int", true)
    }

    ; ---- Items ----
    byHwnd := Map()
    x := pad

    for item in buttons {
        if !item.enabled
            continue

        if item.type = "divider" {
            lineW := Max(1, S(1))
            g.Add("Text", Format("x{} y{} w{} h{} Background{}"
                , x + (divW - lineW) // 2, pad + S(9), lineW, size - S(18), DividerColor))
            x += divW + gap
            continue
        }

        isIcon := item.HasProp("font") && item.font = "icon"

        ; Flat Text control used as a button:
        ; +0x200 = centre vertically, +0x100 = send click notifications.
        btn := g.Add("Text"
            , Format("x{} y{} w{} h{} Center +0x200 +0x100 Background{} c{}"
                , x, pad, size, size, BarColor, TextColor)
            , item.icon)
        btn.SetFont((isIcon ? "s12" : "s11") " c" TextColor, isIcon ? IconFont : TextFont)

        handler := ButtonClicked.Bind(item.action)
        btn.OnEvent("Click", handler)
        btn.OnEvent("DoubleClick", handler)

        byHwnd[btn.Hwnd] := { ctrl: btn, action: item.action }
        x += size + gap
    }

    return { gui: g, w: w, h: h, byHwnd: byHwnd, hot: 0, state: 0 }
}

; Hover / pressed highlight, polled only while a menu is visible.
UpdateHover() {
    m := ActiveMenu

    if !IsObject(m) {
        SetTimer UpdateHover, 0
        return
    }

    MouseGetPos , , , &hCtrl, 2

    hot := (hCtrl && m.byHwnd.Has(hCtrl)) ? hCtrl : 0
    state := !hot ? 0 : (GetKeyState("LButton", "P") ? 2 : 1)

    if hot = m.hot && state = m.state
        return

    if m.hot && m.hot != hot
        PaintButton(m.byHwnd[m.hot], 0)

    if hot
        PaintButton(m.byHwnd[hot], state)

    m.hot := hot
    m.state := state
}

PaintButton(btn, state) {
    if state = 2
        color := BtnPressColor
    else if state = 1
        color := BtnHoverColor
    else
        color := BarColor

    btn.ctrl.Opt("Background" color)
    btn.ctrl.Redraw()
}

; ============================================================
; SHOW / HIDE
; ============================================================

ShowSelectionMenu() {
    global OriginalHwnd

    OriginalHwnd := WinExist("A")
    MouseGetPos &x, &y
    ShowMenu("Selection", x, y)
}

ShowHoldMenu(x, y) {
    global OriginalHwnd

    OriginalHwnd := WinExist("A")
    ShowMenu("Hold", x, y)
}

ShowMenu(kind, cursorX, cursorY) {
    global ActiveMenu, MenuVisible, MenuType

    HideMenus()

    if !Menus.Has(kind) || !IsObject(Menus[kind])
        return

    m := Menus[kind]
    pos := CalculateMenuPosition(cursorX, cursorY, m.w, m.h, kind)

    m.gui.Show(Format("x{} y{} w{} h{} NA", pos.x, pos.y, m.w, m.h))

    ActiveMenu := m
    MenuVisible := true
    MenuType := kind

    SetTimer UpdateHover, 30
}

HideMenus() {
    global ActiveMenu, MenuVisible, MenuType

    SetTimer UpdateHover, 0

    if IsObject(ActiveMenu) {
        if ActiveMenu.hot {
            PaintButton(ActiveMenu.byHwnd[ActiveMenu.hot], 0)
            ActiveMenu.hot := 0
            ActiveMenu.state := 0
        }
        ActiveMenu.gui.Hide()
        ActiveMenu := ""
    }

    MenuVisible := false
    MenuType := ""
}

IsPointInsideCurrentMenu(x, y) {
    if !IsObject(ActiveMenu)
        return false

    try {
        WinGetPos &gx, &gy, &gw, &gh, ActiveMenu.gui.Hwnd
        return x >= gx && x <= gx + gw && y >= gy && y <= gy + gh
    } catch {
        return false
    }
}

; Above the cursor first, below if no room, always inside the monitor.
CalculateMenuPosition(cursorX, cursorY, menuWidth, menuHeight, kind) {
    monitorIndex := GetMonitorAtPoint(cursorX, cursorY)
    MonitorGetWorkArea(monitorIndex, &left, &top, &right, &bottom)

    offsetY := S((kind = "Selection") ? MainMenuOffsetY : HoldMenuOffsetY)

    x := cursorX - Floor(menuWidth / 2)
    y := cursorY - menuHeight - offsetY

    if y < top
        y := cursorY + offsetY

    if x < left
        x := left
    if x + menuWidth > right
        x := right - menuWidth

    if y < top
        y := top
    if y + menuHeight > bottom
        y := bottom - menuHeight

    return { x: x, y: y }
}

GetMonitorAtPoint(x, y) {
    loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &left, &top, &right, &bottom)
        if x >= left && x <= right && y >= top && y <= bottom
            return A_Index
    }
    return 1
}

; ============================================================
; ACTIONS
; The menu is hidden first (instant), then the action runs.
; The original window is still active because the menu never
; takes focus, so no window switching is needed.
; ============================================================

ButtonClicked(action, *) {
    HideMenus()
    RunAction(action)
}

RunAction(action) {
    switch action {
        case "Copy":      ActionCopy()
        case "Paste":     ActionPaste()
        case "PasteGo":   ActionPasteGo()
        case "Search":    ActionSearch()
        case "TitleCase": ChangeSelectedText("title")
        case "UpperCase": ChangeSelectedText("upper")
        case "LowerCase": ChangeSelectedText("lower")
    }
}

; Only switches windows if focus was actually lost.
EnsureOriginalActive() {
    if !OriginalHwnd || WinActive("ahk_id " OriginalHwnd)
        return

    if WinExist("ahk_id " OriginalHwnd) {
        WinActivate "ahk_id " OriginalHwnd
        WinWaitActive "ahk_id " OriginalHwnd, , 0.3
    }
}

ActionCopy() {
    EnsureOriginalActive()
    Send "^c"
}

ActionPaste() {
    EnsureOriginalActive()
    Send "^v"
}

ActionPasteGo() {
    EnsureOriginalActive()
    Send "^v"
    if PasteGoDelay > 0
        Sleep PasteGoDelay
    Send "{Enter}"
}

ActionSearch() {
    FlushClipboard()
    EnsureOriginalActive()

    selectedText := GetSelectedText()
    if selectedText = ""
        return

    Run GoogleSearchURL UrlEncode(selectedText)
}

; Copies the selection and returns it, restoring the clipboard right away.
GetSelectedText() {
    oldClipboard := ClipboardAll()
    A_Clipboard := ""

    Send "^c"

    if !ClipWait(CopyTimeout) {
        A_Clipboard := oldClipboard
        return ""
    }

    text := A_Clipboard
    A_Clipboard := oldClipboard
    return text
}

ChangeSelectedText(caseType) {
    FlushClipboard()
    EnsureOriginalActive()

    oldClipboard := ClipboardAll()
    A_Clipboard := ""

    Send "^c"

    if !ClipWait(CopyTimeout) {
        A_Clipboard := oldClipboard
        return
    }

    selectedText := A_Clipboard
    if selectedText = "" {
        A_Clipboard := oldClipboard
        return
    }

    switch caseType {
        case "upper": newText := StrUpper(selectedText)
        case "lower": newText := StrLower(selectedText)
        case "title": newText := StrTitle(selectedText)
        default:
            A_Clipboard := oldClipboard
            return
    }

    A_Clipboard := newText
    Send "^v"

    ; Restore the user's clipboard in the background instead of blocking here.
    RestoreClipboardLater(oldClipboard)
}

RestoreClipboardLater(clip) {
    global PendingClip

    PendingClip := clip
    SetTimer FlushClipboard, -ClipRestoreDelay
}

FlushClipboard() {
    global PendingClip

    if IsObject(PendingClip) {
        A_Clipboard := PendingClip
        PendingClip := ""
    }
}

; ============================================================
; URL ENCODING (UTF-8 bytes, so non-ASCII text and emoji work)
; ============================================================

UrlEncode(text) {
    byteCount := StrPut(text, "UTF-8") - 1    ; minus the null terminator
    buf := Buffer(byteCount + 1)
    StrPut(text, buf, "UTF-8")

    result := ""

    loop byteCount {
        byte := NumGet(buf, A_Index - 1, "UChar")

        if (byte >= 0x30 && byte <= 0x39)         ; 0-9
            || (byte >= 0x41 && byte <= 0x5A)     ; A-Z
            || (byte >= 0x61 && byte <= 0x7A)     ; a-z
            || byte = 0x2D || byte = 0x2E         ; - .
            || byte = 0x5F || byte = 0x7E         ; _ ~
            result .= Chr(byte)
        else if byte = 0x20
            result .= "+"
        else
            result .= "%" Format("{:02X}", byte)
    }

    return result
}

; ============================================================
; ENABLE / DISABLE  (hotkey and tray share one function)
; ============================================================

ToggleEnabled(*) {
    global Enabled

    Enabled := !Enabled

    if !Enabled
        HideMenus()

    if Enabled
        A_TrayMenu.Check("Enabled")
    else
        A_TrayMenu.Uncheck("Enabled")

    ; v2 signature is TrayTip(Text, Title, Options)
    TrayTip(Enabled ? "Enabled" : "Disabled", "Text Quick Menu", "Iconi Mute")
}

ShowTrayStatus(*) {
    TrayTip(Enabled ? "Currently enabled" : "Currently disabled"
        , "Text Quick Menu", "Iconi Mute")
}

ToggleAutoShow(*) {
    global AutoShowEnabled

    AutoShowEnabled := !AutoShowEnabled

    if AutoShowEnabled
        A_TrayMenu.Check("Auto-show on selection")
    else
        A_TrayMenu.Uncheck("Auto-show on selection")
}

ShowSettings(*) {
    MsgBox("Settings can be added here later.", "Text Quick Menu")
}

; ============================================================
; STARTUP  (auto-execute section: runs once, top to bottom)
; ============================================================

AutoShowAllowedSet := ToSet(AutoShowAllowed)
AutoShowBlockedSet := ToSet(AutoShowBlocked)

Menus["Selection"] := BuildMenu(SelectionButtons)
Menus["Hold"] := BuildMenu(HoldButtons)

A_IconTip := "Text Quick Menu"

A_TrayMenu.Delete()
A_TrayMenu.Add("Text Quick Menu", ShowTrayStatus)
A_TrayMenu.Add()
A_TrayMenu.Add("Enabled", ToggleEnabled)
A_TrayMenu.Add("Auto-show on selection", ToggleAutoShow)
A_TrayMenu.Add("Settings", ShowSettings)
A_TrayMenu.Add("Reload", (*) => Reload())
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Check("Enabled")
if AutoShowEnabled
    A_TrayMenu.Check("Auto-show on selection")
