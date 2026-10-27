# Sanwa 400-MABT156 ring mouse: what it sends

The reference for remapping Mauria's Sanwa ring mouse with this branch of LinearMouse (`sanwa` on `kudzuweb/linearmouse`), and how to set it up on another Mac. Measured on home-laptop, macOS 27.2, 2026-10-27, with a diagnostic build from branch `probe/key-attribution`, which exists only in the home-laptop clone. Every row below is verified from that build's log unless it says otherwise.

## The device

| Fact | Value |
|---|---|
| Product | Sanwa Supply 400-MABT156 (BK2 black, GM2 gunmetal), a 16 g Bluetooth ring mouse worn on a finger; the thumb tilts a stick to move the cursor. Four buttons plus the stick. Released 2024-03-06 (Sanwa press release). |
| Name it reports | `GMABT156BK6-1` |
| Vendor and product ID | `0x248A` / `0x8266`. LinearMouse upstream lists the same ID as a "Delux M729DB mouse", so it is likely a rebadged Delux design (inferred). |
| Connection | Bluetooth Low Energy, HID over GATT. It goes to sleep when idle; move the stick to wake it before testing. |
| HID collections | Keyboard (page 1 usage 6, its primary usage), consumer control (12/1), mouse (1/2), pointer (1/1), vendor-defined (`0xFF01`/1). The keyboard collection is why macOS opened the Keyboard Setup Assistant when it was first paired; close that window. |
| Firmware | Closed. No Mac software from Sanwa or Delux, no community project; it cannot be reprogrammed on the device. |

## What each button sends

The page buttons are keystroke buttons, not mouse buttons. Every keystroke is a down and up about 7 to 9 ms apart, however long the button is held: the ring never holds a key down and never repeats, so no button gives LinearMouse a "still held" signal and push-to-talk on these buttons is impossible.

| Button and gesture | Sends | macOS key code | HID usage (page 7) |
|---|---|---|---|
| Page up, tap | Page Up | 116 | `0x4B` |
| Page up, hold (about a second or more) | Escape, once | 53 | `0x29` |
| Page down, tap | Page Down | 121 | `0x4E` |
| Page down, hold | B, once | 11 | `0x05` |
| Unattributed, from an unlabeled hold test | Shift+F5, then Cmd+Option+P 31 ms later | 96 (F5) with Shift; 35 (P) with Cmd+Option | `0x3E` + `0xE1`; `0x13` + `0xE3` + `0xE2` |

The unattributed pair came during a test where page up and page down were each held without saying which was which. Labeled holds of each page button later sent only Escape and B, so the pair may come from the other buttons or from a hold of a different length. Retest with one labeled button per round before relying on it. These look like the ring's presentation-mode shortcuts (start slideshow from current slide, presenter view, black screen).

