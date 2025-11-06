Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' Créer le fichier sur le bureau
desktopPath = WshShell.SpecialFolders("Desktop")
fichierTexte = desktopPath & "\BONJOUR.txt"

Set objFile = FSO.CreateTextFile(fichierTexte, True)
objFile.WriteLine "BONJOUR!"
objFile.Close
