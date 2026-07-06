function Get-Stat {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Path = ".",

        [Parameter()]
        [switch]$Recurse
    )

    process {
        # Los het pad op naar een absoluut bestandssysteem-pad
        $ResolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
        if (-not $ResolvedPath) {
            Write-Error "Pad niet gevonden: $Path"
            return
        }
        $LiteralPath = $ResolvedPath.Path

        # Verzamel alle doelen (bestand/map zelf, en eventueel subbestanden)
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

        # Verwerk elk item en haal de 100ns precisie (Ticks) op
        foreach ($Item in $Items) {
            try {
                $FileInfo = New-Object System.IO.FileInfo($Item.FullName)
                
                # Windows Ticks representeren exact 100-nanoseconde intervallen
                [PSCustomObject]@{
                    Name             = $Item.Name
                    FullName         = $Item.FullName
                    Size_Bytes       = if ($Item.Attributes -match "Directory") { 0 } else { $FileInfo.Length }
                    Attributes       = $Item.Attributes
                    AccessMode       = $FileInfo.Attributes
                    
                    # Tijdstempels met volledige precisie via .NET Ticks
                    CreationTime     = $FileInfo.CreationTimeUtc.ToString("yyyy-MM-dd HH:mm:ss.fffffffff")
                    CreationTicks    = $FileInfo.CreationTimeUtc.Ticks
                    
                    LastWriteTime    = $FileInfo.LastWriteTimeUtc.ToString("yyyy-MM-dd HH:mm:ss.fffffffff")
                    LastWriteTicks   = $FileInfo.LastWriteTicks = $FileInfo.LastWriteTimeUtc.Ticks
                    
                    LastAccessTime   = $FileInfo.LastAccessTimeUtc.ToString("yyyy-MM-dd HH:mm:ss.fffffffff")
                    LastAccessTicks  = $FileInfo.LastAccessTimeUtc.Ticks
                }
            } catch {
                Write-Error "Fout bij lezen van statistieken voor $($Item.FullName): $_"
            }
        }
    }
}

Export-ModuleMember -Function Get-Stat
