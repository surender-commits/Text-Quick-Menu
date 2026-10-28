
# Text Quick Menu

A lightweight Windows text utility built with AutoHotkey v2. It provides a compact floating menu for copying, pasting, searching selected text, and changing text case using a keyboard shortcut, text-selection gestures, or a click-and-hold gesture.

## Features

- **Floating Selection Menu:** Open a compact menu near the cursor using the backtick key.
- **Copy and Paste:** Trigger `Ctrl+C` or `Ctrl+V` directly from the menu.
- **Paste & Go:** Paste text and automatically press Enter.
- **Google Search:** Search selected text on Google.
- **Text Case Conversion:** Convert selected text to Title Case, UPPERCASE, or lowercase.
- **Automatic Selection Menu:** Show the menu after double-clicking, triple-clicking, or dragging to select text.
- **Click-and-Hold Menu:** Hold the left mouse button to open a smaller menu with Paste and Paste & Go.
- **Application Allow/Block Lists:** Configure which applications can trigger automatic menus.
- **Clipboard Preservation:** Text conversion and search attempt to restore the previous clipboard contents.
- **DPI-Aware Positioning:** Position and size the menu according to display scaling and monitor work areas.
- **System Tray Controls:** Enable or disable the utility, toggle automatic display, reload the script, or exit.
- **Customizable Appearance:** Adjust menu size, spacing, colors, fonts, and behavior through the script configuration.

## Requirements

