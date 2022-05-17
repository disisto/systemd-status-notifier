#!/bin/bash

#**
#    systemd status notifier
#    Version 0.2.1
#
#    A bash script that triggers an Email, Mattermost, PagerDuty, Pushover, Slack and/or SMS (sipgate) notification 
#    when an enabled systemd service is in a failed condition.
#
#    Documentation: https://github.com/disisto/systemd-status-notifier
#
#
#    Licensed under MIT (https://github.com/disisto/systemd-status-notifier/blob/main/LICENSE)
#
#    Copyright (c) 2022 Roberto Di Sisto
#
#    Permission is hereby granted, free of charge, to any person obtaining a copy
#    of this software and associated documentation files (the "Software"), to deal
#    in the Software without restriction, including without limitation the rights
#    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#    copies of the Software, and to permit persons to whom the Software is
#    furnished to do so, subject to the following conditions:
#
#    The above copyright notice and this permission notice shall be included in all
#    copies or substantial portions of the Software.
#
#    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#    SOFTWARE.
##/

### Add here systemd services you want to monitor
### Add "all" to monitor all systemd service or specific single services you want
### to monitor. Example: apache2, postfix, mariadb, custom application name, etc. 
### Get a full list with: systemctl list-units --type=service
SYSTEMD_SERVICES=(all getty@)

### Add here messaging services you want to use
### Possibilities: "email", "mattermost", "pagerduty", "pushover", "sipgate" and/or "slack"
MESSAGING_SERVICES=(email mattermost pagerduty pushover sipgate slack)

### Add here the sender email address
EMAIL_SENDER=(noreply@troubleshooting.tools)

### Add here the recipients email addresses for Email notifications
EMAIL_RECIPIENTS=(admin_1@troubleshooting.tools admin_2@troubleshooting.tools)

### Add here the SMS ID for SMS notifications via sipgate
SIPGATE_SMSID=(s0)

### Add here the recipients phone number for SMS notifications via sipgate
SIPGATE_RECIPIENT=(+4900000000000 +31999999999)


# ----------------------------------------------------------------------------------------------------------- #
#   On production servers, keep this box of tokens in a local secret storage and remove it from this script   #
# ----------------------------------------------------------------------------------------------------------- #
#                                                                                                             #
# Mattermost Webhook URL                                                                                      #
MATTERMOST_WEBHOOK_URL==https://mattermost.troubleshooting.tools/hooks/xx0xx0xxxxxxxxxxxxxx0xx0xx             #
#                                                                                                             #
# Slack Webhook URL                                                                                           #
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/X00XX0X0XXX/X00XXX00XXX/XXxxxxxxXxx0xxXxXX0X0xXX           #
#                                                                                                             #
# PagerDuty service key URL                                                                                   #
PD_SERVICE_KEY=0x00x000xx00000xx000x00000xx0x00                                                               #
#                                                                                                             #
# Pushover application token                                                                                  #
PUSHOVER_TOKEN=xxx00xxxx0xxxxx0xxxx0xxxxxxx0x                                                                 #
#                                                                                                             #
# Pushover user token                                                                                         #
PUSHOVER_USER=xxxxxxxx0xx0xxxxx0xx0xx00xx0                                                                    #
#                                                                                                             #
# sipgate tockenid and token                                                                                  #
SIPGATE_TOKEN=token-XXX00X:0000xx0x-xxx0-0x00-x0xx-00000x0xxx0x                                               #
#                                                                                                             #
# ----------------------------------------------------------------------------------------------------------- #


####################################################
### No further editing is needed below this line ###
####################################################

