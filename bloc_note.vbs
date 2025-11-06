Set WshShell = CreateObject("WScript.Shell")

userProfile = WshShell.ExpandEnvironmentStrings("%USERPROFILE%")
desktopPath = WshShell.ExpandEnvironmentStrings("%USERPROFILE%") & "\Desktop"
exportFolder = desktopPath & "\export"

' Script PowerShell qui trouve automatiquement le bon dossier
cmd = "powershell.exe -ExecutionPolicy Bypass -Command " & _
"$desktop='" & desktopPath & "';" & _
"$export='" & exportFolder & "';" & _
"" & _
"# Trouver le dossier Téléchargements" & _
"$downloads=(New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path;" & _
"" & _
"Write-Host 'Source: ' $downloads -ForegroundColor Cyan;" & _
"Write-Host 'Destination: ' $export -ForegroundColor Cyan;" & _
"Write-Host '';" & _
"" & _
"# Créer le dossier export" & _
"if(!(Test-Path $export)){mkdir $export -Force|Out-Null};" & _
"" & _
"# Compter les fichiers" & _
"$files=Get-ChildItem -Path $downloads -Recurse -File -ErrorAction SilentlyContinue;" & _
"$count=$files.Count;" & _
"Write-Host ""Copie de $count fichier(s)..."" -ForegroundColor Yellow;" & _
"" & _
"# Copier tout le contenu" & _
"Get-ChildItem -Path $downloads | Copy-Item -Destination $export -Recurse -Force -ErrorAction SilentlyContinue;" & _
"" & _
"# Rapport" & _
"$rapport=@""" & vbCrLf & _
"EXPORT TERMINÉ" & vbCrLf & _
"==============" & vbCrLf & _
"Date: $(Get-Date)" & vbCrLf & _
"Source: $downloads" & vbCrLf & _
"Destination: $export" & vbCrLf & _
"Fichiers copiés: $count" & vbCrLf & _
"""@;" & _
"$rapport|Out-File ($export+'\RAPPORT.txt');" & _
"" & _
"Write-Host '';" & _
"Write-Host 'Export terminé !' -ForegroundColor Green;" & _
"Write-Host 'Fichiers copiés: ' $count -ForegroundColor Green;" & _
"pause"

WshShell.Run cmd, 1, True
