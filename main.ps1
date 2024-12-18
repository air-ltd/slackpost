#######################################################################
#
#   FileName:   main.ps1
#   Author:     Jared Church
#
#   Purpose:
#       Gets details of url to logs and posts a message on slack
#       with link to logs. Message is controlled through command line
#       args
#
#   Future Development:
#       Turn this into a reusable action - need to learn how to do
#       that.
#
#######################################################################
# $DebugPreference='SilentlyContinue'
$DebugPreference='Continue'
write-debug "Content File: $($env:INPUT_CONTENT_FILE)"
write-debug "Content: $($env:INPUT_CONTENT)"

$message="$($env:INPUT_CONTENT)"
$slackUrl=$env:INPUT_SLACKURL
$env:GH_TOKEN=$env:INPUT_GH_TOKEN

dir $env:INPUT_CONTENT_FILE
if ( Test-Path $env:INPUT_CONTENT_FILE ) {
    if ( $message -ne "" ) {
        $message+="`n"
    }
    $message+=(get-content -raw $($env:INPUT_CONTENT_FILE))
}


write-debug "Final Message: $($message)" -Debug

############### VARIABLES ###############
$urlTemplateRawLogs="https://github.com/{0}/commit/{1}/checks/{2}/logs"
$urlTemplateLogs="https://github.com/{0}/actions/runs/{1}/job/{2}"

############### FUNCTIONS ###############

. $PSScriptRoot/Send-SlackMessage.ps1

# Gets the job id using github command line
function get-jobId() {
    param (
        $runId,
        $jobNumber=0,
        $repo
    )

    write-debug "Repo: $($repo)"
    write-debug "Run ID: $($runId)"

    # Collect job definitions - this is the only
    # method I've found that works on both self-hosted
    # and github-hosted runners
    $headerAccept="Accept: application/vnd.github+json"
    $headerAPIVersion="X-GitHub-Api-Version: 2022-11-28"
    $path=("/repos/{0}/actions/runs/{1}/jobs" -f $repo,$runId)
    $jobInfo=(gh api -H $headerAccept -H $headerAPIVersion $path)

    write-debug $jobInfo
    $jobId=($jobInfo | convertfrom-json).jobs[$jobNumber].id

    write-debug "Job ID: $($jobId)"

    return $jobId
}

############### SCRIPT ###############

$githubContext = $env:INPUT_GITHUB_CONTEXT | ConvertFrom-Json

### Get Job ID
$jobId=get-jobId -runId $githubContext.run_id -repo $githubContext.repository

# Build Slack Message Content
$actionName="$($githubContext.workflow) #$($githubContext.run_number)/$($githubContext.job)"
$url=($urlTemplateRawLogs -f $githubContext.repository,$githubContext.sha,$jobId)
$url2=($urlTemplateLogs -f $githubContext.repository,$githubContext.run_id,$jobId)

write-output "Raw Logs: $($url)"
write-output "HTML Logs: $($url2)"

$jsonMessage=write-SlackMessageBody -logUrl $url -logUrlHtml $url2 -ActionName $actionName -Message $message

if ( $env:INPUT_TESTMODE ) {
    $jsonMessage
} else {
    write-output "INPUT_TESTMODE is set"
    $jsonMessage
    send-SlackMessage -jsonMessage $jsonMessage -slackUrl $slackUrl
}



### End of File
