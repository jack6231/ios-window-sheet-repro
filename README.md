# ios-window-sheet-repro

A minimal UIKit app for [maestro-runner issue #285](https://github.com/devicelab-dev/maestro-runner/issues/285):
the DeviceLab iOS driver's hierarchy omits a full-screen view that the app adds directly to the `UIWindow`,
while `--driver wda` returns it.

## What it shows

A bottom sheet built as a plain full-screen `UIView` and added with `keyWindow.addSubview(sheet)`
(dimming view + rounded container with `accessibilityViewIsModal = true`, a scroll view, buttons, a confirm button).
Behind it is a navigation controller with a table.

**The sheet disappears from the DeviceLab hierarchy when the page below it is presented modally**
(`present(nav, animated:)`). The page stays in the tree; every other window-level subtree is gone.
WDA returns all of them. Same result on maestro-runner 1.1.28 and 1.1.31.

Setting `accessibilityViewIsModal = true` on the **sheet's root view** makes DeviceLab return the sheet
(and then the page is the one that disappears).

So DeviceLab does apply `accessibilityViewIsModal` to window-level siblings, as VoiceOver does,
and WDA ignores it. In the issue thread the modal flag was ruled out because both drivers ask for the snapshot
with modal views not honoured. The numbers below point the other way.

## Results

iPhone 16 Pro, iOS 26.6.1, Xcode 26.4.1. Each cell is the node count of every child of the `Window`
(`[2, 100, 77]` = three children with 2, 100 and 77 nodes). **Sheet** = `sheet_title_label` is in the tree.

| `DEMO_OPTS` | WDA (1.1.28) | DeviceLab 1.1.28 | DeviceLab 1.1.31 |
|---|---|---|---|
| *(none)*: nav controller is the window root | `[2,100,77]` sheet | `[2,100,76]` sheet | `[2,100,76]` sheet |
| `noContainerModal` | `[2,100,77]` sheet | `[2,100,77]` sheet | not run |
| `sheetRootModal` | `[2,100,77]` sheet | `[76]` sheet, page gone | not run |
| `pageModal` / `navModal` | `[2,100,77]` sheet | `[2,100,76]` sheet | not run |
| `presented` | `[2,3,99,77]` sheet | **`[99]` no sheet** | **`[99]` no sheet** |
| `presentedFull` | `[2,2,99,77]` sheet | **`[99]` no sheet** | not run |
| `presented,map` | `[2,19,99,77]` sheet | **`[99]` no sheet** | not run |
| `presented,pageModal` / `presented,navModal` | `[2,3,99,77]` sheet | **`[99]` no sheet** | not run |
| `presented,noContainerModal` | `[2,3,99,77]` sheet | **`[99]` no sheet** | **`[99]` no sheet** |
| `presented,sheetRootModal` | `[2,3,99,77]` sheet | `[76]` sheet, page gone | `[76]` sheet, page gone |
| `presented,noContainerModal,sheetRootModal` | `[2,3,99,77]` sheet | `[77]` sheet, page gone | `[77]` sheet, page gone |
| `presentedFull,sheetRootModal` | `[2,2,99,77]` sheet | `[76]` sheet, page gone | `[76]` sheet, page gone |

Notes:

- The container's own `accessibilityViewIsModal` only hides the dimming view (76 nodes instead of 77).
  `presented,noContainerModal` still loses the sheet, so the sheet's own flag is not the cause.
- `--driver devicelab-legacy` refuses a real device ("only supports simulators in Phase 4"), so it is not in the table.
- Not tried on a simulator. The thread reports that the plain structure (first row) reads fine there,
  which matches the first row here.
- It is not known whether the public `XCUIApplication.snapshot()` already omits the sheet or the agent drops it later.
- `results/` holds the two trees for `presented`, one per driver.

## Run it

Built with Xcode 26.4.1, deployment target iOS 15. [XcodeGen](https://github.com/yonaskolb/XcodeGen) is only
needed if you change `project.yml`; the generated project is committed.

1. Open `WindowSheetDemo.xcodeproj`, pick your team, run on a device.
2. Choose the structure with `DEMO_OPTS` (comma separated, see `WindowSheetDemo/Options.swift`).
   The value is stored in `UserDefaults`, so it survives a driver relaunching the app.
   An empty value resets it.

   ```
   xcrun devicectl device process launch --device <id> --terminate-existing \
       -e '{"DEMO_OPTS":"presented"}' com.example.WindowSheetDemo

   # simulator
   SIMCTL_CHILD_DEMO_OPTS=presented xcrun simctl launch --terminate-running-process booted com.example.WindowSheetDemo
   ```

3. Open the sheet: tap the **Panel** switch, or run `flows/open_sheet.yaml` with `--driver wda`.
4. Dump the hierarchy with each driver while the sheet is up:

   ```
   maestro-runner --platform ios --device <udid> --driver wda hierarchy --compact
   maestro-runner --platform ios --device <udid> --driver devicelab hierarchy --compact
   ```

Accessibility identifiers: `sheet_trigger_switch` (opens the sheet), `sheet_container`, `sheet_title_label`,
`sheet_close`, `sheet_confirm_btn`.

## Options

| Token | Effect |
|---|---|
| `presented` / `presentedFull` | Present the navigation controller over a base screen (`.overFullScreen` / `.fullScreen`) instead of making it the window root |
| `map` | The base screen holds a full-screen `MKMapView` |
| `pageModal` / `navModal` | `accessibilityViewIsModal` on the page's view / the navigation controller's view |
| `sheetRootModal` | `accessibilityViewIsModal` on the sheet's root view as well |
| `noContainerModal` | Leave the sheet container's `accessibilityViewIsModal` off |
| `noHitGuard` | Drop the `hitTest` override that swallows touches right after the sheet appears |
| `attachView` | Add the sheet to the root view controller's view instead of the key window |
| `noOverlay` | Drop the empty full-screen view inserted at index 0 of the window |
