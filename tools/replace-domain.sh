#!/usr/bin/env bash
#
# replace-domain.sh — ganti domain lama (pompa.asia) -> domain baru (pompa.my.id)
# di seluruh file teks proyek. Mode default = DRY-RUN (tidak menulis apa pun).
#
# Karakteristik:
#   - CASE-SENSITIVE: hanya "pompa.asia" huruf kecil yang diganti.
#     Brand "Pompa Asia" (huruf besar + spasi) TIDAK tersentuh.
#   - Folder dilewati : node_modules, .git, dist, assets/img (folder bernama "img")
#   - File biner dilewati: .png .jpg .jpeg .gif .webp .svg .ico .bmp .woff .woff2 .ttf .eot .pdf .zip
#   - File alat (.ps1/.sh) & file backup (.bak) dilewati agar skrip tidak mengubah dirinya sendiri.
#   - Backup otomatis <file>.bak sebelum menulis (jika .bak sudah ada -> pakai timestamp).
#
# Pemakaian:
#   chmod +x tools/replace-domain.sh
#   ./tools/replace-domain.sh                 # DRY-RUN
#   ./tools/replace-domain.sh --execute       # tulis perubahan + backup
#   ./tools/replace-domain.sh --execute /path/ke/proyek
#
set -eo pipefail

OLD_DOMAIN="${OLD_DOMAIN:-pompa.asia}"
NEW_DOMAIN="${NEW_DOMAIN:-pompa.my.id}"
EXECUTE=0
ROOT=""

usage() {
  cat <<'EOF'
Pemakaian: replace-domain.sh [--execute] [--old=DOMAIN] [--new=DOMAIN] [FOLDER]

  (tanpa opsi)    DRY-RUN: tampilkan file + baris yang akan diubah, tanpa menulis
  --execute, -x   Tulis perubahan ke disk + buat backup .bak
  --old=DOMAIN    Domain lama (default: pompa.asia)
  --new=DOMAIN    Domain baru (default: pompa.my.id)
  --help, -h      Tampilkan bantuan ini

Contoh:
  ./tools/replace-domain.sh                 # lihat dulu
  ./tools/replace-domain.sh --execute       # baru tulis
EOF
}

for arg in "$@"; do
  case "$arg" in
    --execute|-x) EXECUTE=1 ;;
    --old=*)      OLD_DOMAIN="${arg#*=}" ;;
    --new=*)      NEW_DOMAIN="${arg#*=}" ;;
    --help|-h)    usage; exit 0 ;;
    *)            ROOT="$arg" ;;
  esac
done

