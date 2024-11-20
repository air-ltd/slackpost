function send-SlackMessage() {
    param (
        $slackUrl,
        $jsonMessage
    )

    $HEADER=@{
        "Content-type"="application/json"
    }

    write-host $jsonMessage

    $res=invoke-webrequest -method post -Headers $HEADER -Body $jsonMessage -Uri $slackUrl
    if ( $res.StatusCode -ne 200 ) {
        throw "Slack Post Failed"
        $res
    } else {
        write-output "Slack Post Succeeded"
    }
}


function write-SlackMessageBody() {
    param (
        $ActionName,
        $Message,
        $logUrl,
        $logUrlHtml
    )

    $MessageLimit=$Message.Substring(0, [Math]::Min(3000, $Message.Length))

    $BODY=@{
        "blocks"=@(
            @{
                "type"="section"
                "text"=@{
                    "type"="mrkdwn"
                    "text"="$($ActionName)"
                }
            },
            @{ "type"="divider"},
            @{
                "type"="section"
                "text"=@{
                    "type"="mrkdwn"
                    "text"="$($MessageLimit)"
                }
            },
            @{ "type"="divider"},
            @{
                "type"="section"
                "text"=@{
                    "type"="mrkdwn"
                    "text"="<$($logUrl)|Log Raw>`n<$($logUrlHtml)|Log HTML>"
                }
            }
        )
    }

    return ($BODY | convertto-json -Depth 100)
}