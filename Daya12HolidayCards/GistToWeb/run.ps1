using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$GistID = $Request.Query.GistID

if ([string]::IsNullOrEmpty($GistID)) {
    $status = [HttpStatusCode]::BadRequest
    $body = "Please provide a GistID"
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = $status
            Body       = $body
        })
    Exit
}

# Get the gistfiles
$Result = Invoke-Restmethod -Method GET -Uri "https://api.Github.com/gists/$GistID"


$FileNames = $result.files | Get-Member -MemberType NoteProperty
if ($FileNames.Count -gt 1) {
    Write-Output "More than one file in Gist, creating ArrayList"
    [System.Collections.ArrayList]$AllFiles = @()
}
foreach ($File in $FileNames) {
    if ($Result.files.($File.Name).Language -eq "MarkDown") {
        $RawURL = $Result.files.($File.Name).raw_url


        $MDGist = Invoke-RestMethod -Method GET -Uri $RawURL
        $Body = @{
            "text" = $MDGist
            "mode" = "markdown"

        }
        # Get output from the Github API
        $response = Invoke-WebRequest -Method Post -Uri "https://api.github.com/markdown" -Body ($body | ConvertTo-Json)

        write-output "MDGIst $MDGist"
        Write-Output "HTML $HTML"
        $HTMLFile = $response.Content

        if ($FileNames.Count -gt 1) {
            $AllFiles.Add($HTMLFile)
        }
    }
    else {
        Write-Output "$($File.Name) is not a MarkdownFile."
    }
}
if ($AllFiles.Count -gt 0) {
    $Status = [HttpStatusCode]::OK
    $Body = $AllFiles -join ""
}
Elseif ($HTMLFile) {
    $Status = [HttpStatusCode]::OK
    $Body = $HTMLFile
}
Else {
    $status = [HttpStatusCode]::BadRequest
    $body = "File $($File.Name) is not a MarkDownFile."
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = $status
            Body       = $body
        })
    Exit
}

If ($Request.Query.Raw) {
    $ContentType = "text/plain"
}
else {
    $ContentType = "text/html"
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode  = $status
        ContentType = $ContentType
        Body        = $body
    })
