$ErrorActionPreference = 'Break'

$baseDir = $PSScriptRoot
$configPath = "$($baseDir)\config.json"

enum ExifId {
    DateTimeOriginal = 0x9003
    DateTimeDigitized = 0x9004
}

function GetShootingDate {
    [CmdletBinding()]
    param (
        # target file
        [Parameter(Mandatory)]
        [System.Drawing.Bitmap]
        $Image
    )
    $shotProp = $null
    try {
        # Check that the shooting date is set.
        $shotProp = $image.GetPropertyItem([ExifId]::DateTimeOriginal)
        [void][System.Text.Encoding]::ASCII.GetString($shotProp.Value)
    } catch {
        return $null
    }
    return $shotProp
}

function SetExifDateProperty {
    [CmdletBinding()]
    param (
        # Image
        [Parameter(Mandatory)]
        [System.Drawing.Bitmap]
        $Image,
        # Exif id
        [Parameter(Mandatory)]
        [int]
        $ExifId,
        # Set Date Array
        [Parameter(Mandatory)]
        [Array]
        $DateArray
    )
    $prop = $image.PropertyItems | Select-Object -First 1
    $prop.Id = $ExifId
    $prop.Len = 20
    $prop.Type = 2
    $prop.Value = $DateArray
    $Image.SetPropertyItem($prop)
}

function CreatedDateToShootingDate {
    param (
        # target file
        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $ImageFile,
        # force renewal
        [Parameter()]
        [switch]
        $Force
    )
    $image = New-Object System.Drawing.Bitmap($ImageFile.FullName)
    $prop = GetShootingDate -Image $image
    if(($null -eq $prop) -or $Force) {
        $created = $ImageFile.CreationTime.ToString("yyyy:MM:dd HH:mm:ss")
        [array]$createdBytes = [System.Text.Encoding]::ASCII.GetBytes($created)
        $createdBytes += 0x00

        foreach($id in [ExifId].GetEnumValues() ) {
            SetExifDateProperty -Image $image -ExifId $id -DateArray $createdBytes
        }

        $tmp = New-TemporaryFile
        $image.Save($tmp.FullName, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        $image.Dispose()

        Set-ItemProperty -Path $tmp -Name CreationTime -Value $ImageFile.CreationTime
        Set-ItemProperty -Path $tmp -Name LastAccessTime -Value $ImageFile.LastAccessTime
        Set-ItemProperty -Path $tmp -Name LastWriteTime -Value $ImageFile.LastWriteTime

        Move-Item -Path $tmp.FullName -Destination $ImageFile.FullName -Force
    }
}

function Initialize {
    Add-Type -AssemblyName System.Drawing
}


Initialize
$config = ConvertFrom-Json (Get-Content -Path $configPath -Encoding utf8 -Raw)
$path = $config.input_path
if(([bool]$path) -eq $false) {
    exit 1
}
foreach( $img in (Get-ChildItem "$($path)\*.jpg")) {
    CreatedDateToShootingDate -ImageFile $img
}
exit 0