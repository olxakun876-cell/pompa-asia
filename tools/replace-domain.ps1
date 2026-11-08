<#
.SYNOPSIS
    Mengganti domain lama (pompa.asia) menjadi domain baru (pompa.my.id)
    di seluruh file teks proyek. Mode default = DRY-RUN (tidak menulis apa pun).

.DESCRIPTION
    - Pencocokan CASE-SENSITIVE: hanya string huruf kecil "pompa.asia" yang diganti.
      Nama brand "Pompa Asia" (huruf besar + spasi) TIDAK akan tersentuh.
    - Folder yang dilewati : node_modules, .git, dist, assets/img
    - File biner dilewati  : .png .jpg .jpeg .gif .webp .svg .ico .bmp .woff .woff2 .ttf .eot .pdf .zip
    - File alat (.ps1/.sh) dan file backup (.bak) dilewati agar skrip tidak mengubah dirinya sendiri.
    - Backup: setiap file yang ditulis dibuatkan salinan <nama-file>.bak
      (jika .bak sudah ada, dibuat <nama-file>.bak.yyyyMMdd-HHmmss agar backup asli tidak tertimpa).
    - Encoding & line ending dipertahankan (UTF-8 tanpa BOM, CRLF/LF apa adanya).

.PARAMETER Root
    Folder proyek yang diproses. Default: folder induk dari folder skrip ini.

.PARAMETER OldDomain
    Domain lama. Default: pompa.asia

.PARAMETER NewDomain
    Domain baru. Default: pompa.my.id

.PARAMETER Execute
    Tanpa flag ini = DRY-RUN. Dengan flag ini = file benar-benar ditulis (plus backup).

.EXAMPLE
    # 1) DRY-RUN: lihat daftar file + baris yang akan berubah (aman, tanpa menulis)
    .\tools\replace-domain.ps1

.EXAMPLE
    # 2) EKSEKUSI: tulis perubahan + buat backup .bak
    .\tools\replace-domain.ps1 -Execute
