Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' ===== CONFIGURATION =====
desktopPath = WshShell.SpecialFolders("Desktop")
dossierDoc = desktopPath & "\Doc"
userProfile = WshShell.ExpandEnvironmentStrings("%USERPROFILE%")
computerName = WshShell.ExpandEnvironmentStrings("%COMPUTERNAME%")
userName = WshShell.ExpandEnvironmentStrings("%USERNAME%")

' Mot de passe
motDePasse = "SecureVM2025"

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

' Script PowerShell (FIX : guillemets corrigés)
cmd = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command " & _
"$doc='" & dossierDoc & "'; " & _
"$zip='" & outputZip & "'; " & _
"$pwd='" & motDePasse & "'; " & _
"$7zPath=$env:USERPROFILE+'\Outils\7z\7za.exe'; " & _
"$7zUrl='https://www.7-zip.org/a/7za920.zip'; " & _
"if(!(Test-Path $7zPath)){ " & _
"  $7zFolder=$env:USERPROFILE+'\Outils\7z'; " & _
"  if(!(Test-Path $7zFolder)){mkdir $7zFolder -Force|Out-Null}; " & _
"  $temp=$env:TEMP+'\7za.zip'; " & _
"  [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; " & _
"  Invoke-WebRequest -Uri $7zUrl -OutFile $temp -UseBasicParsing; " & _
"  Expand-Archive -Path $temp -DestinationPath $7zFolder -Force; " & _
"  Remove-Item $temp -Force " & _
"}; " & _
"if(Test-Path $7zPath){ " & _
"  $args='a','-t7z','-mx=9','-mhe=on',('-p'+$pwd),$zip,($doc+'\*'); " & _
"  Start-Process -FilePath $7zPath -ArgumentList $args -Wait -NoNewWindow -WindowStyle Hidden; " & _
"  if(Test-Path $zip){ " & _
"    'Chiffrement OK'|Out-File ($env:USERPROFILE+'\Desktop\CHIFFREMENT_OK.txt') " & _
"  } " & _
"}"

' Exécuter
WshShell.Run cmd, 0, True

' Vérifier le résultat
WScript.Sleep 2000
If FSO.FileExists(outputZip) Then
    MsgBox "✅ Chiffrement réussi !" & vbCrLf & vbCrLf & _
           "Archive : " & outputZip, vbInformation, "OK"
Else
    MsgBox "❌ Erreur lors du chiffrement", vbCritical, "Erreur"
End If
