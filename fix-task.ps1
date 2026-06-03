# Fix the scheduled task for boot-time migration
$taskName = "AppDataMigrationFinisher"
$bootScriptPath = "F:\APPDATA\boot-finish.ps1"

# Remove broken task if exists
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

# Create trigger: at system startup
$trigger = New-ScheduledTaskTrigger -AtStartup

# Create action
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$bootScriptPath`""

# Create principal (SYSTEM)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Compatibility Win8

# Register
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force

Write-Host "Task registered. Verifying..."
Get-ScheduledTask -TaskName $taskName | Format-List TaskName, State, Triggers

Write-Host ""
Write-Host "Boot script contents:"
Get-Content $bootScriptPath

Write-Host ""
Write-Host "=== Current Junction Summary ==="
Write-Host "--- Local ---"
cmd /c "dir /AL `"C:\Users\lenovo\AppData\Local`"" 2>$null
Write-Host "--- LocalLow ---"
cmd /c "dir /AL `"C:\Users\lenovo\AppData\LocalLow`"" 2>$null
Write-Host "--- Roaming ---"
cmd /c "dir /AL `"C:\Users\lenovo\AppData\Roaming`"" 2>$null
Write-Host "--- Roaming\Tencent ---"
cmd /c "dir /AL `"C:\Users\lenovo\AppData\Roaming\Tencent`"" 2>$null
Write-Host "--- User Root ---"
cmd /c "dir /AL `"C:\Users\lenovo`"" 2>$null
Write-Host "Done!"
