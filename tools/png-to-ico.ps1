# Convierte assets/img/logo.png a favicon.ico en la raíz del proyecto
# Usa formato ICO que contiene la imagen PNG (soportado por navegadores modernos)
# Ejecutar desde la carpeta del repo con PowerShell

param(
    [string]$PngPath = "assets/img/logo.png",
    [string]$IcoPath = "favicon.ico",
    [int]$MaxSize = 256
)

try {
    Add-Type -AssemblyName System.Drawing
    if (-not (Test-Path $PngPath)) {
        Write-Error "Archivo PNG no encontrado: $PngPath"
        exit 1
    }

    $pngBytes = [System.IO.File]::ReadAllBytes($PngPath)
    # Obtener dimensiones de la imagen
    $img = [System.Drawing.Image]::FromFile($PngPath)
    $w = $img.Width
    $h = $img.Height
    $img.Dispose()

    if ($w -gt $MaxSize -or $h -gt $MaxSize) {
        Write-Host "Redimensionando imagen a $MaxSize x $MaxSize"
        $bmp = New-Object System.Drawing.Bitmap $MaxSize, $MaxSize
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $orig = [System.Drawing.Image]::FromFile($PngPath)
        $g.DrawImage($orig, 0, 0, $MaxSize, $MaxSize)
        $orig.Dispose()
        $g.Dispose()
        $msTemp = New-Object System.IO.MemoryStream
        $bmp.Save($msTemp, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngBytes = $msTemp.ToArray()
        $msTemp.Dispose()
        $bmp.Dispose()
    }

    # Construir contenedor ICO que incluye la imagen PNG (ICO v2 admite PNG inside)
    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)

    # Header: Reserved (2 bytes), Type (2 bytes), Count (2 bytes)
    $bw.Write([uint16]0)   # reserved
    $bw.Write([uint16]1)   # type = 1 (icon)
    $bw.Write([uint16]1)   # count = 1

    # Directory entry (16 bytes)
    # Width (1), Height (1), ColorCount(1), Reserved(1), Planes(2), BitCount(2), BytesInRes(4), ImageOffset(4)
    $widthByte = if ($w -ge 256) { 0 } else { [byte]$w }
    $heightByte = if ($h -ge 256) { 0 } else { [byte]$h }
    $bw.Write([byte]$widthByte)
    $bw.Write([byte]$heightByte)
    $bw.Write([byte]0) # color count
    $bw.Write([byte]0) # reserved
    $bw.Write([uint16]1) # planes
    $bw.Write([uint16]32) # bitcount (32 for PNG)
    $bw.Write([uint32]$pngBytes.Length) # bytes in resource
    $imageOffset = 6 + 16
    $bw.Write([uint32]$imageOffset)

    # Escribir PNG bytes
    $bw.Write($pngBytes)

    # Guardar archivo ICO
    [System.IO.File]::WriteAllBytes($IcoPath, $ms.ToArray())
    $bw.Close()
    $ms.Close()

    Write-Host "favicon creado en: $IcoPath"
    exit 0
} catch {
    Write-Error "Error al crear favicon.ico: $_"
    exit 1
}
