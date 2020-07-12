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
$command = "Invoke-Expression '$(New-Object IO.StreamReader ('$(New-Object IO.Compression.DeflateStream ('$(New-Object IO.MemoryStream 
((,'$([Convert]::FromBase64String('"$code'")))),
[IO.Compression.CompressionMode]::Decompress)),
[Text.Encoding]::ASCII)).ReadToEnd();"

# Invoke-Expression $command
$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encodedCommand = [Convert]::ToBase64String($bytes)

# Write to Standard Out
Write-Host $encodedCommand
