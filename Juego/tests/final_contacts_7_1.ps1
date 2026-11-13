param([int]$Floor=3,[string]$Phase='before')
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$relative=(Get-Content (Join-Path $PSScriptRoot '../reports/final_7_1/active_run.txt')).Trim()
$root=(Resolve-Path (Join-Path $PSScriptRoot ('../../'+$relative))).Path
$directory=Join-Path $root ('floor_'+$Floor)
$files=@(Get-ChildItem -LiteralPath $directory -Filter ($Phase+'_*.png'))
for($page=0;$page -lt [Math]::Ceiling($files.Count/12);$page++) {
 $canvas=New-Object Drawing.Bitmap 1200,1040
 $g=[Drawing.Graphics]::FromImage($canvas);$g.Clear([Drawing.Color]::White)
 $font=New-Object Drawing.Font 'Arial',9
 for($slot=0;$slot -lt 12;$slot++) {
  $index=$page*12+$slot;if($index -ge $files.Count){break}
  $file=$files[$index];$x=($slot%3)*400;$y=[Math]::Floor($slot/3)*260
  $picture=[Drawing.Image]::FromFile($file.FullName);$g.DrawImage($picture,$x,$y,400,225);$picture.Dispose()
  $g.DrawString($file.BaseName,$font,[Drawing.Brushes]::Black,[Drawing.RectangleF]::new($x,$y+225,400,35))
 }
 $target=Join-Path $directory ('contacts_'+$Phase+'_'+$page+'.png')
 if(Test-Path -LiteralPath $target){throw 'Evidence already exists.'}
 $canvas.Save($target,[Drawing.Imaging.ImageFormat]::Png);$g.Dispose();$canvas.Dispose();$font.Dispose()
}