Not yet measured: the two other buttons and pressing the stick, as taps and as holds. They are probably the left and right mouse buttons, which are real mouse buttons that LinearMouse can map with press, long press and hold (inferred from the product's "left and right click" description).

## How LinearMouse sees it

| Fact | Detail |
|---|---|
| Key events carry the ring's device ID | `IOHIDEventGetSenderID` on its keystrokes equals the ID LinearMouse tracks for it as a pointing device, so a key trigger can be scoped to the ring and the keyboard's own keys are untouched. This is what the `key-triggers` branch relies on. |
| Trigger names | Each keystroke above is its own trigger: `pageUp`, `escape`, `pageDown`, `b`. A hold is a separate trigger, not a long press of the tap's trigger. LinearMouse's long-press outcome can never fire on these buttons, because the key is released within 9 ms. |
| Recording | Move the stick first so the ring is the active device, then press the button while the recorder is listening. |
| Config that works | The mapping below, in `~/.config/linearmouse/linearmouse.json`, sends Fn on a tap of page up and starts dictation. |

```json
{
  "outcomes": { "shortPress": { "keyPress": ["fn"] } },
  "trigger": { "input": { "button": { "kind": "key", "key": "pageUp" } } }
}
```

Stock LinearMouse (any build without the `key-triggers` branch) refuses to load a config containing `"kind": "key"` and shows "Failed to load the configuration: ... Cannot initialize Kind from invalid String value key". Move the config aside before running such a build.

## Setting it up on another Mac

The build with key triggers and the Fn action lives on branch `sanwa` of Mauria's fork, `kudzuweb/linearmouse` (pushed 2026-10-27). It is the four local branches merged together: `recorder-primary-drift`, `quirk-handler-product-name`, `fn-key-action`, `key-triggers`.

1. Install Xcode, then `brew install swiftlint swiftformat npm`.
2. `git clone -b sanwa https://github.com/kudzuweb/linearmouse.git && cd linearmouse && npm install && make configure`. Without an Apple Development certificate in the keychain, `make configure` signs ad hoc, and macOS may ask for Accessibility again after each rebuild.
3. `make "$PWD/build/Release/LinearMouse.app"`. The archive step must print `** ARCHIVE SUCCEEDED **`; the export step then fails without a Developer ID certificate, which is expected.
4. `ditto build/LinearMouse.xcarchive/Products/Applications/LinearMouse.app /Applications/LinearMouse.app`, open it from `/Applications`, and grant Accessibility in System Settings › Privacy & Security. On a company-managed Mac this may need IT. Run it from `/Applications`, never from the `build` folder: the next build replaces that copy, and Start at login and the Accessibility permission both point at the app's location, so an app in `build` stops working or loses its permission after a rebuild.
5. Pair the ring, close the Keyboard Setup Assistant if it appears, and write the config below to `~/.config/linearmouse/linearmouse.json` before opening LinearMouse.
6. Turn on Start at login from LinearMouse's menu bar icon.

Config as of 2026-10-27: tap page up sends Fn (dictation), tap page down sends Enter; hold page up already sends Escape from the ring itself; hold page down sends B and is unmapped.

```json
{
  "schemes": [
    {
      "buttons": {
        "mappings": [
          {
            "outcomes": {
              "shortPress": {
                "keyPress": [
                  "fn"
                ]
              }
            },
            "trigger": {
              "input": {
                "button": {
                  "key": "pageUp",
                  "kind": "key"
                }
              }
            }
          },
          {
            "outcomes": {
              "shortPress": {
                "keyPress": [
                  "enter"
                ]
              }
            },
            "trigger": {
              "input": {
                "button": {
                  "key": "pageDown",
                  "kind": "key"
                }
              }
            }
          }
        ]
      },
      "if": {
        "device": {
          "category": "mouse",
          "productID": "0x8266",
          "productName": "GMABT156BK6-1",
          "vendorID": "0x248a"
        }
      },
      "scrolling": {
        "acceleration": {
          "vertical": 1
        },
        "distance": {
          "vertical": "auto"
        },
        "smoothed": {
          "vertical": {
            "acceleration": 0.78,
            "bouncing": true,
            "enabled": true,
            "inertia": 0.44,
            "preset": "linear",
            "response": 0.9200000000000002,
            "speed": 1
          }
        },
        "speed": {
          "vertical": 0
        }
      }
    },
    {
      "if": {
        "device": {
          "category": "trackpad",
          "productID": "0x0",
          "productName": "Apple Internal Keyboard / Trackpad",
          "vendorID": "0x0"
        }
      },
      "scrolling": {
        "acceleration": {
          "vertical": 1
        },
        "distance": {
          "vertical": "auto"
        },
        "smoothed": {
          "vertical": {
            "acceleration": 1.2,
            "bouncing": true,
            "enabled": false,
            "inertia": 0.78,
            "preset": "easeInOutCubic",
            "response": 0.62,
            "speed": 1.0600000000000003
          }
        },
        "speed": {
          "vertical": 0
        }
      }
    }
  ]
}
```

## Re-measuring

On home-laptop, check out `probe/key-attribution` in its own worktree (`~/Documents/Projects/linearmouse/.worktrees/probe` exists; the branch is not pushed), build with `make "$PWD/build/Release/LinearMouse.app"`, park the config as above, run the archived app, and read `/usr/bin/log show --last 1m --info --style compact --predicate 'category == "KeyProbe"'`. Bare `log` is shadowed in Mauria's zsh; call `/usr/bin/log`. The build logs key events only from managed pointing devices, never from the keyboard.
