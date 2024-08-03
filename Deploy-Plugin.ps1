param(
    [string]$gradlePath,
    [string]$projectDir,
    [string]$buildGradlePath,
    [string]$sshUser,
    [string]$sshServer,
    [string]$remoteCraftyServerPath,
    [string]$remoteServerId,
    [string]$buildLibsPath
)

# example command without actual values:
# powershell -ExecutionPolicy Bypass -File "Deploy-Plugin.ps1" -gradlePath "path\to\gradle.bat" -projectDir "path\to\project" -buildGradlePath "path\to\build.gradle" -sshUser "sshUser" -sshServer "sshServer" -remoteCraftyServerPath "/opt/docker/crafty/servers" -remoteServerId "remoteServerId" -buildLibsPath "path\to\build\libs"

function Detect-GradlePath {
    if (-not $gradlePath) {
        Write-Host "Attempting to auto-detect Gradle path..." -ForegroundColor Cyan
        $gradlePath = Get-Command gradle.bat -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        if (-not $gradlePath) {
            Write-Host "Gradle not found in PATH. Please provide the correct path to gradle.bat." -ForegroundColor Red
            exit 1
        }
        Write-Host "Gradle path auto-detected: $gradlePath" -ForegroundColor Green
    }
}

function Update-Version {
    Write-Host "Updating version in build.gradle..." -ForegroundColor Cyan
    $content = Get-Content $buildGradlePath
    $versionLine = $content | Where-Object { $_ -match "^version\s*=\s*'\d+\.\d+\.\d+-SNAPSHOT'" }
    if ($versionLine) {
        $version = $versionLine -replace "version\s*=\s*'", '' -replace "-SNAPSHOT'", ''
        $parts = $version.Split(".")
        $parts[2] = [int]$parts[2] + 1
        $newVersion = "$($parts[0]).$($parts[1]).$($parts[2])-SNAPSHOT"
        $newContent = $content -replace $versionLine, "version = '$newVersion'"
        Set-Content $buildGradlePath -Value $newContent
        Write-Host "Version updated to $newVersion" -ForegroundColor Green
    } else {
        Write-Host "Version line not found in build.gradle!" -ForegroundColor Red
        exit 1
    }
}

function Build-Gradle {
    Write-Host "Building project with Gradle..." -ForegroundColor Cyan
    Push-Location $projectDir
    & $gradlePath clean build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Gradle build failed!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Write-Host "Gradle build successful." -ForegroundColor Green
    Pop-Location
}

function Establish-SSHConnection {
    Write-Host "Establishing SSH connection to $sshServer..." -ForegroundColor Cyan
    $sshSession = "$sshUser@$sshServer"
    if (!(Test-Path "$env:USERPROFILE\.ssh\known_hosts")) {
        ssh-keyscan -H $sshServer | Add-Content "$env:USERPROFILE\.ssh\known_hosts"
    }
    return $sshSession
}

function Cleanup-OldFiles {
    param (
        [string]$sshSession,
        [string]$remotePath
    )
    Write-Host "Cleaning up old files on remote server..." -ForegroundColor Cyan
    $pluginPath = "$remotePath/plugins"
    $commands = @(
        "rm -rf $pluginPath/*"
    )
    foreach ($command in $commands) {
        Write-Host "Executing: $command" -ForegroundColor Yellow
        $result = ssh $sshSession $command
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to execute command: $command" -ForegroundColor Red
            exit 1
        }
    }
    Write-Host "Old files cleaned up." -ForegroundColor Green
}

function Deploy-NewFiles {
    param (
        [string]$sshSession,
        [string]$localFilePath,
        [string]$remotePath
    )
    Write-Host "Deploying new files to remote server..." -ForegroundColor Cyan
    $scpCommand = "scp `${localFilePath} `${sshSession}:${remotePath}/plugins/"
    Write-Host "Executing: $scpCommand" -ForegroundColor Yellow
    $result = Invoke-Expression $scpCommand
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to deploy new files!" -ForegroundColor Red
        exit 1
    }
    Write-Host "New files deployed." -ForegroundColor Green
}

function Main {
    Detect-GradlePath
    Update-Version
    Build-Gradle
    $sshSession = Establish-SSHConnection
    $remotePath = "$remoteCraftyServerPath/$remoteServerId"
    Cleanup-OldFiles -sshSession $sshSession -remotePath $remotePath
    $latestBuild = Get-ChildItem -Path $buildLibsPath -Filter *.jar | Sort-Object LastWriteTime | Select-Object -Last 1
    if ($latestBuild) {
        Deploy-NewFiles -sshSession $sshSession -localFilePath $latestBuild.FullName -remotePath $remotePath
    } else {
        Write-Host "No build files found in $buildLibsPath!" -ForegroundColor Red
        exit 1
    }

    Write-Host "Deployment complete!" -ForegroundColor Green
}

Main
