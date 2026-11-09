param([string]$ReportRoot = (Join-Path $PSScriptRoot '../reports/detailed_walkthrough_2026_10_26'))
Add-Type -AssemblyName System.Drawing
$ReportRoot = (Resolve-Path -LiteralPath $ReportRoot).Path
$inventory = Get-Content -LiteralPath (Join-Path $ReportRoot 'inventory.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$font = New-Object System.Drawing.Font('Arial',12)
$smallFont = New-Object System.Drawing.Font('Arial',10)
$brush = [System.Drawing.Brushes]::White
foreach ($room in $inventory.rooms) {
    $roomId = [int]$room.id
    $lastView = Join-Path $ReportRoot ('room_{0:000}_5.png' -f $roomId)
    if (-not (Test-Path -LiteralPath $lastView)) { continue }
    $output = Join-Path $ReportRoot ('contact_{0:000}.jpg' -f $roomId)
    $sheet = New-Object System.Drawing.Bitmap(1152,512)
    $graphics = [System.Drawing.Graphics]::FromImage($sheet)
    $graphics.Clear([System.Drawing.Color]::FromArgb(23,27,35))
    $graphics.DrawString(('{0:000} | Piso {1} | {2}' -f $roomId,$room.floor,$room.path),$font,$brush,8,5)
    for ($view = 0; $view -lt 6; $view++) {
        $source = Join-Path $ReportRoot ('room_{0:000}_{1}.png' -f $roomId,$view)
        $image = [System.Drawing.Image]::FromFile($source)
        $left = ($view % 3) * 384
        $top = 48 + [math]::Floor($view / 3) * 232
        $graphics.DrawImage($image,[int]$left,[int]$top,384,216)
        $graphics.DrawString(@('Norte','Este','Sur','Oeste','Techo','Suelo')[$view],$smallFont,$brush,[int]($left+5),[int]($top+216))
        $image.Dispose()
    }
    $sheet.Save($output,[System.Drawing.Imaging.ImageFormat]::Jpeg)
    $graphics.Dispose()
    $sheet.Dispose()
}
$font.Dispose()
$smallFont.Dispose()
foreach ($dataset in @('extra','supplemental')) {
if (Test-Path -LiteralPath (Join-Path $ReportRoot ($dataset + '_views.json'))) {
    $views = Get-Content -LiteralPath (Join-Path $ReportRoot ($dataset + '_views.json')) -Raw -Encoding UTF8 | ConvertFrom-Json
    $pageFont = New-Object System.Drawing.Font('Arial',11)
    for ($start = 0; $start -lt $views.Count; $start += 9) {
        $page = New-Object System.Drawing.Bitmap(1152,738)
        $graphics = [System.Drawing.Graphics]::FromImage($page)
        $graphics.Clear([System.Drawing.Color]::FromArgb(23,27,35))
        for ($offset = 0; $offset -lt 9 -and ($start + $offset) -lt $views.Count; $offset++) {
            $view = $views[$start + $offset]
            $left = ($offset % 3) * 384
            $top = [math]::Floor($offset / 3) * 246
            $image = [System.Drawing.Image]::FromFile((Join-Path $ReportRoot ($view.label + '.png')))
            $graphics.DrawString($view.label,$pageFont,$brush,[int]($left+5),[int]($top+5))
            $graphics.DrawImage($image,[int]$left,[int]($top+26),384,216)
            $image.Dispose()
        }
        $page.Save((Join-Path $ReportRoot ($dataset + ('_contact_{0:00}.jpg' -f [int]($start/9)))),[System.Drawing.Imaging.ImageFormat]::Jpeg)
        $graphics.Dispose()
        $page.Dispose()
    }
    $pageFont.Dispose()
}
}
Write-Output ('Contact sheets: ' + (Get-ChildItem -LiteralPath $ReportRoot -Filter 'contact_*.jpg').Count)
