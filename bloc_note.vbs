Set WshShell = CreateObject("WScript.Shell")
Set FSO = CreateObject("Scripting.FileSystemObject")

' Récupérer le chemin du Bureau
desktopPath = WshShell.SpecialFolders("Desktop")

' Créer le fichier txt sur le Bureau
outputFile = desktopPath & "\MonFichier.txt"

' Créer et écrire dans le fichier
Set textFile = FSO.CreateTextFile(outputFile, True)
textFile.WriteLine "Bonjour ! Ceci est mon premier fichier texte."
textFile.WriteLine "Il a été créé le : " & Now()
textFile.WriteLine ""
textFile.WriteLine "Vous pouvez modifier ce texte comme vous le souhaitez."
textFile.Close

