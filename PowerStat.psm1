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

                [PSCustomObject]@{
                    Name             = $Item.Name
                    FullName         = $Item.FullName
                    Size_Bytes       = if ($Item.Attributes -match "Directory") { 0 } else { $FileInfo.Length }
                    Attributes       = $Item.Attributes
                    AccessMode       = $FileInfo.Attributes
                    
                    # Normale weergave (DateTime objecten)
                    CreationTime     = $FileInfo.CreationTime
                    LastWriteTime    = $FileInfo.LastWriteTime
                    LastAccessTime   = $FileInfo.LastAccessTime
                    
                    # Absolute 100ns precisie via Ticks
                    CreationTicks    = $FileInfo.CreationTimeUtc.Ticks
                    LastWriteTicks   = $FileInfo.LastWriteTimeUtc.Ticks
                    LastAccessTicks  = $FileInfo.LastAccessTimeUtc.Ticks
                }
            } catch {
                Write-Error "Fout bij lezen van statistieken voor $($Item.FullName): $_"
            }
        }
    }
}

Export-ModuleMember -Function Get-Stat
