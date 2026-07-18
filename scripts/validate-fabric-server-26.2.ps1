param(
    [Parameter(Mandatory = $true)]
    [string] $ServerDirectory,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 99)]
    [int] $Pass,

    [ValidateRange(30, 600)]
    [int] $StartupTimeoutSeconds = 120,

    [ValidateRange(10, 180)]
    [int] $ShutdownTimeoutSeconds = 60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$server = (Resolve-Path -LiteralPath $ServerDirectory).Path
if ((Split-Path -Leaf $server) -notlike "wthit-fabric-26.2-test-*") {
    throw "Refusing to run outside a WTHIT 26.2 isolation directory: $server"
}

$launcherName = "fabric-server-mc.26.2-loader.0.19.3-launcher.1.1.1.jar"
$launcher = Join-Path $server $launcherName
if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) {
    throw "Missing Fabric launcher: $launcher"
}

$stdoutPath = Join-Path $server "wthit-pass$Pass.stdout.log"
$stderrPath = Join-Path $server "wthit-pass$Pass.stderr.log"
$latestLog = Join-Path $server "logs\latest.log"
if (Test-Path -LiteralPath $latestLog -PathType Leaf) {
    $archivedLatestLog = Join-Path $server "logs\before-wthit-pass$Pass-latest.log"
    if (Test-Path -LiteralPath $archivedLatestLog) {
        throw "Refusing to overwrite an existing validation log: $archivedLatestLog"
    }
    Move-Item -LiteralPath $latestLog -Destination $archivedLatestLog
}

$startInfo = [Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = (Get-Command java).Source
$startInfo.WorkingDirectory = $server
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.RedirectStandardInput = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
foreach ($argument in @("-Xms1G", "-Xmx4G", "-jar", $launcherName, "nogui")) {
    [void] $startInfo.ArgumentList.Add($argument)
}

$serverProcess = [Diagnostics.Process]::new()
$serverProcess.StartInfo = $startInfo
$stdoutTask = $null
$stderrTask = $null
$stdout = ""
$stderr = ""
$done = $false
$forced = $false

try {
    if (-not $serverProcess.Start()) {
        throw "Fabric server process did not start"
    }

    $stdoutTask = $serverProcess.StandardOutput.ReadToEndAsync()
    $stderrTask = $serverProcess.StandardError.ReadToEndAsync()
    $startupDeadline = [DateTime]::UtcNow.AddSeconds($StartupTimeoutSeconds)

    while (-not $done -and -not $serverProcess.HasExited -and [DateTime]::UtcNow -lt $startupDeadline) {
        if (Test-Path -LiteralPath $latestLog -PathType Leaf) {
            try {
                $done = (Get-Content -Raw -LiteralPath $latestLog).Contains("Done (")
            } catch [IO.IOException] {
                # The logger may briefly rotate or hold the file between reads.
            }
        }

        if (-not $done) {
            Start-Sleep -Milliseconds 250
        }
    }

    if (-not $done) {
        throw "Server did not reach Done within $StartupTimeoutSeconds seconds"
    }

    foreach ($command in @("waila plugin list", "waila dump", "save-all flush")) {
        $serverProcess.StandardInput.WriteLine($command)
        $serverProcess.StandardInput.Flush()
        Start-Sleep -Milliseconds 750
    }

    $serverProcess.StandardInput.WriteLine("stop")
    $serverProcess.StandardInput.Flush()
    $serverProcess.StandardInput.Close()

    if (-not $serverProcess.WaitForExit($ShutdownTimeoutSeconds * 1000)) {
        throw "Server did not stop within $ShutdownTimeoutSeconds seconds"
    }
} finally {
    if ($serverProcess.Id -ne 0 -and -not $serverProcess.HasExited) {
        try {
            $serverProcess.StandardInput.WriteLine("stop")
            $serverProcess.StandardInput.Flush()
        } catch {
            # The process may have already closed its standard input.
        }

        if (-not $serverProcess.WaitForExit(15000)) {
            $serverProcess.Kill($true)
            $serverProcess.WaitForExit()
            $forced = $true
        }
    }

    if ($null -ne $stdoutTask) {
        $stdout = $stdoutTask.Result
    }
    if ($null -ne $stderrTask) {
        $stderr = $stderrTask.Result
    }

    [IO.File]::WriteAllText($stdoutPath, $stdout)
    [IO.File]::WriteAllText($stderrPath, $stderr)
}

$exitCode = $serverProcess.ExitCode
$doneCount = [regex]::Matches($stdout, "Done \(").Count
$cleanStop = $stdout.Contains("Stopping server") -and $stdout.Contains("All dimensions are saved")
$runtimeFailures = [regex]::Matches(
    $stdout + "`n" + $stderr,
    "Mixin Apply Error|Mixin apply failed|ClassNotFoundException|NoClassDefFoundError|NoSuchMethodError|Could not execute entrypoint|/ERROR\]"
).Count

"PASS=$Pass"
"PID=$($serverProcess.Id)"
"EXIT=$exitCode"
"DONE_COUNT=$doneCount"
"CLEAN_STOP=$cleanStop"
"FORCED=$forced"
"RUNTIME_FAILURE_MATCHES=$runtimeFailures"
"STDOUT=$stdoutPath"
"STDERR=$stderrPath"

$stdout -split "`r?`n" |
    Select-String -Pattern "waila|wthit|badpackets|server_dump|plugin|Stopping server|All dimensions are saved" -CaseSensitive:$false |
    Select-Object -Last 40

if ($exitCode -ne 0 -or $doneCount -ne 1 -or -not $cleanStop -or $forced -or $runtimeFailures -ne 0) {
    throw "Fabric server validation pass $Pass failed its exit/startup/shutdown/runtime checks"
}
