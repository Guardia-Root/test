' bloc_notes2.vbs
' Crée un fichier BONJOUR.txt sur le bureau contenant "Bonjour"

Option Explicit

Dim WshShell, FSO, desktopPath, filePath, objFile

Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' Récupérer le chemin du bureau
desktopPath = WshShell.SpecialFolders("Desktop")
If desktopPath = "" Then
    ' fallback
    desktopPath = WshShell.ExpandEnvironmentStrings("%USERPROFILE%") & "\Desktop"
End If

filePath = desktopPath & "\BONJOUR.txt"

On Error Resume Next
Set objFile = FSO.CreateTextFile(filePath, True)
If Err.Number <> 0 Then
    ' En cas d'erreur, on quitte proprement
    WScript.Quit 1
End If
On Error GoTo 0

objFile.WriteLine "Bonjour"
objFile.Close
