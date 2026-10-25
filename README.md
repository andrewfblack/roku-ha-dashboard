# HA Home Dashboard (Roku)

A sideloaded Roku channel that shows a Home Assistant "Home" dashboard on your TV:

The interface bundles only the Material Design Icons it uses for tabs,
weather, climate modes, settings, and details. Their Apache 2.0 license is
included at `images/mdi/LICENSE`.

Tabs are represented by icons with a visible selected state. Home shows today's
and tomorrow's events and editable weekly meals; OK on the calendar panel opens
the week calendar page. Daily forecasts use centered condition artwork beneath
each weekday.

The television layout uses a high-contrast header with labeled navigation,
larger across-the-room typography, five-day calendar paging, opaque content
surfaces, and display-size icon assets to avoid Roku image-scaling blur.

The Home Assistant integration's Theme and colors section controls the Roku
Home card background/opacity, headings, body and secondary text, selected
focus border, title, and background-image darkening.

- **Calendar** — today's and tomorrow's events on Home; OK opens the standalone
  Skylight-inspired week calendar with 3–7 color-coded day columns. The
  Calendar tab shows the monthly overview.
- **Meal plan** — from a configurable HA sensor (default: `sensor.meal_plan`)
- **Climate** — inside temperature/humidity and outside temperature/condition
- **Weekly meals** — today's meal on Home; OK opens editable Monday–Sunday planning
- **Weather tab** — current conditions plus configurable daily or hourly forecast
  with bundled condition artwork
- **Bundled weather icons** — sun, clouds, rain, storms, snow, fog, wind, hail,
  and clear-night artwork; no external image service required
- **Lights tab** — toggle selected lights and cycle brightness presets
- **Scenes tab** — activate selected Home Assistant scenes and scripts
- **Climate tab** — adjust target temperature and cycle HVAC modes
- **Security tab** — monitor up to two garage doors, four locks, an alarm
  panel, and selected family members' home/away status
- **Live updates** — via the Home Assistant WebSocket API
- **Always-on display** — keeps Roku's system screensaver from replacing the dashboard while the channel is open
- **Tab navigation** — move Right through the Home panels to Weather; Left returns Home
- **Allowlisted controls** — only entities selected in the companion integration can be controlled
- **Idle return** — returns to Home after five minutes without remote input
- **Fall theme** — warm autumn background (`images/fall-bg.jpg`)
- **Seasonal and uploaded backgrounds** — Fall, Winter, Spring, and Summer
  bundled artwork, or an image uploaded through the Home Assistant integration

## 1. Home Assistant preparation

### Pairing
Install and configure the companion Family Dashboard HACS integration. The
Roku creates a device-approval request and waits for approval in Home Assistant.
Every Roku receives a separate revocable device credential; the TV never stores
a Home Assistant long-lived access token.

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

On first launch the **Connect to Home Assistant** screen searches the local
IPv4 network for the Family Dashboard integration. If it is found, select
**START PAIRING**. Otherwise enter the HA URL (for example,
`http://192.168.1.50:8123`) with Roku's native keyboard.

Open the **Family Dashboard** panel in Home Assistant, choose **Pair a device**,
and approve the pending Roku request. The credential and URL are then saved on
the Roku, so setup only happens once unless that device is revoked.

## 3. Debugging

- Roku debug console: `telnet <roku-ip> 8085` (close with Ctrl+] then `quit`).
- If discovery fails, enter the Roku-reachable Home Assistant URL manually.
  Automatic discovery checks `homeassistant.local` and the Roku's local `/24`
  IPv4 network on Home Assistant's standard port, 8123.
- If pairing fails, verify the pending request in the Family Dashboard panel
  and check the integration's Network access setting. HTTPS requires a valid
  certificate (self-signed certificates are not supported without code changes).

> **Display safety:** preventing the screensaver can contribute to image
> retention or burn-in on susceptible displays. Exit the channel when it is
> not needed, especially on OLED TVs.

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
components/SetupView.xml/.brs     first-run discovery and pairing approval
components/tasks/DiscoveryTask.*  local Home Assistant network discovery
components/HomeView.xml/.brs      Home tab UI (calendar, meals, climate)
components/WeekView.xml/.brs      standalone week calendar opened from Home
components/CalendarView.xml/.brs  monthly overview tab
components/tasks/HATask.xml/.brs  background task: REST + WebSocket to Home Assistant
images/fall-bg.jpg                fall background
images/winter-bg.jpg              winter background
images/spring-bg.jpg              spring background
images/summer-bg.jpg              summer background
images/weather/*.png              bundled weather condition artwork
```

Build and sideload this channel, then optionally install the companion
[ha-roku-dashboard](https://github.com/andrewfblack/ha-roku-dashboard) Home
Assistant integration to control calendars, entities, backgrounds and layouts
from HA.

## Roadmap

- Layout customization from Home Assistant (fetch a JSON layout/Lovelelace config
  so panels can be rearranged without rebuilding the channel)
- More tabs: cameras and media (HLS streams play natively on Roku)
