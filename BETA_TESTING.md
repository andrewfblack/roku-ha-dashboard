# Roku beta testing checklist

## Install

1. Download the release ZIP from GitHub.
2. Enable Roku Developer Mode.
3. Open the Roku developer installer at `http://ROKU_IP`.
4. Upload the ZIP under **Development Application Installer**.
5. Install the companion Home Assistant integration and configure the desired
   entities.
6. Select **START PAIRING** on Roku and approve the device in Home Assistant.

## Smoke test

- Home loads with the configured background.
- Home calendar shows today, tomorrow, and the optional next holiday.
- OK on Home calendar opens the week calendar.
- Calendar arrows wrap within the month; day OK opens event details.
- Rewind/Fast Forward switch tabs immediately.
- Weather current conditions and forecast render.
- Lights and switches toggle only selected entities.
- Scenes activate only selected scenes/scripts.
- Security shows garage doors, locks, alarm, and family presence.
- Backgrounds and theme changes refresh after Home Assistant changes.
- Restarting Roku reconnects without pairing again.

## Report a beta issue

Include the Roku model, Roku OS version, Family Dashboard integration version,
the affected tab, reproduction steps, and a photo or debug-console excerpt.

Report issues at:

https://github.com/andrewfblack/roku-ha-dashboard/issues

## Submission items still needed

- Four screenshots captured from the running Roku app.
- Final Roku developer account/channel owner information.
- Confirmation of the support and privacy URLs in the Roku submission form.
