$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$script:NodeVersion = "22.23.0"

$script:NodeRoot = Join-Path `
    $env:USERPROFILE `
    "tools\node"

$script:NpmPrefix = Join-Path `
    $env:USERPROFILE `
    "npm"

# ------------------------------------------------------------
# Internal: configure PATH
# ------------------------------------------------------------

function Set-CopilotCliPath {

    $env:PATH = "$script:NodeRoot;$script:NpmPrefix;$env:PATH"
}

# ------------------------------------------------------------
# Install portable Node.js
# ------------------------------------------------------------

function Install-PortableNode {

    [CmdletBinding()]
    param()

    Set-CopilotCliPath

    $nodeExe = Join-Path $script:NodeRoot "node.exe"

    if (Test-Path $nodeExe) {

        Write-Verbose "Node.js already installed."

        & $nodeExe --version

        return
    }

    Write-Host "Installing portable Node.js $script:NodeVersion..."

    New-Item `
        -ItemType Directory `
        -Path $script:NodeRoot `
        -Force | Out-Null

    $zip = Join-Path `
        $env:TEMP `
        "node-v$script:NodeVersion-win-x64.zip"

    $url = `
        "https://nodejs.org/dist/v$script:NodeVersion/node-v$script:NodeVersion-win-x64.zip"

    Write-Host "Downloading Node.js..."

    Invoke-WebRequest `
        -Uri $url `
        -OutFile $zip `
        -UseBasicParsing

    $extract = Join-Path `
        $env:TEMP `
        "node-extract"

    if (Test-Path $extract) {

        Remove-Item `
            $extract `
            -Recurse `
            -Force
    }

    Expand-Archive `
        -Path $zip `
        -DestinationPath $extract `
        -Force

    $source = Join-Path `
        $extract `
        "node-v$script:NodeVersion-win-x64"

    Copy-Item `
        "$source\*" `
        $script:NodeRoot `
        -Recurse `
        -Force

    Remove-Item `
        $extract `
        -Recurse `
        -Force

    Remove-Item `
        $zip `
        -Force

    Set-CopilotCliPath

    Write-Host "Node.js installed."

    & $nodeExe --version
}

# ------------------------------------------------------------
# Install Copilot CLI
# ------------------------------------------------------------

function Install-CopilotCli {

    [CmdletBinding()]
    param()

    Install-PortableNode

    New-Item `
        -ItemType Directory `
        -Path $script:NpmPrefix `
        -Force | Out-Null

    Set-CopilotCliPath

    $npm = Join-Path `
        $script:NodeRoot `
        "npm.cmd"

    Write-Host "Configuring npm prefix..."

    & $npm config set prefix $script:NpmPrefix

    Write-Host "Installing GitHub Copilot CLI..."

    & $npm install -g @github/copilot

    $copilot = Join-Path `
        $script:NpmPrefix `
        "copilot.cmd"

    if (-not (Test-Path $copilot)) {

        throw "Copilot CLI installation failed. $copilot was not found."
    }

    Write-Host "Copilot CLI installed."

    & $copilot --version
}

# ------------------------------------------------------------
# Invoke Copilot CLI
# ------------------------------------------------------------

function Invoke-CopilotCli {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $Prompt,

        # Any additional copilot CLI flags, e.g. --allow-all, --no-ask-user, etc.
        [Parameter(ValueFromRemainingArguments)]
        [string[]]
        $Arguments
    )

    Install-CopilotCli

    Set-CopilotCliPath

    $copilot = Join-Path `
        $script:NpmPrefix `
        "copilot.cmd"

    if (-not (Test-Path $copilot)) {

        throw "Copilot CLI not found."
    }

    Write-Host "Executing Copilot CLI..."

    & $copilot `
        -p $Prompt `
        @Arguments
}

Export-ModuleMember `
    -Function `
        Install-PortableNode,
        Install-CopilotCli,
        Invoke-CopilotCli