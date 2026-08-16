# Deploy the site to `main` as a SINGLE squashed commit.
#
# Why: play/ weighs ~34 MB. Committing it normally would leave a permanent
# blob in history on every rebuild and the repo would keep growing.
# This rebuilds the branch from scratch and force-pushes, so history is
# always exactly one commit and repo size stays flat.
#
# GitHub Pages must be: Settings -> Pages -> Deploy from a branch -> main / root
#
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File .\deploy.ps1

$ErrorActionPreference = 'Stop'
$repo   = Split-Path -Parent $MyInvocation.MyCommand.Path
$branch = 'main'
$remote = (git -C $repo remote get-url origin)

# what actually gets served + the sources worth keeping in the repo
$payload = @(
    'index.html', 'cv.html', 'playables.json', 'i18n.js', '.nojekyll',
    'README.md', 'deploy.ps1', 'shots', 'play'
)

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ghp_" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    foreach ($p in $payload) {
        $src = Join-Path $repo $p
        if (-not (Test-Path $src)) { Write-Warning "missing: $p"; continue }
        Copy-Item $src -Destination $tmp -Recurse -Force
    }
    # hardened builds must not be touched by line-ending normalisation
    @('play/** -text', '*.pak binary', '*.jpg binary') |
        Set-Content (Join-Path $tmp '.gitattributes') -Encoding ascii

    Push-Location $tmp
    git init -q -b $branch
    git config user.name  'Vitaliy Stetsuik'
    git config user.email 'vistet1428@gmail.com'
    git add -A
    git -c core.autocrlf=false commit -q -m "site: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git remote add origin $remote
    $env:GIT_SSH_COMMAND = 'ssh -o BatchMode=yes -o ConnectTimeout=25'
    git push -q --force origin $branch
    Pop-Location

    $files = Get-ChildItem $tmp -Recurse -File | Where-Object { $_.FullName -notmatch '\\\.git\\' }
    $mb = [math]::Round(($files | Measure-Object Length -Sum).Sum / 1MB, 1)
    Write-Host "$branch : $($files.Count) files, $mb MB, 1 commit (forced)"
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
