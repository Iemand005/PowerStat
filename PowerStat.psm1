function Get-Stat {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Path = ".",

        [Parameter()]
        [switch]$Recurse
    )

    process {
        $ResolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
        if (-not $ResolvedPath) {
            Write-Error "Pad niet gevonden: $Path"
            return
        }
        $LiteralPath = $ResolvedPath.Path

        $Items = @()
        if (Test-Path -Path $LiteralPath -PathType Container) {
            $Items += Get-Item -LiteralPath $LiteralPath
            if ($Recurse) {
                $Items += Get-ChildItem -LiteralPath $LiteralPath -Recurse -Force
            } else {
                $Items += Get-ChildItem -LiteralPath $LiteralPath -Force
            }
        } else {
            $Items += Get-Item -LiteralPath $LiteralPath
        }

        foreach ($Item in $Items) {
            try {
                $FileInfo = New-Object System.IO.FileInfo($Item.FullName)
                
                $CreationUtc   = $FileInfo.CreationTimeUtc
                $LastWriteUtc  = $FileInfo.LastWriteTimeUtc
                $LastAccessUtc = $FileInfo.LastAccessTimeUtc

                [PSCustomObject]@{
                    Name             = $Item.Name
                    FullName         = $Item.FullName
                    Size_Bytes       = if ($Item.Attributes -match "Directory") { 0 } else { $FileInfo.Length }
                    Attributes       = $Item.Attributes
                    AccessMode       = $FileInfo.Attributes
                    
                    # .fffffff geeft exact de maximale 100ns precisie weer die NTFS ondersteunt
                    CreationTime     = $CreationUtc.ToString("yyyy-MM-dd HH:mm:ss.fffffff")
                    CreationTicks    = $CreationUtc.Ticks
                    
                    LastWriteTime    = $LastWriteUtc.ToString("yyyy-MM-dd HH:mm:ss.fffffff")
                    LastWriteTicks   = $LastWriteUtc.Ticks
                    
                    LastAccessTime   = $LastAccessUtc.ToString("yyyy-MM-dd HH:mm:ss.fffffff")
                    LastAccessTicks  = $LastAccessUtc.Ticks
                }
            } catch {
                Write-Error "Fout bij lezen van statistieken voor $($Item.FullName): $_"
            }
        }
    }
}

Export-ModuleMember -Function Get-Stat
