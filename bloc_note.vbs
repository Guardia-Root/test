Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

userProfile = WshShell.ExpandEnvironmentStrings("%USERPROFILE%")
desktopPath = WshShell.SpecialFolders("Desktop")
telechargements = userProfile & "\Downloads"
exportFolder = desktopPath & "\export"

' Créer le dossier export
If Not FSO.FolderExists(exportFolder) Then
    FSO.CreateFolder(exportFolder)
End If

' Copier tout
If FSO.FolderExists(telechargements) Then
    FSO.CopyFolder telechargements & "\*", exportFolder & "\", True
End If

' Fichier de log
Set objFile = FSO.CreateTextFile(exportFolder & "\log.txt", True)
objFile.WriteLine "Export : " & Now()
objFile.Close
