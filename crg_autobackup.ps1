<#
Aurthor: Matt Royer
Creation: December 5, 2023


Purpose: Backup the active game data file(s) from CRG with intent to have a backup if CRG decides to shit the bed and currupt the autosave files it has

Reocovery: 
    1) Stop CRG Java Application (scoreboard-Windows.exe)
    2) backup CRG "<working folder\config\autosave\" folder... precaution only
    3) Delete files contents of CRG "<working folder\config\autosave\" folder
    4) Open up deisred *.zip file in backup folder and copy "scoreboard-0-secs-ago.json" to the CRG "<working folder\config\autosave\" folder.
    5) Stop CRG Java Application  (scoreboard-Windows.exe)


#>


#Config Variables
$snapShotInterval = 60     #in seconds on hopw frequently to backup the active game data


#Generate GUID for Tracking Backup Session; used to detect event changes
$activeGameBackupSession = [guid]::NewGuid()


#Location of stuff; may vary from specific CRG Installation
$workingDIR = "C:\Users\Matt\Desktop"     #Working Directories
$scoreboardActiveGameBackupDIR = $workingDIR + "\ScoreboardGameBackup"     #Directory to Backup Active Games Data
$backupLogFile = $scoreboardActiveGameBackupDIR + "\Backup.log"     #Log file for Backup logs
$cRGWorkingDirector = $workingDIR + "\crg-scoreboard_v2023.5"     #CRG directory
$scoreboardActiveGame = $cRGWorkingDirector + "\config\autosave\*.*"     #Location where CRG Active Game Files are stored
$cRGLogFile = $cRGWorkingDirector + "\logs\crg.log"     #CRG Error Log File

#Localization
$newBackupSessionText = "Starting New Backup Session"
$activeGameBackupText = "Active Game Backup"
$crgLogEntryDetectedText = "CRG Log Entry Detected"

cls

New-Item -ItemType Directory -Force -Path $ScoreboardGameBackupDIR | Out-Null    #Create Backup Directory if required

$currentDateTime = Get-Date     #Date / Time for Loggging
$newSessionlogEntry = $newBackupSessionText + " | " + $activeGameBackupSession 
$tempEntry = $currentDateTime.toString() + " | " + $newSessionlogEntry
Write-Host $tempEntry

#Logging it Backup Log
Add-Content -Path $backupLogFile -Value "#################################################################"
Add-Content -Path $backupLogFile -Value $tempEntry

#Stamped in CRG log and is actively monitored as last entry.  If not last entry, CRG generated an error log
Add-Content -Path $cRGLogFile -Value $newSessionlogEntry 

Do {


    #Monitoring for log additions to CRG Log file
    $assesserrorrestart = Get-Content -Path $cRGLogFile -Tail 1

    If ($assesserrorrestart -ne $newSessionlogEntry) { #Checking if deliberate session marker is still the last line in the CRG log file; if No, CRG logged some error or warning... starting new backup session for easier identification for restoration
        $currentDateTime = Get-Date     #Date / Time for Loggging
        $activeGameBackupSession = [guid]::NewGuid()     #Generating new Backup Session GUID

        #Logging Host console, CRG, and backup log that new backup session is being generated
        Write-Warning "$crgLogEntryDetectedText - $newBackupSessionText | $activeGameBackupSession"
        $newSessionlogEntry = $newBackupSessionText + " | " + $activeGameBackupSession
        $tempEntry = $currentDateTime.toString() + " | " + $newSessionlogEntry
        Add-Content -Path $backupLogFile -Value $tempEntry
        Add-Content -Path $cRGLogFile -Value $newSessionlogEntry

    } 

    $currentDateTime = Get-Date     #Date / Time for Loggging
    $backupFileName = "\ActiveGameBackup-" + $currentDateTime.ToString("yyyyMMdd_HHmmss") + ".zip"     #Generating unique backup file name
    $scoreboardGameDataBackup = $scoreboardActiveGameBackupDIR + $backupFileName     #Generating destination of backup file
    Compress-Archive -Path $scoreboardActiveGame -DestinationPath $scoreboardGameDataBackup -Force      #Zipping content up of active CRG game files
    #Logging Backup
    $actionLog = $currentDateTime.ToString() + " | " + $activeGameBackupText + " | " + $scoreboardGameDataBackup
    Write-Host $actionLog
    Add-Content -Path $backupLogFile -Value $actionLog

    #Sleep based on configured interval
    Start-Sleep -seconds $snapShotInterval 

} While ($true)
