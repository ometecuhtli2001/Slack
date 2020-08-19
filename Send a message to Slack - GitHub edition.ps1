# Send an alert to Slack using PowerShell

# Returns:
#   Success - ok
#   Error - either an HTTP response code or -1 if one could not be extracted
function Send-SlackMessage{
    Param(
    [string]$SlackChannelUri="",
    [string]$ChannelName,
    [string]$Message,
    [string]$Emoji=":ghost:",
    [string]$Username=""
    )

    $reply=""

    $Body = @"
    {
        "channel": "$ChannelName",
        "username": "$Username",
        "text": "$Message",
        "icon_emoji":"$Emoji"
    }
"@
    try {
        if($PSVersionTable.PSVersion.Major -lt 3){ 
            $client = New-Object "System.Net.WebClient"
            $reply = $client.UploadString($SlackChannelUri, $Body)
        } else {
            $reply=Invoke-RestMethod -uri $SlackChannelUri -Method Post -body $body -ContentType 'application/json'
        } # if..else: PS version
    }
    catch {
        $gotcode=$_ -match "The remote server returned an error: \((\d+)\)"
        if($gotcode){
            $reply=$Matches[1]
        } else {
            $reply=-1 # Generic error indicator
        } # if..else: is there an HTTP code to extract?
    }
    return $reply
} # Send-SlackMessage

$now=get-date -Format "MM/dd/yyyy HH:mm:ss"
Send-SlackMessage -SlackChannelUri "https://hooks.slack.com/services/foo/bar/baz" -ChannelName "#testing" -Message "The time is $now"

