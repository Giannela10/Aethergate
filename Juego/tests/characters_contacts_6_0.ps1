param([string]$Prefix='after')
Add-Type -AssemblyName System.Drawing
$report6=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../reports/characters_6_0'))
$items6=@(Get-ChildItem -LiteralPath $report6 -Filter ($Prefix+'_*.png') | Sort-Object Name)
$font6=New-Object Drawing.Font('Arial',12)
for($start6=0;$start6 -lt $items6.Count;$start6+=12){
 $bitmap6=New-Object Drawing.Bitmap(1600,1020)
 $graphics6=[Drawing.Graphics]::FromImage($bitmap6)
 $graphics6.Clear([Drawing.Color]::FromArgb(20,24,30))
 for($i6=0;$i6 -lt 12 -and ($start6+$i6) -lt $items6.Count;$i6++){
  $item6=$items6[$start6+$i6]; $x6=($i6%4)*400; $y6=[Math]::Floor($i6/4)*340
  $image6=[Drawing.Image]::FromFile($item6.FullName)
  $graphics6.DrawImage($image6,[int]$x6,[int]($y6+24),400,300)
  $graphics6.DrawString($item6.BaseName,$font6,[Drawing.Brushes]::White,[int]($x6+4),[int]$y6)
  $image6.Dispose()
 }
 $bitmap6.Save((Join-Path $report6 ($Prefix+'_contact_'+[int]($start6/12)+'.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg)
 $graphics6.Dispose();$bitmap6.Dispose()
}
$font6.Dispose()
