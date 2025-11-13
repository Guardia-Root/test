' Downloads a GitHub repo ZIP (no git required) and encrypts the "Docs" folder on the Desktop
' - Configure repoOwner/repoName/branch and password below
' - Writes a PowerShell script and runs it (avoids complex quoting in VBS)
Option Explicit

Dim WshShell, FSO
Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' ====== CONFIG ======
Dim repoOwner, repoName, branch, githubBaseUrl, repoZipUrl
repoOwner = "Guardia-Root"      ' <-- change if needed
repoName  = "test"               ' <-- change if needed
branch    = "main"               ' <-- change if needed (main or master)

Dim password
password = "SecureVM2025!"       ' <-- ASSIGNEZ ICI LE MOT DE PASSE DE CHIFFREMENT

' ====== PATHS ======
Dim userProfile, desktopPath, outilsFolder, psScriptPath
userProfile = WshShell.ExpandEnvironmentStrings("%USERPROFILE%")
desktopPath = WshShell.SpecialFolders("Desktop")
outilsFolder = userProfile & "\Outils"
psScriptPath = outilsFolder & "\chiffrer_repo_and_docs.ps1"

' Create Outils folder if needed
If Not FSO.FolderExists(outilsFolder) Then
    FSO.CreateFolder(outilsFolder)
End If

' Build GitHub ZIP URL (downloads branch archive)
githubBaseUrl = "https://github.com"
repoZipUrl = githubBaseUrl & "/" & repoOwner & "/" & repoName & "/archive/refs/heads/" & branch & ".zip"

' ====== PowerShell script content ======
Dim psContent
psContent = ""
psContent = psContent & "$ErrorActionPreference = 'Stop'" & vbCrLf
psContent = psContent & "$ProgressPreference = 'SilentlyContinue'" & vbCrLf
psContent = psContent & "$repoZipUrl = '" & repoZipUrl & "'" & vbCrLf
psContent = psContent & "$tools = Join-Path $env:USERPROFILE 'Outils'" & vbCrLf
psContent = psContent & "$tempZip = Join-Path $env:TEMP 'repo_download.zip'" & vbCrLf
psContent = psContent & "$extractPath = Join-Path $tools 'repo'" & vbCrLf
psContent = psContent & "$desktop = [Environment]::GetFolderPath('Desktop')" & vbCrLf
psContent = psContent & "$docs = Join-Path $desktop 'Docs'" & vbCrLf
psContent = psContent & "$sevenZipExe = Join-Path $tools '7z\\7za.exe'" & vbCrLf
psContent = psContent & "$sevenZipArchiveUrl = 'https://www.7-zip.org/a/7za920.zip'" & vbCrLf
psContent = psContent & "$pwd = '" & Replace(password, "'", "''") & "'" & vbCrLf
psContent = psContent & "" & vbCrLf

psContent = psContent & "function Log($m) {" & vbCrLf
psContent = psContent & "  $log = Join-Path $desktop 'chiffrement_log.txt'" & vbCrLf
psContent = psContent & "  Add-Content -Path $log -Value (('[' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + '] ' + $m))" & vbCrLf
psContent = psContent & "}" & vbCrLf
psContent = psContent & "" & vbCrLf

