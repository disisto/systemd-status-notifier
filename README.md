<p align="center">
<a href="https://troubleshooting.tools/lookup/ip/"><img src="https://troubleshooting.tools/assets/img/troubleshooting.tools/gh_logo.png" height="200"></a>
</p>

# systemd status notifier

This bash script allows you to be notified via Email, Mattermost, PagerDuty, Slack and/or SMS (sipgate) when an enabled systemd service is in a failed condition.

<img src="https://github.com/disisto/systemd-status-notifier/raw/main/img/0_systemd-status-monitor.gif">

---

# Content

- [Supported services](https://github.com/disisto/systemd-status-notifier/wiki#supported-services)
- [Requirements](https://github.com/disisto/systemd-status-notifier/wiki#requirements)
- [Installation](https://github.com/disisto/systemd-status-notifier/wiki#installation)
  - [Download](https://github.com/disisto/systemd-status-notifier/wiki#download)
  - [Access and ownership permissions](https://github.com/disisto/systemd-status-notifier/wiki#access-and-ownership-permissions)
  - [Create a systemd service](https://github.com/disisto/systemd-status-notifier/wiki#create-a-systemd-service)
  - [Optional: Cron job](https://github.com/disisto/systemd-status-notifier/wiki#optional-cron-job)
- [Script adaptation](https://github.com/disisto/systemd-status-notifier/wiki#script-adaptation)
  - [Select the systemd services to monitor](https://github.com/disisto/systemd-status-notifier/wiki#select-the-systemd-services-to-monitor)
  - [Select the channel for notifications](https://github.com/disisto/systemd-status-notifier/wiki#select-the-channel-for-notifications)
- [Channel configuration](https://github.com/disisto/systemd-status-notifier/wiki#channel-configuration)
  - [Email notifications](https://github.com/disisto/systemd-status-notifier/wiki#email-notifications)
  - [Mattermost notifications](https://github.com/disisto/systemd-status-notifier/wiki#mattermost-notifications)
  - [PagerDuty notifications](https://github.com/disisto/systemd-status-notifier/wiki#pagerduty-notifications)
  - [sipgate SMS notifications](https://github.com/disisto/systemd-status-notifier/wiki#sipgate-sms-notifications)
  - [Slack notifications](https://github.com/disisto/systemd-status-notifier/wiki#slack-notifications)

---

## Supported services

| Service       | Method |
| ------------- | ------ |
| Email         | MTA    |
| Mattermost    | API    |
| PagerDuty     | API    |
| sipgate (SMS) | API    |
| Slack         | API    |

---

## Requirements

- Linux OS with systemd

- For Email notifications: Mail Transfer Agent (MTA) like `postfix`

- For Mattermost/sipgate/Slack notifications: `cURL`

- For PagerDuty API v2 notifications: `pdagent`

---

This project is not affiliated with <a href="https://mattermost.com/">Matterhost</a>, <a href="https://www.pagerduty.com/">PagerDuty</a>, <a href="https://www.sipgate.de/">sipgate</a> and/or <a href="https://www.sipgate.de/">Slack</a><br>All mentioned trademarks are the property of their respective owners.
