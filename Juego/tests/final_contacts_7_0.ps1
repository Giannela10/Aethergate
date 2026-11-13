$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$evidenceRoot=(Get-Content (Join-Path $PSScriptRoot '../reports/final_7_0/active_run.txt')).Trim()
$evidenceRoot=(Resolve-Path (Join-Path $PSScriptRoot ('../../'+$evidenceRoot))).Path
foreach($floor in @('PisoMenos1','Piso1','Piso2')) {
    $files=@(Get-ChildItem -LiteralPath $evidenceRoot -Filter ('survey_'+$floor+'*.png'))
    for($page=0;$page -lt [Math]::Ceiling($files.Count/12);$page++) {
        $canvas=New-Object Drawing.Bitmap 1200,1040
        $graphics=[Drawing.Graphics]::FromImage($canvas)
        $graphics.Clear([Drawing.Color]::White)
        $font=New-Object Drawing.Font 'Arial',9
        for($slot=0;$slot -lt 12;$slot++) {
            $index=$page*12+$slot
            if($index -ge $files.Count){break}
            $file=$files[$index]
            $x=($slot%3)*400;$y=[Math]::Floor($slot/3)*260
            $picture=[Drawing.Image]::FromFile($file.FullName)
            $graphics.DrawImage($picture,$x,$y,400,225)
            $graphics.DrawString($file.BaseName.Replace('survey_'+$floor+'_',''),$font,[Drawing.Brushes]::Black,[Drawing.RectangleF]::new($x,$y+225,400,35))
            $picture.Dispose()
        }
        $name=Join-Path $evidenceRoot ('contact_'+$floor+'_'+$page+'.png')
        if(Test-Path -LiteralPath $name){throw 'Contact sheet already exists; preserve evidence.'}
        $canvas.Save($name,[Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose();$canvas.Dispose();$font.Dispose()
    }
}
