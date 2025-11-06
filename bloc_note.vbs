Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

userProfile = WshShell.ExpandEnvironmentStrings("%USERPROFILE%")
desktopPath = WshShell.SpecialFolders("Desktop")
telechargements = userProfile & "\Documents"
exportFolder = desktopPath & "\export"

' Créer le dossier export
If Not FSO.FolderExists(exportFolder) Then
    FSO.CreateFolder(exportFolder)
End If

' Copier tout (FIX : enlever le \* et copier fichier par fichier + sous-dossiers)
If FSO.FolderExists(telechargements) Then
    On Error Resume Next
    
    Set sourceFolder = FSO.GetFolder(telechargements)
    
    ' Copier tous les fichiers
    For Each file In sourceFolder.Files
        FSO.CopyFile file.Path, exportFolder & "\", True
    Next
    
    ' Copier tous les sous-dossiers
    For Each subFolder In sourceFolder.SubFolders
        FSO.CopyFolder subFolder.Path, exportFolder & "\", True
    Next
    
    On Error GoTo 0
End If

' Fichier de log
Set objFile = FSO.CreateTextFile(exportFolder & "\log.txt", True)
objFile.WriteLine "Export : " & Now()
objFile.Close