# Tentukan folder root: default = induk folder skrip (skrip ada di <proyek>/tools/).
if [ -z "$ROOT" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$SCRIPT_DIR/../index.html" ]; then
    ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  else
    ROOT="$SCRIPT_DIR"
  fi
fi

if [ ! -d "$ROOT" ]; then
  echo "Folder tidak ditemukan: $ROOT" >&2
  exit 1
fi
ROOT="$(cd "$ROOT" && pwd)"

if [ "$OLD_DOMAIN" = "$NEW_DOMAIN" ]; then
  echo "Old dan New domain sama — tidak ada yang perlu diganti." >&2
  exit 1
fi

echo ""
echo "=========================================================="
echo " GANTI DOMAIN PROYEK"
echo "=========================================================="
echo " Root        : $ROOT"
echo " Ganti       : '$OLD_DOMAIN'  ->  '$NEW_DOMAIN'  (case-sensitive)"
if [ "$EXECUTE" -eq 1 ]; then
  echo " Mode        : EXECUTE — file akan ditulis + backup .bak"
else
  echo " Mode        : DRY-RUN — tidak ada file yang ditulis"
fi
echo ""

# Cari file teks yang mengandung domain lama (grep -I = lewati biner, -l = nama file saja).
FILES=()
while IFS= read -r f; do
  if [ -n "$f" ]; then FILES+=("$f"); fi
done < <(
  cd "$ROOT" && grep -rIlF -e "$OLD_DOMAIN" . \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=img \
    --exclude='*.png' --exclude='*.jpg' --exclude='*.jpeg' --exclude='*.gif' \
    --exclude='*.webp' --exclude='*.svg' --exclude='*.ico' --exclude='*.bmp' \
    --exclude='*.woff' --exclude='*.woff2' --exclude='*.ttf' --exclude='*.eot' \
    --exclude='*.pdf' --exclude='*.zip' \
    --exclude='*.bak' --exclude='*.bak.*' \
    --exclude='*.ps1' --exclude='*.sh' \
    2>/dev/null || true
)

CHECKED=$(cd "$ROOT" && find . -type f \
  -not -path './node_modules/*' -not -path './.git/*' -not -path './dist/*' -not -path './assets/img/*' \
  | wc -l | tr -d ' ')

TOTAL_FILES=0
TOTAL_OCC=0
TOTAL_BAK=0

for rel in "${FILES[@]}"; do
  f="$ROOT/${rel#./}"

  # Hitung occurrence (jumlah kemunculan, bukan jumlah baris).
  occ=$(grep -oF -e "$OLD_DOMAIN" "$f" | wc -l | tr -d ' ')

  TOTAL_FILES=$((TOTAL_FILES + 1))
  TOTAL_OCC=$((TOTAL_OCC + occ))
  echo "=== ${rel#./}  ($occ occurrence) ==="

  # Tampilkan per baris: "sebelum" dan "sesudah".
  while IFS= read -r hit; do
    lineno="${hit%%:*}"
    line="${hit#*:}"
    newline="${line//"$OLD_DOMAIN"/"$NEW_DOMAIN"}"
    printf '  baris %s\n' "$lineno"
    printf '    - %s\n' "$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    printf '    + %s\n' "$(printf '%s' "$newline" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  done < <(grep -nF -e "$OLD_DOMAIN" "$f")
  echo ""

  if [ "$EXECUTE" -eq 1 ]; then
    # Backup otomatis sebelum menulis.
    bak="$f.bak"
    if [ -e "$bak" ]; then
      bak="$f.bak.$(date +%Y%m%d-%H%M%S)"
    fi
    cp -p "$f" "$bak"
    TOTAL_BAK=$((TOTAL_BAK + 1))

    # Ganti literal (bukan regex) & case-sensitive, in-place, portabel (GNU + BSD/macOS).
    OLD_DOMAIN="$OLD_DOMAIN" NEW_DOMAIN="$NEW_DOMAIN" \
      perl -pi -e 's/\Q$ENV{OLD_DOMAIN}\E/$ENV{NEW_DOMAIN}/g' "$f"
  fi
done

echo "=========================================================="
echo " RINGKASAN"
echo "=========================================================="
echo " File diperiksa      : $CHECKED"
echo " File terdampak      : $TOTAL_FILES"
echo " Total occurrence    : $TOTAL_OCC"

if [ "$EXECUTE" -eq 1 ]; then
  echo " Backup .bak dibuat  : $TOTAL_BAK"

  # Verifikasi akhir: pastikan tidak ada sisa domain lama.
  # "|| true" wajib: grep mengembalikan exit 1 saat TIDAK ada yang cocok (kondisi sukses).
  LEFT=$(cd "$ROOT" && { grep -rIlF -e "$OLD_DOMAIN" . \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=img \
    --exclude='*.png' --exclude='*.jpg' --exclude='*.svg' --exclude='*.ico' \
    --exclude='*.woff' --exclude='*.woff2' --exclude='*.bak' --exclude='*.bak.*' \
    --exclude='*.ps1' --exclude='*.sh' 2>/dev/null || true; } | wc -l | tr -d ' ')
  if [ "$LEFT" -eq 0 ]; then
    echo " Verifikasi          : OK — tidak ada sisa '$OLD_DOMAIN'"
  else
    echo " Verifikasi          : $LEFT file MASIH mengandung '$OLD_DOMAIN' — periksa manual"
  fi
  echo ""
  echo " Langkah berikutnya:"
  echo "   1. Periksa hasil: git diff"
  echo "   2. Perbarui <lastmod> di sitemap.xml"
  echo "   3. File *.bak boleh dihapus (sudah masuk .gitignore)"
else
  echo ""
  echo " Ini masih DRY-RUN. Untuk benar-benar menulis:"
  echo "   ./tools/replace-domain.sh --execute"
fi
echo ""