#>
[CmdletBinding()]
param(
    [string]$Root,
    [string]$OldDomain = 'pompa.asia',
    [string]$NewDomain = 'pompa.my.id',
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- konfigurasi
# Folder (relatif terhadap root) yang tidak boleh disentuh.
$ExcludeDirs = @('node_modules', '.git', 'dist', 'assets\img')

# Ekstensi biner / non-teks yang dilewati.
$ExcludeExt = @(
    '.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.ico', '.bmp',
    '.woff', '.woff2', '.ttf', '.eot', '.pdf', '.zip', '.gz', '.mp4', '.bak',
    '.ps1', '.sh'   # file alat: jangan sampai skrip mengubah dirinya sendiri
)

# ------------------------------------------------------- tentukan folder root
if (-not $Root) {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $parentDir = Split-Path -Parent $scriptDir
    # Skrip biasanya ada di <proyek>\tools\. Jika index.html tidak ada di induk,
    # berarti skrip diletakkan langsung di root proyek.
    if (Test-Path -LiteralPath (Join-Path $parentDir 'index.html')) { $Root = $parentDir }
    else { $Root = $scriptDir }
}

if (-not (Test-Path -LiteralPath $Root)) { throw "Folder tidak ditemukan: $Root" }
$Root = (Resolve-Path -LiteralPath $Root).Path

if ($OldDomain -ceq $NewDomain) { throw 'OldDomain dan NewDomain sama - tidak ada yang perlu diganti.' }

Write-Host ''
Write-Host '==========================================================' -ForegroundColor DarkCyan
Write-Host ' GANTI DOMAIN PROYEK' -ForegroundColor Cyan
Write-Host '==========================================================' -ForegroundColor DarkCyan
Write-Host (" Root        : {0}" -f $Root)
Write-Host (" Ganti       : '{0}'  ->  '{1}'  (case-sensitive)" -f $OldDomain, $NewDomain)
if ($Execute) {
    Write-Host ' Mode        : EXECUTE - file akan ditulis + backup .bak' -ForegroundColor Yellow
} else {
    Write-Host ' Mode        : DRY-RUN - tidak ada file yang ditulis' -ForegroundColor Green
}
Write-Host ''

# ------------------------------------------------------------ helper pencocokan
function Test-Excluded {
    param([System.IO.FileInfo]$File)

    # 1) ekstensi biner / file alat
    if ($ExcludeExt -contains $File.Extension.ToLowerInvariant()) { return $true }
    if ($File.Name -like '*.bak' -or $File.Name -like '*.bak.*') { return $true }

    # 2) folder yang dilewati (dicocokkan per segmen path, case-insensitive)
    $rel = $File.FullName.Substring($Root.Length).TrimStart('\')
    foreach ($dir in $ExcludeDirs) {
        if ($rel.StartsWith($dir + '\', [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
        if ($rel.IndexOf('\' + $dir + '\', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    }
    return $false
}

function Get-Newline {
    param([string]$Text)
    if ($Text.Contains("`r`n")) { return "`r`n" }
    return "`n"
}

# --------------------------------------------------------------- proses file
$checked     = 0
$fileChanged = 0
$occurrences = 0
$backupCount = 0
$report      = @()

$allFiles = Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Where-Object { -not (Test-Excluded $_) }

foreach ($file in $allFiles) {
    $checked++

    try { $content = [System.IO.File]::ReadAllText($file.FullName) }
    catch { Write-Warning ("Gagal membaca {0}: {1}" -f $file.Name, $_.Exception.Message); continue }

    if (-not $content.Contains($OldDomain)) { continue }   # Contains() = case-sensitive (ordinal)

    $lines    = $content -split "\r?\n"
    $relPath  = $file.FullName.Substring($Root.Length).TrimStart('\')
    $hitLines = @()
    $fileHits = 0

    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        if (-not $line.Contains($OldDomain)) { continue }

        $count     = [regex]::Matches($line, [regex]::Escape($OldDomain), 'None').Count
        $fileHits += $count
        $newLine   = $line.Replace($OldDomain, $NewDomain)

        $before = $line.Trim()
        $after  = $newLine.Trim()
        if ($before.Length -gt 150) { $before = $before.Substring(0, 150) + '...' }
        if ($after.Length  -gt 150) { $after  = $after.Substring(0, 150) + '...' }

        $hitLines += [pscustomobject]@{
            Line   = $i + 1
            Before = $before
            After  = $after
        }
    }

    if ($fileHits -eq 0) { continue }

    $fileChanged++
    $occurrences += $fileHits
    $report += [pscustomobject]@{ File = $relPath; Hits = $fileHits; Lines = $hitLines }

    # ------------------------------------------------------------- cetak laporan
    Write-Host ("=== {0}  ({1} occurrence) ===" -f $relPath, $fileHits) -ForegroundColor Cyan
    foreach ($h in $hitLines) {
        Write-Host ("  baris {0}" -f $h.Line) -ForegroundColor DarkGray
        Write-Host ("    - {0}" -f $h.Before) -ForegroundColor Yellow
        Write-Host ("    + {0}" -f $h.After)  -ForegroundColor Green
    }
    Write-Host ''

    # ------------------------------------------------------------------- menulis
    if ($Execute) {
        $newContent = $content.Replace($OldDomain, $NewDomain)

        # Backup otomatis sebelum menulis.
        $bakPath = $file.FullName + '.bak'
        if (Test-Path -LiteralPath $bakPath) {
            $bakPath = $file.FullName + '.bak.' + (Get-Date -Format 'yyyyMMdd-HHmmss')
        }
        Copy-Item -LiteralPath $file.FullName -Destination $bakPath -Force
        $backupCount++

        # Tulis ulang: UTF-8 TANPA BOM, encoding & newline dipertahankan.
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($file.FullName, $newContent, $utf8NoBom)
    }
}

# ------------------------------------------------------------------- ringkasan
Write-Host '==========================================================' -ForegroundColor DarkCyan
Write-Host ' RINGKASAN' -ForegroundColor Cyan
Write-Host '==========================================================' -ForegroundColor DarkCyan
Write-Host (" File diperiksa      : {0}" -f $checked)
Write-Host (" File terdampak      : {0}" -f $fileChanged)
Write-Host (" Total occurrence    : {0}" -f $occurrences)
if ($Execute) {
    Write-Host (" Backup .bak dibuat  : {0}" -f $backupCount)

    # Verifikasi akhir: pastikan tidak ada sisa domain lama.
    $leftover = 0
    foreach ($file in $allFiles) {
        try { $text = [System.IO.File]::ReadAllText($file.FullName) } catch { continue }
        if ($text.Contains($OldDomain)) { $leftover++ }
    }
    if ($leftover -eq 0) {
        Write-Host (" Verifikasi          : OK - tidak ada sisa '{0}'" -f $OldDomain) -ForegroundColor Green
    } else {
        Write-Host (" Verifikasi          : {0} file MASIH mengandung '{1}' - periksa manual" -f $leftover, $OldDomain) -ForegroundColor Red
    }
    Write-Host ''
    Write-Host ' Langkah berikutnya:' -ForegroundColor Cyan
    Write-Host '   1. Periksa hasil: git diff'
    Write-Host '   2. Perbarui <lastmod> di sitemap.xml'
    Write-Host '   3. File *.bak boleh dihapus (sudah masuk .gitignore)'
} else {
    Write-Host ''
    Write-Host ' Ini masih DRY-RUN. Untuk benar-benar menulis:' -ForegroundColor Yellow
    Write-Host '   .\tools\replace-domain.ps1 -Execute' -ForegroundColor Yellow
}
Write-Host ''