psContent = psContent & "try {" & vbCrLf
psContent = psContent & "  Log 'Début du script: téléchargement du repo " & repoOwner & "/" & repoName & "'" & vbCrLf
psContent = psContent & "  if (-not (Test-Path $tools)) { New-Item -ItemType Directory -Path $tools -Force | Out-Null }" & vbCrLf
psContent = psContent & "  Log ('Téléchargement: ' + $repoZipUrl)" & vbCrLf
psContent = psContent & "  Invoke-WebRequest -Uri $repoZipUrl -OutFile $tempZip -UseBasicParsing -ErrorAction Stop" & vbCrLf
psContent = psContent & "  if (Test-Path $extractPath) { Remove-Item -Recurse -Force -Path $extractPath -ErrorAction SilentlyContinue }" & vbCrLf
psContent = psContent & "  Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force" & vbCrLf
psContent = psContent & "  Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue" & vbCrLf
psContent = psContent & "  Log 'Repo extrait dans: ' + $extractPath" & vbCrLf
psContent = psContent & "  if (-not (Test-Path $docs)) { Log 'ERREUR: dossier Docs introuvable: ' + $docs; exit 2 }" & vbCrLf
psContent = psContent & "  Log 'Dossier Docs trouvé: ' + $docs" & vbCrLf
psContent = psContent & "  if (-not (Test-Path $sevenZipExe)) {" & vbCrLf
psContent = psContent & "    Log '7za introuvable, téléchargement de 7za...'" & vbCrLf
psContent = psContent & "    $zzip = Join-Path $env:TEMP '7za.zip'" & vbCrLf
psContent = psContent & "    Invoke-WebRequest -Uri $sevenZipArchiveUrl -OutFile $zzip -UseBasicParsing -ErrorAction Stop" & vbCrLf
psContent = psContent & "    $sevenFolder = Join-Path $tools '7z'" & vbCrLf
psContent = psContent & "    if (-not (Test-Path $sevenFolder)) { New-Item -ItemType Directory -Path $sevenFolder -Force | Out-Null }" & vbCrLf
psContent = psContent & "    try { Expand-Archive -Path $zzip -DestinationPath $sevenFolder -Force } catch { Log 'Expand-Archive failed: ' + $_.Exception.Message }" & vbCrLf
psContent = psContent & "    Remove-Item -Path $zzip -Force -ErrorAction SilentlyContinue" & vbCrLf
psContent = psContent & "    $found = Get-ChildItem -Path $sevenFolder -Recurse -Filter '7za.exe' -ErrorAction SilentlyContinue | Select-Object -First 1" & vbCrLf
psContent = psContent & "    if ($found) { $sevenZipExe = $found.FullName; Log '7za trouvé: ' + $sevenZipExe } else { Log 'ERREUR: 7za non trouvé après extraction'; exit 3 }" & vbCrLf
psContent = psContent & "  } else { Log '7za déjà présent: ' + $sevenZipExe }" & vbCrLf
psContent = psContent & "  $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'" & vbCrLf
psContent = psContent & "  $outArchive = Join-Path $desktop ('Docs_Encrypted_' + $timestamp + '.7z')" & vbCrLf
psContent = psContent & "  Log ('Chiffrement: création de ' + $outArchive)" & vbCrLf
psContent = psContent & "  $args = @('a','-t7z','-mx=9','-mhe=on', ('-p' + $pwd), $outArchive, (Join-Path $docs '*'))" & vbCrLf
psContent = psContent & "  & $sevenZipExe $args" & vbCrLf
psContent = psContent & "  if (Test-Path $outArchive) { Log 'Archive créée: ' + $outArchive } else { Log 'ERREUR: archive non créée'; exit 4 }" & vbCrLf
psContent = psContent & "  Log 'Fin du script avec succès.'" & vbCrLf
psContent = psContent & "  exit 0" & vbCrLf
psContent = psContent & "} catch {" & vbCrLf
psContent = psContent & "  Log 'Exception: ' + $_.Exception.Message" & vbCrLf
psContent = psContent & "  exit 1" & vbCrLf
psContent = psContent & "}" & vbCrLf

' ====== Write PS1 to disk ======
Dim psFile
Set psFile = FSO.CreateTextFile(psScriptPath, True)
psFile.Write psContent
psFile.Close

' ====== Execute PowerShell script hidden and wait ======
Dim ret, cmd
cmd = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & psScriptPath & """"
ret = WshShell.Run(cmd, 0, True)  ' wait for completion

' ====== Clean up PS1 (optional) ======
On Error Resume Next
If FSO.FileExists(psScriptPath) Then FSO.DeleteFile(psScriptPath)
On Error GoTo 0

' ====== Notify user ======
If ret = 0 Then
    MsgBox "✅ Opération terminée. Vérifiez le fichier chiffré sur le bureau et le log (chiffrement_log.txt).", vbInformation, "Terminé"
Else
    MsgBox "❌ Le script a rencontré une erreur (code " & ret & "). Consultez 'chiffrement_log.txt' sur le bureau pour les détails.", vbCritical, "Erreur"
End If