### Error handling
if (( !${#SYSTEMD_SERVICES[@]} )); 
  then
    echo -e "No systemd service is set up: Undefined variable \$SYSTEMD_SERVICES in `pwd`/`basename "$0"` on line 40."
	exit
fi

if (( !${#MESSAGING_SERVICES[@]} )); 
  then
    echo -e "No messaging service is set up: Undefined variable \$MESSAGING_SERVICES in `pwd`/`basename "$0"` on line 44."
	exit
fi

if (( !${#EMAIL_SENDER[@]} )); 
  then
	echo -e "No email sender is set up: Undefined variable \$EMAIL_SENDER in `pwd`/`basename "$0"` on line 47."
	exit
fi

if (( !${#EMAIL_RECIPIENTS[@]} )); 
  then
    echo -e "No email address for email reception set up: Undefined variable \$EMAIL_RECIPIENTS in `pwd`/`basename "$0"` on line 50."
	exit
fi

if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "mattermost" && (( !${#MATTERMOST_WEBHOOK_URL} )) ); 
  then
    echo -e "No Mattermost webhook URL set up: Undefined variable \$MATTERMOST_WEBHOOK_URL in `pwd`/`basename "$0"`."
	exit
fi

if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "pagerduty" && (( !${#PD_SERVICE_KEY} )) ); 
  then
    echo -e "No PagerDuty service key set up: Undefined variable \$PD_SERVICE_KEY in `pwd`/`basename "$0"`."
	exit
fi

if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "pushover" && (( !${#PUSHOVER_TOKEN} )) ); 
  then
    echo -e "No Pushover application token set up: Undefined variable \$PUSHOVER_TOKEN in `pwd`/`basename "$0"`."
	exit
fi

if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "pushover" && (( !${#PUSHOVER_USER} )) ); 
  then
    echo -e "No Pushover user token set up: Undefined variable \$PUSHOVER_USER in `pwd`/`basename "$0"`."
	exit
fi

if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "sipgate" && (( !${#SIPGATE_SMSID} )) ); 
  then
    echo -e "No SMS ID for SMS reception via sipgate set up: Undefined variable \$SIPGATE_SMSID in `pwd`/`basename "$0"` on line 53."
	exit
fi

if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "sipgate" && (( !${#SIPGATE_RECIPIENT} )) ); 
  then
    echo -e "No phone number for SMS reception via sipgate set up: Undefined variable \$SIPGATE_RECIPIENT in `pwd`/`basename "$0"` on line 56."
	exit
fi

if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "sipgate" && (( !${#SIPGATE_TOKEN} )) ); 
  then
    echo -e "No sipgate token set up: Undefined variable \$SIPGATE_TOKEN in `pwd`/`basename "$0"`."
	exit
fi

if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "slack" && (( !${#SLACK_WEBHOOK_URL} )) ); 
  then
    echo -e "No Slack webhook URL set up: Undefined variable \$SLACK_WEBHOOK_URL in `pwd`/`basename "$0"`."
	exit
fi


### List which notification methods were used 
for messagingServices in ${MESSAGING_SERVICES[@]^}; do
  messagingService="${messagingService:+$messagingService, }$messagingServices"
done

### List email recipients 
for emailRecipients in ${EMAIL_RECIPIENTS[@]}; do
  emailRecipient="${emailRecipient:+$emailRecipient, }$emailRecipients"
done


### Formatting the date in unix to include suffix on day (st, nd, rd and th)
## https://stackoverflow.com/questions/40607925/date-format-in-bash-cases
d=$(date +%e)
case $d in
    1?) d=${d}th ;;
    *1) d=${d}st ;;
    *2) d=${d}nd ;;
    *3) d=${d}rd ;;
    *)  d=${d}th ;;
esac



if [[ ${SYSTEMD_SERVICES[@]::1} =~ "all"( |$) ]];
  then
    SYSTEMD_SERVICES=$(systemctl list-unit-files --no-pager --no-legend  --type=service --state=enabled | awk -F'.service ' '{print $1}')
	SKIP_SERVICES=${SYSTEMD_SERVICES[@]:1} 
fi

for systemdService in ${SYSTEMD_SERVICES[@]/$SKIP_SERVICES}; do

  if (systemctl is-failed --quiet service $systemdService);
  then
    ### For debugging: Console output
	#echo -e "$systemdService...DOWN!"

	###############################
    ############ EMAIL ############
    ###############################

    ### Trigger Email notification
	if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "email"); then
		(
		  sirenEmoji=(=?utf-8?Q?=F0=9F=9A=A8?=)
		  echo "From: $EMAIL_SENDER "
		  echo "To: $emailRecipient "
		  echo "MIME-Version: 1.0"
		  echo "Content-Type: text/html; " 
		  echo "Subject: $sirenEmoji systemd Monitor: $systemdService on `hostname` is DOWN! (`date +"%Y-%m-%d %T"`)" 
		  echo "" 
		  echo "<!doctype html>
				  <html>
				    <head>
					  <meta name='viewport' content='width=device-width'>
					  <meta http-equiv='Content-Type' content='text/html; charset=UTF-8'>
						<title>$systemdService on `hostname` is DOWN!</title>
					  <style>
						@media only screen and (max-width: 620px) {
						table[class=body] h1 {
							font-size: 28px !important;
							margin-bottom: 10px !important;
						}

						table[class=body] p,
						table[class=body] ul,
						table[class=body] ol,
						table[class=body] td,
						table[class=body] span,
						table[class=body] a {
							font-size: 16px !important;
						}

						table[class=body] .wrapper,
						table[class=body] .article {
							padding: 10px !important;
						}

						table[class=body] .content {
							padding: 0 !important;
						}

						table[class=body] .container {
							padding: 0 !important;
							width: 100% !important;
						}

						table[class=body] .main {
							border-left-width: 0 !important;
							border-radius: 0 !important;
							border-right-width: 0 !important;
						}

						table[class=body] .btn table {
							width: 100% !important;
						}

						table[class=body] .btn a {
							width: 100% !important;
						}

						table[class=body] .img-responsive {
							height: auto !important;
							max-width: 100% !important;
							width: auto !important;
						}
						}
						@media all {
						.ExternalClass {
							width: 100%;
						}

						.ExternalClass,
						.ExternalClass p,
						.ExternalClass span,
						.ExternalClass font,
						.ExternalClass td,
						.ExternalClass div {
							line-height: 100%;
						}

						.apple-link a {
							color: inherit !important;
							font-family: inherit !important;
							font-size: inherit !important;
							font-weight: inherit !important;
							line-height: inherit !important;
							text-decoration: none !important;
						}

						.btn-primary table td:hover {
							background-color: #d5075d !important;
						}

						.btn-primary a:hover {
							background-color: #d5075d !important;
							border-color: #d5075d !important;
						}
						}
						</style>
					  </head>
					  <body class style='background-color: #eaebed; font-family: sans-serif; -webkit-font-smoothing: antialiased; font-size: 14px; line-height: 1.4; margin: 0; padding: 0; -ms-text-size-adjust: 100%; -webkit-text-size-adjust: 100%;'>
						<table role='presentation' border='0' cellpadding='0' cellspacing='0' class='body' style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; min-width: 100%; background-color: #eaebed; width: 100%;' width='100%' bgcolor='#eaebed'>
						<tr>
							<td style='font-family: sans-serif; font-size: 14px; vertical-align: top;' valign='top'>&nbsp;</td>
							<td class='container' style='font-family: sans-serif; font-size: 14px; vertical-align: top; display: block; max-width: 580px; padding: 10px; width: 580px; Margin: 0 auto;' width='580' valign='top'>
							<div class='header' style='padding: 20px 0;'>
								<table role='presentation' border='0' cellpadding='0' cellspacing='0' width='100%' style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; min-width: 100%; width: 100%;'>
								<tr>
									<td class='align-center' width='100%' style='font-family: sans-serif; font-size: 14px; vertical-align: top; text-align: center;' valign='top' align='center'>
									<a href='https://github.com/disisto/systemd-status-notifier' style='color: #ec0867; text-decoration: underline;'><img src='https://troubleshooting.tools/assets/img/troubleshooting.tools/systemd_email_logo.gif' height='100%' alt='troubleshooting.tools' style='border: none; -ms-interpolation-mode: bicubic; max-width: 100%; border-radius: 20%;'></a>
									</td>
								</tr>
								</table>
							</div>
							<div class='content' style='box-sizing: border-box; display: block; Margin: 0 auto; max-width: 580px; padding: 10px;'>

								<!-- START CENTERED WHITE CONTAINER -->
								<span class='preheader' style='color: transparent; display: none; height: 0; max-height: 0; max-width: 0; opacity: 0; overflow: hidden; mso-hide: all; visibility: hidden; width: 0;'>Attention. System failure. High urgency.</span>
								<table role='presentation' class='main' style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; min-width: 100%; background: #ffffff; border-radius: 3px; width: 100%;' width='100%'>

								<!-- START MAIN CONTENT AREA -->
								<tr>
									<td class='wrapper' style='font-family: sans-serif; font-size: 14px; vertical-align: top; box-sizing: border-box; padding: 20px;' valign='top'>
									<table role='presentation' border='0' cellpadding='0' cellspacing='0' style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; min-width: 100%; width: 100%;' width='100%'>
										<tr>
										<td style='font-family: sans-serif; font-size: 14px; vertical-align: top;' valign='top'>
											<p style='font-family: sans-serif; font-size: 14px; font-weight: normal; margin: 0; margin-bottom: 15px;'></p>
											<p style='font-family: sans-serif; font-size: 14px; font-weight: normal; margin: 0; margin-bottom: 15px;'>systemd reports on host <b>`hostname`</b> that the following service is down:</p>
											<br>
											<table role='presentation' border='0' cellpadding='0' cellspacing='0' class='btn btn-primary' style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; min-width: 100%; box-sizing: border-box; width: 100%;' width='100%'>
											<tbody>
												<tr>
												<td align='center' style='font-family: sans-serif; font-size: 14px; vertical-align: top; padding-bottom: 15px;' valign='top'>
													<table role='presentation' border='0' cellpadding='0' cellspacing='0' style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; min-width: auto; width: auto;'>
													<tbody>
														<tr>
														<td style='font-family: sans-serif; font-size: 14px; vertical-align: top; border-radius: 5px; text-align: center; background-color: #ec0867;' valign='top' align='center' bgcolor='#ec0867'> <div style='border: solid 1px #ec0867; border-radius: 5px; box-sizing: border-box; cursor: pointer; display: inline-block; font-size: 28px; font-weight: bold; margin: 0; padding: 12px 25px; text-decoration: none; background-color: #ec0867; border-color: #ec0867; color: #ffffff;'>$systemdService</div> </td>
														</tr>
													</tbody>
													</table>
												</td>
												</tr>
											</tbody>
											</table>
											<br>
											<p style='font-family: sans-serif; font-size: 14px; font-weight: normal; margin: 0; margin-bottom: 15px;'>Service Description: `systemctl show $systemdService -p Description | cut -d "=" -f2`</p>
											<p style='font-family: sans-serif; font-size: 14px; font-weight: normal; margin: 0; margin-bottom: 15px;'>Event was logged on <b>`date +"%b $d, %Y at %T (%Z)"`</b>.</p>
											<p style='font-family: sans-serif; font-size: 14px; font-weight: normal; margin: 0; margin-bottom: 15px;'>Admin`if [ ${#EMAIL_RECIPIENTS[@]} -gt 1 ]; then echo "s"; fi` has been informed via <b>`echo $messagingService | sed 's/\(.*\),/\1 and/'`</b>.</p>
											<p style='font-family: sans-serif; font-size: 14px; font-weight: normal; margin: 0; margin-bottom: 15px;'><br>Hope to have informed you sufficiently.</p>
										</td>
										</tr>
									</table>
									</td>
								</tr>

								<!-- END MAIN CONTENT AREA -->
								</table>

								<!-- START FOOTER -->
								<div class='footer' style='clear: both; Margin-top: 10px; text-align: center; width: 100%;'>
								<table role='presentation' border='0' cellpadding='0' cellspacing='0' style='border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; min-width: 100%; width: 100%;' width='100%'>
									<tr>
									<td class='content-block powered-by' style='font-family: sans-serif; vertical-align: top; padding-bottom: 10px; padding-top: 10px; color: #9a9ea6; font-size: 12px; text-align: center;' valign='top' align='center'>
										&copy; 2022`if [ $(date +"%Y") -ne 2022 ]; then echo "-"$(date +"%Y"); fi` This automated message was created with <a href="https://github.com/disisto/systemd-status-notifier">systemd status notifier</a>
									</td>
									</tr>
								</table>
								</div>
								<!-- END FOOTER -->

							<!-- END CENTERED WHITE CONTAINER -->
							</div>
							</td>
							<td style='font-family: sans-serif; font-size: 14px; vertical-align: top;' valign='top'>&nbsp;</td>
						</tr>
						</table>
					  </body>
				  </html>"
		) | /usr/sbin/sendmail -t $emailRecipient

    else
		    :
	### For debugging: Console output
	#echo -e "$systemdService...OK"
  
	fi

    ###############################
    ########### SIPGATE ###########
    ###############################

	for smsRecipient in ${SIPGATE_RECIPIENT[@]}; do
		if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "sipgate"); then


			SIPGATE_PAYLOAD="
				{ 
					\"smsId\": \"$SIPGATE_SMSID\", 
					\"recipient\": \"$smsRecipient\", 
					\"message\":  \"$systemdService on `hostname` is DOWN! Admin`if [ ${#EMAIL_RECIPIENTS[@]} -gt 1 ]; then echo "s"; fi` has been informed via `echo $messagingService | sed 's/\(.*\),/\1 and/'`\"
				}
			"

		### Trigger Slack notification
			curl -s \
				-X POST \
				-u $SIPGATE_TOKEN \
				https://api.sipgate.com/v2/sessions/sms \
				-H "Accept: application/json" \
				-H "Content-Type: application/json" \
				-d "$SIPGATE_PAYLOAD"

		fi
	done


    ###############################
    ############ SLACK ############
    ###############################

    SLACK_PAYLOAD="
		{
			\"text\": \":rotating_light: $systemdService on `hostname` is DOWN!\",
			\"blocks\": [
				{
					\"type\": \"header\",
					\"text\": {
						\"type\": \"plain_text\",
						\"text\": \":siren-motion: $systemdService on `hostname` is DOWN!\",
						\"emoji\": true
					}
				},
				{
					\"type\": \"divider\"
				},
				{
					\"type\": \"section\",
					\"fields\": [
						{
							\"type\": \"mrkdwn\",
							\"text\": \"*Monitor:*\nsystemd\"
						},
						{
							\"type\": \"mrkdwn\",
							\"text\": \"*Service Status:*\nDOWN\"
						}
					]
				},
				{
					\"type\": \"divider\"
				},
				{
					\"type\": \"section\",
					\"fields\": [
						{
							\"type\": \"mrkdwn\",
							\"text\": \"*Instance:*\n`hostname`\"
						},
						{
							\"type\": \"mrkdwn\",
							\"text\": \"*Service:*\n$systemdService\"
						}
					]
				},
				{
					\"type\": \"divider\"
				},
				{
					\"type\": \"section\",
					\"text\": {
							\"type\": \"mrkdwn\",
							\"text\": \"*Service Description:*\n`systemctl show $systemdService -p Description | cut -d "=" -f2`\"
						}
				},
				{
					\"type\": \"divider\"
				},
				{
					\"type\": \"section\",
					\"text\": {
							\"type\": \"mrkdwn\",
							\"text\": \"*Notification:*\nAdmin`if [ ${#EMAIL_RECIPIENTS[@]} -gt 1 ]; then echo "s"; fi` has been informed via `echo $messagingService | sed 's/\(.*\),/\1 and/'`\"
						}
				},
				{
					\"type\": \"divider\"
				},
				{
					\"type\": \"context\",
					\"elements\": [
						{
							\"type\": \"mrkdwn\",
							\"text\": \"`date +"%b $d, %Y at %T (%Z)"` | This automated message was created with <https://github.com/disisto/systemd-status-notifier|systemd status notifier>\"
						}
					]
				}
			]
		}
    "

    ### Trigger Slack notification
	if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "slack"); then
      curl -s \
	          -X POST \
			  -H 'Content-type: application/json' \
			  --data "$SLACK_PAYLOAD" \
			  $SLACK_WEBHOOK_URL
	fi

    ###############################
    ########## MATTERMOST #########
    ###############################

    MATTERMOST_PAYLOAD="
		{
			\"text\": \"#### :siren-motion: \`$systemdService\` on `hostname` is DOWN!\n\n| Monitor | Instance | Service | Status |\n|:-----------|:-----------:|:-----------------------------------------------|\n| systemd | `hostname` | $systemdService | DOWN |\n| \n *** \n ###### Service Description: `systemctl show $systemdService -p Description | cut -d "=" -f2` \n *** \n ###### Notification: Admin`if [ ${#EMAIL_RECIPIENTS[@]} -gt 1 ]; then echo "s"; fi` has been informed via `echo $messagingService | sed 's/\(.*\),/\1 and/'` \n *** \n `date +"%b $d, %Y at %T (%Z)"` | This automated message was created with <https://github.com/disisto/systemd-status-notifier|systemd status notifier>\"
		}
    "

	### Trigger Mattermost notification
	if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "mattermost"); then
      curl -s \
	          -X POST \
			  -H 'Content-type: application/json' \
			  -d "$MATTERMOST_PAYLOAD" \
			  $MATTERMOST_WEBHOOK_URL
	fi


    ###############################
    ########## PUSHOVER ###########
    ###############################

	if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "pushover"); then
      curl -s \
			  --form-string "token=$PUSHOVER_TOKEN" \
			  --form-string "user=$PUSHOVER_USER" \
			  --form-string "sound=siren" \
			  --form-string "title=$systemdService on `hostname` is DOWN!" \
			  --form-string "message=Event was logged on `date +"%b $d, %Y at %T (%Z)"`. Admin`if [ ${#EMAIL_RECIPIENTS[@]} -gt 1 ]; then echo "s"; fi` has been informed via `echo $messagingService. | sed 's/\(.*\),/\1 and/'`" \
			  https://api.pushover.net/1/messages.json
	fi

    ###############################
    ########## PAGERDUTY ##########
    ###############################

    ### Trigger PagerDuty notification
	if (printf '%s\n' "${MESSAGING_SERVICES[@]}" | grep -xq "pagerduty"); then
      pd-send -k $PD_SERVICE_KEY \
	          -t trigger \
			  -d "$systemdService on `hostname` is DOWN!" \
			  -i "`hostname`-$systemdService" \
			  -f "Service Description"="`systemctl show $systemdService -p Description | cut -d "=" -f2`" \
			  -f Notification="Admin`if [ ${#EMAIL_RECIPIENTS[@]} -gt 1 ]; then echo "s"; fi` has been informed via `echo $messagingService. | sed 's/\(.*\),/\1 and/'`"
	fi

  fi

done
