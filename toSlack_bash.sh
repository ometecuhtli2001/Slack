#!/bin/bash

# Send a message to Slack

# Return codes:
# 0 - user asked for help (-h argument on command line)
# 1 - missing a required parameter
# 123 - a test error code if the -E parameter specified, otherwise a legit error code
# 200 - message sent to Slack without errors
# anything else - an error occurred!

function usage {
    programName=$0
    echo "description: use this program to post messages to a Slack channel"
    echo "usage: $programName [-t \"sample title\"] [-b \"message body\"] [-c \"mychannel\"] [-u \"slack url\"]"
    echo "    REQUIRED:"
    echo "    -b    The message body"
    echo "    -c    The channel you are posting to (but see -A below)"
    echo "    -t    the title of the message you are posting"
    echo "    -u    The slack hook url to post to (but see -A below)"
    echo 
    echo "    OPTIONAL:"
    echo "    -e    The slack emoji code to use; if not specified, defaults to :robot_face: because the message will probably be coming from a robot"
    echo "    -h    This help message."
    echo "    -A    Send to the #alerts channel. If this is specified, -c and -u are not required; the emoji is overidden to :scream: and the border color is changed to red because, well, it's an alert!"
    echo "    -E    Simulate an error by returning exit code 123 - this is useful for testing scripts which call this script."
    echo "    -C    The color of the left border of the message, can be formatted as an HTML code; defaults to 'good' which is green"
    echo "    -T    Testing mode: the request is not actually sent to Slack, and the JSON which would be sent is output to STDOUT"
    echo "    -U    The username from whom the message is sent, defaults to the hostname of the sender (in this case ${HOSTNAME}).  Subsequent messages in Slack are indented under this username and ordered chronologically."
}

# Set default values
isTesting="0"
emojiCode=":robot_face:"
username=$(hostname)
borderColor="good"
URLalerts="Txxxxxxxx/Bxxxxxxxx/Exxxxxxxxxxxxxxxxxxxxxxx"
# #00cc00 is (more or less) the equivalend of "good"

while getopts ":t:b:c:u:e:U:C:EhAT" opt; do
	case ${opt} in
		t) msgTitle="$OPTARG"
		;;
		u) slackUrl="$OPTARG"
		;;
		b) msgBody="$OPTARG"
		;;
		c) channelName="$OPTARG"
		;;
		e) emojiCode="$OPTARG"
		;;
		U) username="$OPTARG"
		;;
		C) borderColor="$OPTARG"
		;;
		A)	channelName='alerts'
			emojiCode=":scream:"
			borderColor="#AA0000"
			slackUrl="https://hooks.slack.com/services/$URLalerts"
		;;
		T) isTesting="1"
		;;
		h)	usage
			exit 0
		;;
		E) exit 123
		;;
		\?) echo "Invalid option -$OPTARG" >&2
		;;
	esac
done

if [ $isTesting = "1" ]; then
	echo "Test mode: $isTesting"
	echo "Title: ${msgTitle}"
	echo "URL: ${slackUrl}"
	echo "Body: ${msgBody}"
	echo "Channel: ${channelName}"
	echo
	echo
fi

if [ ! "${msgTitle}" ]; then
	echo "Missing title"
fi

if [ ! "${slackUrl}" ]; then
	echo "Missing Slack URL"
fi
if [ ! "${msgBody}" ]; then
	echo "Missing message body"
fi
if [ ! "${channelName}" ]; then
	echo "Missing channel name"
fi


if [[ ! "${msgTitle}" ||  ! "${slackUrl}" || ! "${msgBody}" || ! "${channelName}" ]]; then
    echo "Missing required arguments"
    usage
    exit 1
fi

read -d '' payLoad << EOF
{
        "channel": "#${channelName}",
        "username": "$username",
        "icon_emoji": "$emojiCode",
        "attachments": [
            {
                "fallback": "${msgTitle}",
		"color":"$borderColor",
                "title": "${msgTitle}",
                "fields": [{
                    "title": "message",
                    "value": "${msgBody}",
                    "short": false
                }]
            }
        ]
    }
EOF

if [ $isTesting = "1" ]; then
	echo "${payLoad}"
	echo 
fi
	
if [ $isTesting = "0" ]; then
	statusCode=$(curl \
		--write-out %{http_code} \
		--silent \
		--output /dev/null \
		-X POST \
		-H 'Content-type: application/json' \
		--data "${payLoad}" ${slackUrl})
fi

echo ${statusCode}

exit ${statusCode}
