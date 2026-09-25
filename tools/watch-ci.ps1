param([string]$Sha = "b0331d6")

# Polls the branch build for a given commit. Unauthenticated GitHub API is
# capped at 60 requests/hour per IP, so this deliberately checks every three
# minutes and no faster — a tighter loop exhausts the quota mid-build and
# then reports failures that are really 403s.
$h = @{ "User-Agent" = "watch-ci" }
$repo = "dev-banik/VoiceCraft-AI"
$deadline = (Get-Date).AddMinutes(40)

while ((Get-Date) -lt $deadline) {
    try {
        $run = (Invoke-RestMethod "https://api.github.com/repos/$repo/actions/runs?branch=main&per_page=3" -Headers $h).workflow_runs |
               Where-Object { $_.head_sha -like "$Sha*" } | Select-Object -First 1
        if ($run -and $run.status -eq "completed") {
            "CONCLUSION: $($run.conclusion)"
            "URL: $($run.html_url)"
            if ($run.conclusion -ne "success") {
                $jobs = (Invoke-RestMethod $run.jobs_url -Headers $h).jobs
                foreach ($j in $jobs) {
                    foreach ($s in $j.steps) {
                        if ($s.conclusion -eq "failure") { "FAILED STEP: $($j.name) / $($s.name)" }
                    }
                }
            }
            exit 0
        }
        "$((Get-Date).ToString('HH:mm:ss')) - $(if ($run) { $run.status } else { 'run not visible yet' })"
    } catch {
        "$((Get-Date).ToString('HH:mm:ss')) - poll failed (likely rate limit); backing off"
    }
    Start-Sleep -Seconds 180
}
"TIMED OUT"
exit 1