- Windows 10 or Windows 11.
- [AutoHotkey v2.0](https://www.autohotkey.com/).

**Note:** This script uses AutoHotkey v2 syntax and is not compatible with AutoHotkey v1 without modifications.

## Installation

1. Install AutoHotkey v2 from the [official website](https://www.autohotkey.com/).
2. Download or clone this repository.
3. Locate `Text_Quick_Menu.ahk`.
4. Double-click the file to run it.
5. Find the Text Quick Menu icon in the Windows system tray.

No compilation or build process is required to run the `.ahk` script.

## Usage

### Open the Menu

Press the backtick key (`` ` ``), usually located to the left of `1` on a US keyboard.

The floating menu appears near the mouse cursor.

- Press the backtick key again to toggle the menu.
- Press `Esc` to close the visible menu.

The manual keyboard shortcut works in any application while the utility is enabled, regardless of the automatic menu's application allow/block lists.

### Menu Actions

| Action | Description |
|---|---|
| Copy | Sends `Ctrl+C` to the active application. |
| Paste | Sends `Ctrl+V` to the active application. |
| Paste & Go | Pastes text, waits for the configured delay, and presses Enter. |
| Search | Searches the selected text on Google. |
| Aa | Converts selected text to Title Case. |
| AA | Converts selected text to uppercase. |
| aa | Converts selected text to lowercase. |

The available actions depend on which menu is displayed. The click-and-hold menu contains Paste and Paste & Go.

### Automatic Text Selection Menu

The utility can automatically display the menu when you select text using supported mouse gestures.

Supported gestures include:

- Double-clicking or triple-clicking text.
- Clicking and dragging to select text.

Automatic display depends on the configuration and application allow/block lists. By default, the script checks whether the mouse interaction began with an I-beam cursor to reduce unwanted triggers.

### Click-and-Hold Menu

Hold the left mouse button without moving beyond the configured threshold.

After the configured hold duration, a smaller menu appears with Paste and Paste & Go actions.

The behavior can be customized in the configuration section.

## Keyboard Shortcuts

| Shortcut or Gesture | Action |
|---|---|
| Backtick (`` ` ``) | Show or hide the floating menu |
| `Esc` | Close the visible menu |
| `Ctrl+Alt+T` | Enable or disable the utility |
| Double/triple-click | Trigger the selection menu when enabled |
| Click-and-drag | Trigger the selection menu when enabled |
| Click-and-hold | Trigger the hold menu when enabled |

## Configuration

Open `Text_Quick_Menu.ahk` in a text editor to customize the utility.

Configuration options are defined near the top of the script.

After making changes, save the file and select **Reload** from the system tray menu to apply them.

### Application Allow/Block Lists

The script provides configuration options for controlling which applications can trigger automatic menus.

| Setting | Description |
|---|---|
| `AutoShowAllowed` | List of applications allowed to trigger automatic menus. |
| `AutoShowBlocked` | List of applications blocked from triggering automatic menus. |
| `AutoShowUnlistedApps` | Allows automatic menus in applications not included in either list when enabled. |
| `HoldMenuUseAppLists` | Controls whether the hold menu follows the application lists. |

Application names must match executable process names, such as `chrome.exe`.

You can find application process names in Windows Task Manager under the **Details** tab.

The block list takes priority over the allow list.

### Common Settings

| Setting | Description |
|---|---|
| `HoldTime` | Duration required to hold the mouse button before displaying the hold menu. |
| `HoldMoveThreshold` | Maximum permitted mouse movement during the hold gesture. |
| `HideHoldMenuOnRelease` | Controls whether the hold menu closes when the mouse button is released. |
| `AutoShowEnabled` | Enables or disables automatic menu display at startup. |
| `AutoShowOnMultiClick` | Enables automatic display after double-clicking or triple-clicking. |
| `AutoShowOnDrag` | Enables automatic display after a drag selection. |
| `DragMinDistance` | Minimum mouse movement required for a drag gesture. |
| `RequireIBeamCursor` | Requires an I-beam cursor when the mouse interaction begins. |
| `CopyTimeout` | Time allowed for copying selected text. |
| `PasteGoDelay` | Delay between pasting text and pressing Enter. |
| `ClipRestoreDelay` | Delay before restoring clipboard contents after text conversion. |
| `MenuButtonSize` | Controls menu button dimensions. |
| `MenuPadding` | Controls menu padding. |
| `MenuGap` | Controls spacing between menu elements. |
| `BarColor`, `BorderColor`, `TextColor` | Customize menu colors. |

Color values are represented as RGB hexadecimal strings without the `#` prefix.

## System Tray Menu

The system tray menu provides the following controls:

- **Enabled:** Turn the utility on or off.
- **Auto-show on selection:** Toggle automatic selection-menu display.
- **Settings:** Currently a placeholder; a dedicated graphical settings window is not implemented.
- **Reload:** Reload the script and its configuration.
- **Exit:** Close the utility.

## Troubleshooting

### The Menu Does Not Appear Automatically

- Confirm that the utility is enabled.
- Check that automatic menu display is enabled.
- Verify the active application's process name.
- Check the `AutoShowAllowed` and `AutoShowBlocked` lists.
- Review the `AutoShowUnlistedApps` setting.
- If cursor detection prevents the menu from appearing, try setting `RequireIBeamCursor := false`.

### The Menu Does Not Appear in a Specific Application

Check the application's executable name in Windows Task Manager and confirm that it is not included in `AutoShowBlocked`.

### The Keyboard Shortcut Does Not Work as Expected

The script uses scan code `SC029`, documented as the key to the left of `1` on a US keyboard.

Different keyboard layouts may map this key differently.

### Copy or Paste Does Not Work

The utility sends standard keyboard shortcuts. Its behavior depends on whether the active application or control supports `Ctrl+C` and `Ctrl+V`.

### Configuration Changes Do Not Apply

1. Save `Text_Quick_Menu.ahk`.
2. Open the Text Quick Menu system tray menu.
3. Select **Reload**.

## Known Limitations

- The script relies on standard keyboard shortcuts rather than application-specific editing APIs.
- Google is the configured search provider.
- The Settings tray item is currently a placeholder.
- Automatic menu behavior depends on application process names and configuration.
- Behavior may vary across applications, keyboard layouts, and text controls.

## Contributing

Contributions, bug reports, and feature suggestions are welcome.

When submitting a bug report, include:

- A description of the issue.
- Steps to reproduce the behavior.
- The affected application and Windows version.
- Relevant configuration settings, if applicable.

When submitting a pull request, explain the changes and how they were tested.

## License

No license information was included with the supplied source file.

Before publishing this repository, add a `LICENSE` file if you intend to specify how others may use, modify, and redistribute the project.

Until a license is added, do not assume that the repository grants standard open-source reuse permissions.
