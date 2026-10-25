# Privacy

Family Dashboard is a Roku client for a Home Assistant installation that you
control. The channel does not include advertising, analytics, tracking, or a
third-party account system.

The channel communicates with the Home Assistant URL configured during setup.
Home Assistant supplies the dashboard data and selected controls. The Roku
stores the configured URL and its own device credential locally so it can
reconnect. It does not store a Home Assistant long-lived access token.

Data shown on the TV depends on the entities selected in Home Assistant. The
channel does not send dashboard data to the Family Dashboard project or to a
third-party service.

To revoke a device, remove it from the paired devices in the Family Dashboard
Home Assistant panel. For questions or privacy requests, use the project issue
tracker:

https://github.com/andrewfblack/roku-ha-dashboard/issues
