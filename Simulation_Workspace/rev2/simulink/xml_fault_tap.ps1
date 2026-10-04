# XML-level fault tap tool for Load_Flow_V2.slx (R2024a code cannot branch
# occupied SPS physical ports; this edits the branch tree exactly as the GUI does).
# Usage:
#   xml_fault_tap.ps1 -Action tap   -Bus B01|B02 [-Slx path]
#   xml_fault_tap.ps1 -Action untap -Bus B01|B02 [-Slx path]
# Tap = append <Branch ConnectType="DEST_SRC"><P Name="Dst">SID#lconn:k</P>
# as direct children of the bus container Line (pattern proven by 83# refs).
param([string]$Action='tap',[string]$Bus='B02',[string]$Slx='')
if ($Slx -eq '') { $Slx = 'G:\Other computers\My Computer (2)\Level 3 Term 1\306 Power Project - opencode\simulink\studies\Load_Flow_V2.slx' }
$busAnchor = @{ B01 = '19#rconn'; B02 = '11#lconn' }
# B01 taps anchor on G1 terminals, B02 on BUS COUPLER (both never restructured;
# GSUT_L refs collide with the Q0 series insert - do NOT anchor there).
$fb = @{ B01 = 'F_B01'; B02 = 'F_B02' }[$Bus]
Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
$fs = [System.IO.File]::Open($Slx,[System.IO.FileMode]::Open,[System.IO.FileAccess]::ReadWrite)
try {
  $zip = New-Object System.IO.Compression.ZipArchive($fs,[System.IO.Compression.ZipArchiveMode]::Update)
  try {
    $entry = $zip.GetEntry('simulink/systems/system_root.xml')
    $sr = New-Object System.IO.StreamReader($entry.Open())
    $xmlText = $sr.ReadToEnd(); $sr.Close()
    [xml]$x = $xmlText
    $blk = @($x.System.Block) | Where-Object { $_.Name -eq $fb } | Select-Object -First 1
    if ($null -eq $blk) { throw "block $fb not found" }
    $sid = $blk.SID
    $anchorBase = $busAnchor[$Bus]
    # per-phase containers (phase k tree carries anchorBase:k); remove any
    # existing taps of this block everywhere first (idempotent)
    $nrem = 0
    foreach ($ln in @($x.System.Line)) {
      $todel = @()
      foreach ($br in @($ln.GetElementsByTagName('Branch'))) {
        foreach ($p in @($br.P)) { if ($p.Name -eq 'Dst' -and $p.'#text' -match "^$sid#lconn:") { $todel += $br; break } }
      }
      foreach ($br in $todel) { $ln.RemoveChild($br) | Out-Null; $nrem++ }
    }
    $nadd = 0
    if ($Action -eq 'tap') {
      for ($k=1; $k -le 3; $k++) {
        $anchor = "$anchorBase`:$k"
        $container = $null
        foreach ($ln in @($x.System.Line)) {
          if ($ln.OuterXml -match [regex]::Escape($anchor)) { $container = $ln; break }
        }
        if ($null -eq $container) { throw "phase-$k container ($anchor) not found" }
        $br = $x.CreateElement('Branch')
        $br.SetAttribute('ConnectType','DEST_SRC')
        $p = $x.CreateElement('P'); $p.SetAttribute('Name','Dst'); $p.InnerText = "$sid#lconn:$k"
        $br.AppendChild($p) | Out-Null
        # top-level child (proven crash-free across the validation suite; nested
        # placement correlated with teardown crashes - do not nest)
        $container.AppendChild($br) | Out-Null
        $nadd++
      }
    }
    $ms = New-Object System.IO.MemoryStream
    $xw = New-Object System.IO.StreamWriter($ms,[System.Text.Encoding]::UTF8)
    $x.Save($xw); $xw.Flush(); $ms.Position = 0
    $es = $entry.Open(); $es.SetLength(0)
    $ms.CopyTo($es); $es.Close(); $ms.Close()
    Write-Output "$Action $fb (SID $sid) $Bus phase-correct: removed $nrem, added $nadd"
  } finally { $zip.Dispose() }
} finally { $fs.Close() }

