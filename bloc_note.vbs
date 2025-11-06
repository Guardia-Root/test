Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' ===== CONFIGURATION =====
desktopPath = WshShell.SpecialFolders("Desktop")
dossierDoc = desktopPath & "\Doc"
userProfile = WshShell.ExpandEnvironmentStrings("%USERPROFILE%")
computerName = WshShell.ExpandEnvironmentStrings("%COMPUTERNAME%")
userName = WshShell.ExpandEnvironmentStrings("%USERNAME%")

' Mot de passe (à récupérer depuis le serveur ou hardcodé)
motDePasse = "SecureVM2025!#" & computerName  ' Mot de passe unique par VM

' Nom du fichier chiffré
timestamp = Year(Now) & Right("0" & Month(Now), 2) & Right("0" & Day(Now), 2) & "_" & _
            Right("0" & Hour(Now), 2) & Right("0" & Minute(Now), 2)
outputZip = desktopPath & "\Doc_Secure_" & computerName & "_" & timestamp & ".7z"

' Vérifier que le dossier Doc existe
If Not FSO.FolderExists(dossierDoc) Then
    Set logFile = FSO.CreateTextFile(desktopPath & "\ERREUR_CHIFFREMENT.txt", True)
    logFile.WriteLine "ERREUR: Dossier 'Doc' introuvable"
    logFile.WriteLine "Date: " & Now()
    logFile.WriteLine "Chemin attendu: " & dossierDoc
    logFile.Close
    WScript.Quit
End If

' Script PowerShell complet
cmd = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command " & _
"$ErrorActionPreference='SilentlyContinue';" & _
"$doc='" & dossierDoc & "';" & _
"$zip='" & outputZip & "';" & _
"$pwd='" & motDePasse & "';" & _
"$pc='" & computerName & "';" & _
"$user='" & userName & "';" & _
"$7zPath=$env:USERPROFILE+'\Outils\7z\7za.exe';" & _
"$7zUrl='https://www.7-zip.org/a/7za920.zip';" & _
"" & _
"# Fonction de log" & _
"function Log($msg){" & _
"  $logPath=$env:USERPROFILE+'\Desktop\chiffrement_log.txt';" & _
"  Add-Content $logPath \"\"[$(Get-Date -f 'yyyy-MM-dd HH:mm:ss')] $msg\"\"" & _
"};" & _
"" & _
"Log 'Début du chiffrement';" & _
"Log ('Dossier source: '+$doc);" & _
"" & _
"# Installer 7-Zip portable" & _
"if(!(Test-Path $7zPath)){" & _
"  Log 'Installation de 7-Zip...';" & _
"  $7zFolder=$env:USERPROFILE+'\Outils\7z';" & _
"  if(!(Test-Path $7zFolder)){mkdir $7zFolder -Force|Out-Null};" & _
"  $temp=$env:TEMP+'\7za.zip';" & _
"  try{" & _
"    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" & _
"    Invoke-WebRequest -Uri $7zUrl -OutFile $temp -UseBasicParsing;" & _
"    Expand-Archive -Path $temp -DestinationPath $7zFolder -Force;" & _
"    Remove-Item $temp -Force;" & _
"    Log '7-Zip installé'" & _
"  }catch{" & _
"    Log ('Erreur installation 7-Zip: '+$_.Exception.Message)" & _
"  }" & _
"};" & _
"" & _
"# Chiffrer le dossier" & _
"if(Test-Path $7zPath){" & _
"  Log 'Chiffrement en cours...';" & _
"  $args=@('a','-t7z','-mx=9','-mhe=on','-p'+$pwd,$zip,($doc+'\*'));" & _
"  $process=Start-Process -FilePath $7zPath -ArgumentList $args -Wait -NoNewWindow -PassThru;" & _
"  " & _
"  if($process.ExitCode -eq 0 -and (Test-Path $zip)){" & _
"    Log 'Chiffrement réussi';" & _
"    $size=(Get-Item $zip).Length;" & _
"    Log ('Taille archive: '+[math]::Round($size/1MB,2)+' MB');" & _
"    " & _
"    # Supprimer le dossier non chiffré (OPTIONNEL - COMMENTEZ SI VOUS VOULEZ GARDER)" & _
"    # Remove-Item $doc -Recurse -Force;" & _
"    # Log 'Dossier original supprimé';" & _
"    " & _
"    # Créer un fichier info" & _
"    $info=@''" & _
"╔════════════════════════════════════╗" & _
"║   DOSSIER CHIFFRÉ - INFORMATIONS   ║" & _
"╚════════════════════════════════════╝" & _
"" & _
"Date: $(Get-Date)" & _
"Machine: $pc" & _
"Utilisateur: $user" & _
"" & _
"Source: $doc" & _
"Archive chiffrée: $zip" & _
"" & _
"Sécurité:" & _
"- Algorithme: AES-256" & _
"- Compression: LZMA2 (niveau max)" & _
"- Headers chiffrés: Oui" & _
"" & _
"Pour déchiffrer:" & _
"1. Clic droit sur le fichier .7z" & _
"2. Extraire avec 7-Zip" & _
"3. Entrer le mot de passe" & _
"''@;" & _
"    $info|Out-File ($env:USERPROFILE+'\Desktop\Doc_Chiffre_INFO.txt')" & _
"  }else{" & _
"    Log 'ERREUR: Échec du chiffrement'" & _
"  }" & _
"}else{" & _
"  Log 'ERREUR: 7-Zip introuvable'" & _
"};" & _
"" & _
"Log 'Fin du processus'"

' Exécuter
WshShell.Run cmd, 0, True

' Attendre la fin et vérifier
WScript.Sleep 3000
If FSO.FileExists(outputZip) Then
    ' Message silencieux ou log seulement
    Set logFile = FSO.CreateTextFile(desktopPath & "\CHIFFREMENT_OK.txt", True)
    logFile.WriteLine "✅ CHIFFREMENT RÉUSSI"
    logFile.WriteLine "Date: " & Now()
    logFile.WriteLine "Archive: " & outputZip
    logFile.Close
End If
