Add-Type -AssemblyName System.Drawing

function Draw-StudyMateLogo {
    param(
        [System.Drawing.Graphics]$g,
        [float]$x,
        [float]$y,
        [float]$size,
        [bool]$drawBackground = $true,
        [bool]$squircle = $true
    )

    $scale = $size / 512.0

    if ($drawBackground) {
        # Linear Gradient Brush
        $rect = New-Object System.Drawing.RectangleF($x, $y, $size, $size)
        $c1 = [System.Drawing.Color]::FromArgb(255, 0x62, 0x58, 0xE8) # Indigo
        $c2 = [System.Drawing.Color]::FromArgb(255, 0x39, 0x87, 0xF5) # Blue
        $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c2, 45.0)

        if ($squircle) {
            $radius = $size * 0.226
            $path = New-Object System.Drawing.Drawing2D.GraphicsPath
            $dia = $radius * 2
            $path.AddArc($x, $y, $dia, $dia, 180, 90)
            $path.AddArc($x + $size - $dia, $y, $dia, $dia, 270, 90)
            $path.AddArc($x + $size - $dia, $y + $size - $dia, $dia, $dia, 0, 90)
            $path.AddArc($x, $y + $size - $dia, $dia, $dia, 90, 90)
            $path.CloseFigure()
            $g.FillPath($bgBrush, $path)
        } else {
            $g.FillRectangle($bgBrush, $rect)
        }
    }

    # Transform coordinates
    $state = $g.Save()
    $g.TranslateTransform($x, $y)
    $g.ScaleTransform($scale, $scale)

    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $capBaseBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0xE2, 0xE6, 0xFA))
    $goldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0xF5, 0x9E, 0x0B))
    $goldPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 0xF5, 0x9E, 0x0B), 5.0)
    $spinePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 0xD5, 0xDC, 0xF8), 3.0)

    # 1. Graduation Cap Skullcap (underneath)
    $capPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $pts = @(
        (New-Object System.Drawing.PointF(174, 195)),
        (New-Object System.Drawing.PointF(256, 235)),
        (New-Object System.Drawing.PointF(338, 195)),
        (New-Object System.Drawing.PointF(338, 232)),
        (New-Object System.Drawing.PointF(256, 290)),
        (New-Object System.Drawing.PointF(174, 250))
    )
    $capPath.AddPolygon($pts)
    $g.FillPath($capBaseBrush, $capPath)

    # 2. Mortarboard Diamond Top
    $diamond = @(
        (New-Object System.Drawing.PointF(256, 108)),
        (New-Object System.Drawing.PointF(406, 178)),
        (New-Object System.Drawing.PointF(256, 242)),
        (New-Object System.Drawing.PointF(106, 178))
    )
    $g.FillPolygon($whiteBrush, $diamond)

    # 3. Cap Center Button
    $g.FillEllipse($goldBrush, 247, 169, 18, 14)

    # 4. Golden Tassel Ribbon
    $tasselCurve = @(
        (New-Object System.Drawing.PointF(256, 176)),
        (New-Object System.Drawing.PointF(320, 185)),
        (New-Object System.Drawing.PointF(376, 214)),
        (New-Object System.Drawing.PointF(376, 270))
    )
    $g.DrawCurve($goldPen, $tasselCurve, 0.5)
    $g.FillEllipse($goldBrush, 371, 267, 10, 10)
    # Tassel Brush / Fringe
    $fringe = @(
        (New-Object System.Drawing.PointF(371, 275)),
        (New-Object System.Drawing.PointF(381, 275)),
        (New-Object System.Drawing.PointF(386, 308)),
        (New-Object System.Drawing.PointF(366, 308))
    )
    $g.FillPolygon($goldBrush, $fringe)

    # 5. Open Book - Left Page
    $leftBook = New-Object System.Drawing.Drawing2D.GraphicsPath
    $leftBook.AddBezier(248, 318, 210, 304, 150, 308, 108, 330)
    $leftBook.AddLine(108, 330, 108, 412)
    $leftBook.AddBezier(108, 412, 150, 395, 210, 395, 248, 418)
    $leftBook.CloseFigure()
    $g.FillPath($whiteBrush, $leftBook)

    # 6. Open Book - Right Page
    $rightBook = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rightBook.AddBezier(264, 318, 302, 304, 362, 308, 404, 330)
    $rightBook.AddLine(404, 330, 404, 412)
    $rightBook.AddBezier(404, 412, 362, 395, 302, 395, 264, 418)
    $rightBook.CloseFigure()
    $g.FillPath($whiteBrush, $rightBook)

    # 7. Center Spine Divider
    $g.DrawLine($spinePen, 256, 322, 256, 414)

    # 8. Brand Badge with "STUDY MATE" text directly on logo
    $badgeRect = New-Object System.Drawing.RectangleF(116, 426, 280, 50)
    $bRadius = 25.0
    $bPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $bDia = $bRadius * 2
    $bPath.AddArc(116, 426, $bDia, $bDia, 180, 90)
    $bPath.AddArc(116 + 280 - $bDia, 426, $bDia, $bDia, 270, 90)
    $bPath.AddArc(116 + 280 - $bDia, 426 + 50 - $bDia, $bDia, $bDia, 0, 90)
    $bPath.AddArc(116, 426 + 50 - $bDia, $bDia, $bDia, 90, 90)
    $bPath.CloseFigure()
    $g.FillPath($whiteBrush, $bPath)

    $logoFont = New-Object System.Drawing.Font("Arial", 22, [System.Drawing.FontStyle]::Bold)
    $logoTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0x4F, 0x46, 0xE5))
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString("STUDY MATE", $logoFont, $logoTextBrush, $badgeRect, $sf)

    $g.Restore($state)
}

