# HA Home Dashboard (Roku)

A sideloaded Roku channel that shows a Home Assistant "Home" dashboard on your TV:

- **Calendar** — today's next three events plus a current-month overview with event markers
- **Meal plan** — from a configurable HA sensor (default: `sensor.meal_plan`)
- **Climate** — inside temperature/humidity and outside temperature/condition
- **Live updates** — via the Home Assistant WebSocket API
- **Fall theme** — warm autumn background (`images/fall-bg.jpg`)

## 1. Home Assistant preparation

### Pairing code
Install and configure the companion Roku Dashboard HACS integration. Open
`sensor.roku_dashboard_config` in Developer Tools → States and copy its
`pairing_code` attribute. The Roku needs only this 8-character code; it does
not store a Home Assistant long-lived access token.

### Meal plan sensor
The channel reads the *state* of an entity you choose. Easiest option — a helper you can edit from the HA UI (even from your phone):

```yaml
# configuration.yaml
input_text:
  meal_plan:
    name: Meal Plan
    max: 255
```

Then update it however you like (automations, scripts, the Actions tab). The default
entity is `sensor.meal_plan`; if you use `input_text.meal_plan` just enter that
entity id in the channel setup screen. Any text entity works.

### Calendars
Any entity under `/api/calendars` is picked up automatically (this is where your
Google/Outlook calendars appear after the Calendar integration is configured).
The channel shows the next 5 of today's events.

If the **Roku Dashboard HACS integration** is installed, the channel reads
`sensor.roku_dashboard_config` and shows only the calendars you selected there
(leave the selection empty to show all).

### Temperature auto-detection
If you leave the inside/outside entity fields blank:
- **Outside** = the first `weather.*` entity
- **Inside** = the first `climate.*` entity, otherwise the first `sensor.*`
  entity with `device_class: temperature` whose name doesn't look outdoor

## 2. Sideload the channel

1. Enable **Developer Mode** on your Roku ([instructions](https://developer.roku.com/docs/developer-program/dev-settings/dev-web-interface.md)).
2. Package the app:

   ```sh
   cd roku-ha-dashboard
   zip -r ../ha-home-dashboard.zip manifest source components images
   ```

3. Open `http://<roku-ip>` in a browser (the dev web interface), log in
   (`rokudev` + your dev password), and upload the zip under **Development
   Application Installer**. The channel launches automatically.

On first launch the **Connect to Home Assistant** screen appears. It has only
two fields: your HA URL (e.g. `http://192.168.1.50:8123`) and pairing code.
Use Up/Down to select a field and press **OK** to open Roku's native keyboard.
Choose **SAVE** in the keyboard when finished, then select **CONNECT**. The
token is masked on the TV after entry. Everything is saved on the device, so
setup only happens once (or after a failed login, when the values are restored).

## 3. Debugging

- Roku debug console: `telnet <roku-ip> 8085` (close with Ctrl+] then `quit`).
- If login fails: check the URL works from your phone's browser, and that the
  token wasn't revoked. HTTPS requires a valid certificate (self-signed certs
  are not supported without code changes).

## 4. Customization

- **Background**: replace `images/fall-bg.jpg` (1920x1080) and re-zip.
- **Colors/fonts**: component XML files use plain colors (e.g. `0xE0913EFF`)
  and built-in system fonts.
- **Layout**: panel coordinates are in each component's XML (FHD 1920x1080).

## Project layout

```
manifest                          channel metadata (FHD)
source/main.brs                   screen bootstrap
components/MainScene.xml/.brs     coordinator: setup vs home, registry, task wiring
components/SetupView.xml/.brs     first-run HA URL + token entry
components/HomeView.xml/.brs      Home tab UI (calendar, meals, climate)
components/tasks/HATask.xml/.brs  background task: REST + WebSocket to Home Assistant
images/fall-bg.jpg                fall background
```

Build and sideload this channel, then optionally install the companion
[ha-roku-dashboard](https://github.com/andrewfblack/ha-roku-dashboard) Home
Assistant integration to control calendars, entities, backgrounds and layouts
from HA.

## Roadmap (v2 ideas)

- Layout customization from Home Assistant (fetch a JSON layout/Lovelelace config
  so panels can be rearranged without rebuilding the channel)
- Controls: lights, switches, climate setpoints
- More tabs: lights, cameras (HLS streams play natively on Roku)
