# Insert BRK_Q0 in series at GSUT_L tree leaves (B02 node), Rev2 V2 model.
# For each phase k: the leaf Branch carrying P(Src=8#lconn:k) is re-pointed to
# the breaker R port, and a new top-level Line connects GSUT_L to breaker L.
# Usage: xml_series_q0.ps1 [-Slx path]   (idempotent-ish: skips phases already done)
param([string]$Slx='')
if ($Slx -eq '') { $Slx = 'G:\Other computers\My Computer (2)\Level 3 Term 1\306 Power Project - opencode\simulink\studies\Load_Flow_V2.slx' }
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
    $brk = @($x.System.Block) | Where-Object { $_.Name -eq 'BRK_Q0' } | Select-Object -First 1
    if ($null -eq $brk) { throw 'BRK_Q0 block not found' }
    $qsid = $brk.SID
    for ($k=1; $k -le 3; $k++) {
      $hit = @()
      foreach ($br in $x.System.SelectNodes('//*[local-name()="Branch"]')) {
        foreach ($p in @($br.P)) {
          if (($p.Name -eq 'Src' -or $p.Name -eq 'Dst') -and $p.'#text' -eq "8#lconn:$k") { $hit += ,@($br,$p.Name) }
        }
      }
      # leaf already converted?
      $done = $false
      foreach ($br in $x.System.SelectNodes('//*[local-name()="Branch"]')) {
        foreach ($p in @($br.P)) {
          if ($p.Name -eq 'Src' -and $p.'#text' -eq "$qsid#rconn:$k") { $done = $true }
        }
      }
      if ($done) { Write-Output "phase $k already converted"; continue }
      if ($hit.Count -ne 1) { throw "phase $k : found $($hit.Count) GSUT_L leaves (expected 1)" }
      $leaf=$hit[0][0]; $pname=$hit[0][1]
      foreach ($p in @($leaf.P)) { if ($p.Name -eq $pname) { $p.'#text' = "$qsid#rconn:$k" } }
      $ln = $x.CreateElement('Line'); $ln.SetAttribute('LineType','Connection')
      $pz = $x.CreateElement('P'); $pz.SetAttribute('Name','ZOrder'); $pz.InnerText = "$([int]900+$k)"
      $ps = $x.CreateElement('P'); $ps.SetAttribute('Name','Src'); $ps.InnerText = "8#lconn:$k"
      $pp = $x.CreateElement('P'); $pp.SetAttribute('Name','Points'); $pp.InnerText = '[0, 0]'
      $pd = $x.CreateElement('P'); $pd.SetAttribute('Name','Dst'); $pd.InnerText = "$qsid#lconn:$k"
      $ln.AppendChild($pz) | Out-Null; $ln.AppendChild($ps) | Out-Null
      $ln.AppendChild($pp) | Out-Null; $ln.AppendChild($pd) | Out-Null
      $x.System.AppendChild($ln) | Out-Null
      Write-Output "phase $k : GSUT_L -> BRK_Q0 -> tree"
    }
    $ms = New-Object System.IO.MemoryStream
    $xw = New-Object System.IO.StreamWriter($ms,[System.Text.Encoding]::UTF8)
    $x.Save($xw); $xw.Flush(); $ms.Position = 0
    $es = $entry.Open(); $es.SetLength(0)
    $ms.CopyTo($es); $es.Close(); $ms.Close()
    Write-Output 'xml_series_q0 done'
  } finally { $zip.Dispose() }
} finally { $fs.Close() }
