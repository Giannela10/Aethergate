param([string]$Phase='before')
Add-Type -AssemblyName System.Drawing
$reportDir = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../reports/visual_5'))
$views = Get-Content -LiteralPath (Join-Path $reportDir ($Phase+'_views.json')) -Raw | ConvertFrom-Json
$views = @($views | Group-Object label | ForEach-Object { $_.Group[-1] })
$font = New-Object Drawing.Font('Arial',11)
for ($start=0; $start -lt $views.Count; $start+=12) {
 $sheet=New-Object Drawing.Bitmap(1600,1020)
 $graphics=[Drawing.Graphics]::FromImage($sheet)
 $graphics.Clear([Drawing.Color]::FromArgb(20,24,30))
 for ($i=0; $i -lt 12 -and ($start+$i) -lt $views.Count; $i++) {
  $v=$views[$start+$i]; $x=($i%4)*400; $y=[Math]::Floor($i/4)*340
  $img=[Drawing.Image]::FromFile((Join-Path $reportDir ([IO.Path]::GetFileName($v.capture))))
  $graphics.DrawImage($img,[int]$x,[int]($y+24),400,300)
  $graphics.DrawString($v.label,$font,[Drawing.Brushes]::White,[int]($x+4),[int]$y)
  $img.Dispose()
 }
 $sheet.Save((Join-Path $reportDir ($Phase+'_contact_'+[int]($start/12)+'.jpg')),[Drawing.Imaging.ImageFormat]::Jpeg)
 $graphics.Dispose(); $sheet.Dispose()
}
$font.Dispose()
