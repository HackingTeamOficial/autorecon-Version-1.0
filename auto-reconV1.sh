#!/bin/bash

#========== BANNER ==========#
clear
echo -e "\e[1;32m
 ___   _                     _   _            _    _               _____                    
|_ _| | |    _____   _____  | | | | __ _  ___| | _(_)_ __   __ _  |_   _|__  __ _ _ __ ___  
 | |  | |   / _ \ \ / / _ \ | |_| |/ _\` |/ __| |/ / | '_ \ / _\` |   | |/ _ \/ _\` | '_ \` _ \ 
 | |  | |__| (_) \ V /  __/ |  _  | (_| | (__|   <| | | | | (_| |   | |  __/ (_| | | | | | |
|___| |_____\___/ \_/ \___| |_| |_|\__,_|\___|_|\_\_|_| |_|\__, |   |_|\___|\__,_|_| |_| |_|
                                                           |___/                            
\e[0m"
echo -e "\e[1;34mBienvenidos a Hacking Team - Comunidad De Hackers"
echo -e "By AnonSec777  |  Telegram: https://t.me/+74d-97oV7P05OTVk\e[0m\n"
sleep 2

#================== CONFIGURACIÓN ==================#
TOOLS=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    "github.com/tomnomnom/assetfinder"
    "github.com/projectdiscovery/httpx/cmd/httpx"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
    "github.com/tomnomnom/gau"
    "github.com/tomnomnom/waybackurls"
    "github.com/jaeles-project/gospider"
    "github.com/projectdiscovery/dnsx/cmd/dnsx"
    "github.com/projectdiscovery/tlsx/cmd/tlsx"
    "github.com/projectdiscovery/cdncheck/cmd/cdncheck"
    "github.com/LukaSikic/unfurl"
    "github.com/1ndianl33t/qsreplace"
    "github.com/tomnomnom/ffuf"
    "github.com/hahwul/dalfox/v2"
)

BIN_DIR="$HOME/go/bin"
export PATH=$PATH:$BIN_DIR

#================== FUNCIÓN DE INSTALACIÓN ==================#
check_or_install() {
    TOOL_NAME=$(basename "$1")
    if ! command -v "$TOOL_NAME" &> /dev/null; then
        echo "[+] Instalando $TOOL_NAME..."
        go install "$1@latest"
    else
        echo "[*] $TOOL_NAME ya está instalado."
    fi
}

echo "[*] Verificando herramientas necesarias..."
for tool in "${TOOLS[@]}"; do
    check_or_install "$tool"
done

#================== INICIO DE RECON ==================#
if [ -z "$1" ]; then
    echo "Uso: $0 <url>"
    exit 1
fi

TARGET=$1
DOMAIN=$(echo "$TARGET" | awk -F/ '{print $3}')
OUT_DIR="output/$DOMAIN"
mkdir -p "$OUT_DIR"

echo "[+] Objetivo: $TARGET"
echo "[+] Dominio: $DOMAIN"
echo "[+] Resultados en: $OUT_DIR"

# Subdomain enum
subfinder -d "$DOMAIN" -silent -o "$OUT_DIR/subfinder.txt"
assetfinder --subs-only "$DOMAIN" > "$OUT_DIR/assetfinder.txt"
cat "$OUT_DIR/"*finder.txt | sort -u > "$OUT_DIR/all_subs.txt"

# Alive domains
cat "$OUT_DIR/all_subs.txt" | httpx -silent -o "$OUT_DIR/alive.txt"

# URL extraction
gau "$DOMAIN" > "$OUT_DIR/gau.txt"
waybackurls "$DOMAIN" > "$OUT_DIR/wayback.txt"
cat "$OUT_DIR"/gau.txt "$OUT_DIR"/wayback.txt | sort -u > "$OUT_DIR/all_urls.txt"

# Spider
gospider -s "$TARGET" -o "$OUT_DIR/gospider" -t 10 --js --subs

# Vulnerability scan
ffuf -u "$TARGET/FUZZ" -w /usr/share/wordlists/dirb/common.txt -o "$OUT_DIR/ffuf.json" -of json
nuclei -l "$OUT_DIR/alive.txt" -o "$OUT_DIR/nuclei.txt"

# XSS
gf xss < "$OUT_DIR/all_urls.txt" > "$OUT_DIR/gf_xss.txt"
dalfox file "$OUT_DIR/gf_xss.txt" -o "$OUT_DIR/dalfox_xss.txt"

# Misc
qsreplace "test" < "$OUT_DIR/all_urls.txt" > "$OUT_DIR/qsreplaced.txt"
unfurl --unique keys < "$OUT_DIR/all_urls.txt" > "$OUT_DIR/param_keys.txt"

# DNS/CDN analysis
dnsx -l "$OUT_DIR/all_subs.txt" -o "$OUT_DIR/dnsx.txt"
cdncheck -i "$OUT_DIR/alive.txt" -o "$OUT_DIR/cdncheck.txt"

echo "✅ Recon completado. Revisa $OUT_DIR"