# 1. Generate 512x512 studymate_logo.png
$bmpLogo = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmpLogo)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
Draw-StudyMateLogo -g $g -x 0 -y 0 -size 512 -drawBackground $true -squircle $true
$bmpLogo.Save("c:\Users\amans\Desktop\Study Mate\assets\branding\studymate_logo.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmpLogo.Dispose()

# 2. Generate 512x512 transparent logo
$bmpTrans = New-Object System.Drawing.Bitmap(512, 512)
$gTrans = [System.Drawing.Graphics]::FromImage($bmpTrans)
$gTrans.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
Draw-StudyMateLogo -g $gTrans -x 0 -y 0 -size 512 -drawBackground $false
$bmpTrans.Save("c:\Users\amans\Desktop\Study Mate\assets\branding\studymate_logo_transparent.png", [System.Drawing.Imaging.ImageFormat]::Png)
$gTrans.Dispose()
$bmpTrans.Dispose()

# 3. Generate 1024x1024 app_icon.png (for Launcher & Store)
$bmpAppIcon = New-Object System.Drawing.Bitmap(1024, 1024)
$gIcon = [System.Drawing.Graphics]::FromImage($bmpAppIcon)
$gIcon.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gIcon.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
Draw-StudyMateLogo -g $gIcon -x 0 -y 0 -size 1024 -drawBackground $true -squircle $false
$bmpAppIcon.Save("c:\Users\amans\Desktop\Study Mate\assets\icon\app_icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$gIcon.Dispose()
$bmpAppIcon.Dispose()

# 4. Generate 1024x1024 app_icon_foreground.png (Safe-zone 66% centered for Adaptive Icon)
$bmpFore = New-Object System.Drawing.Bitmap(1024, 1024)
$gFore = [System.Drawing.Graphics]::FromImage($bmpFore)
$gFore.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gFore.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$innerSize = 1024 * 0.64
$offset = (1024 - $innerSize) / 2
Draw-StudyMateLogo -g $gFore -x $offset -y $offset -size $innerSize -drawBackground $false
$bmpFore.Save("c:\Users\amans\Desktop\Study Mate\assets\icon\app_icon_foreground.png", [System.Drawing.Imaging.ImageFormat]::Png)
$gFore.Dispose()
$bmpFore.Dispose()

# 5. Generate 1024x1024 app_icon_background.png
$bmpBack = New-Object System.Drawing.Bitmap(1024, 1024)
$gBack = [System.Drawing.Graphics]::FromImage($bmpBack)
$rectBack = New-Object System.Drawing.RectangleF(0, 0, 1024, 1024)
$c1 = [System.Drawing.Color]::FromArgb(255, 0x62, 0x58, 0xE8)
$c2 = [System.Drawing.Color]::FromArgb(255, 0x39, 0x87, 0xF5)
$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rectBack, $c1, $c2, 45.0)
$gBack.FillRectangle($bgBrush, $rectBack)
$bmpBack.Save("c:\Users\amans\Desktop\Study Mate\assets\icon\app_icon_background.png", [System.Drawing.Imaging.ImageFormat]::Png)
$gBack.Dispose()
$bmpBack.Dispose()

# 6. Generate 800x240 studymate_wordmark.png
$bmpWord = New-Object System.Drawing.Bitmap(800, 240)
$gWord = [System.Drawing.Graphics]::FromImage($bmpWord)
$gWord.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gWord.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# Draw logo on left
Draw-StudyMateLogo -g $gWord -x 24 -y 24 -size 192 -drawBackground $true -squircle $true

# Draw text on right
$titleFont = New-Object System.Drawing.Font("Segoe UI", 48, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Regular)
$tagFont = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Regular)

$titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0x1E, 0x21, 0x34))
$subBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0x62, 0x58, 0xE8))
$tagBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0x6E, 0x74, 0x8E))

$gWord.DrawString("StudyMate", $titleFont, $titleBrush, 240, 32)
$gWord.DrawString("Student Helper", $subFont, $subBrush, 244, 114)
$gWord.DrawString("Study. Plan. Achieve.", $tagFont, $tagBrush, 246, 160)

$bmpWord.Save("c:\Users\amans\Desktop\Study Mate\assets\branding\studymate_wordmark.png", [System.Drawing.Imaging.ImageFormat]::Png)
$gWord.Dispose()
$bmpWord.Dispose()

Write-Host "All StudyMate branding assets successfully created!"
