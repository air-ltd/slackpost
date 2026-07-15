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
        $res
        throw "Slack Post Failed"
    } else {
        write-output "Slack Post Succeeded"
    }
}


function split-message() {
    param (
        $inputString,
        $substringLength=3000
    )

    # Initialize an empty array to hold the substrings
    $outputArray = @()

    # Loop through the string in increments of 30 characters
    for ($i = 0; $i -lt $inputString.Length; $i += $substringLength) {
        # Extract a substring of 30 characters
        $substring = $inputString.Substring($i, [Math]::Min($substringLength, $inputString.Length - $i))
        # Add the substring to the array
        $outputArray += $substring
    }

    # Output the array
    return $outputArray

}

function write-SlackMessageBody() {
    param (
        $ActionName,
        $Message,
        $logUrl,
        $logUrlHtml
    )


    $messageList=split-message -inputString $Message

    $messageObject=@()
    $messageList | foreach {
        $messageObject+=@{
                "type"="section"
                "text"=@{
                    "type"="mrkdwn"
                    "text"="$($_)"
                }

        }
    }


    $blocks=$(
        @{
            "type"="section"
            "text"=@{
                "type"="mrkdwn"
                "text"="$($ActionName)"
            }
        },
        @{ "type"="divider"}
    )

    $blocks+=$messageObject
    $blocks+=$(
        @{ "type"="divider"},
        @{
            "type"="section"
            "text"=@{
                "type"="mrkdwn"
                "text"="<$($logUrl)|Log Raw>`n<$($logUrlHtml)|Log HTML>"
            }
        }
    )

    $BODY=@{
        "blocks"=$blocks
    }

    return ($BODY | convertto-json -Depth 100)
}