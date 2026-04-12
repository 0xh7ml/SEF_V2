#!/bin/bash

# ============================================================
#  SEF — Subdomain Enumeration Framework
#  install.sh — No-root installer (reconFTW-style)
#  Usage: bash install.sh [--verbose]
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

VERBOSE=false
FAILED_TOOLS=()
SUCCESS_TOOLS=()

# ── All paths are user-space, no /usr/local/bin, no sudo ─────
SEF_DIR="$HOME/Tools"
GO_DIR="$HOME/go"
GO_BIN="$GO_DIR/bin"
GO_ROOT="$HOME/.local/go"
LOCAL_BIN="$HOME/.local/bin"
GF_DIR="$HOME/.gf"
REPOS_DIR="$SEF_DIR/repos"

mkdir -p "$SEF_DIR" "$GO_BIN" "$LOCAL_BIN" "$GF_DIR" "$REPOS_DIR"

logo() {
    echo -e "${CYAN}"
    echo " _____                      _ _        _     "
    echo "(_____)           _        | | |      | |    "
    echo "   _   ____   ___| |_  ____| | |   ___| | _  "
    echo "  | | |  _ \\ /___|  _)/ _  | | |  /___| || \\ "
    echo " _| |_| | | |___ | |_( ( | | | |_|___ | | | |"
    echo "(_____|_| |_(___/ \\___\\_|\\||_|_|_(_(___/|_| |_|"
    echo -e "${NC}"
    echo -e "${BOLD}     Subdomain Enumeration Framework — installer v2.1${NC}"
    echo -e "     All tools install to user-space — no sudo needed"
    echo ""
}

usage() {
    echo "Usage: bash install.sh [--verbose]"
    echo "  --verbose    Show full output from tool installations"
    exit 0
}

for arg in "$@"; do
    case $arg in
        --verbose) VERBOSE=true ;;
        --help|-h) usage ;;
    esac
done

logo

# ── Bail if accidentally run as root ─────────────────────────
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}[!] Do NOT run as root. Run as your normal user:${NC}"
    echo -e "    ${BOLD}bash install.sh${NC}"
    exit 1
fi

echo -e "${GREEN}[+] User home  : ${BOLD}$HOME${NC}"
echo -e "${GREEN}[+] Tools dir  : ${BOLD}$SEF_DIR${NC}"
echo -e "${GREEN}[+] Go bin     : ${BOLD}$GO_BIN${NC}"
echo -e "${GREEN}[+] Local bin  : ${BOLD}$LOCAL_BIN${NC}"
echo ""

# ── PATH setup ───────────────────────────────────────────────
export PATH="$GO_ROOT/bin:$GO_BIN:$LOCAL_BIN:$HOME/.local/bin:$PATH"
export GOROOT="$GO_ROOT"
export GOPATH="$GO_DIR"
export GOBIN="$GO_BIN"

add_to_path() {
    local line="$1"
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -f "$rc" ] && grep -qxF "$line" "$rc" || echo "$line" >> "$rc" 2>/dev/null
    done
}

add_to_path "export GOROOT=$GO_ROOT"
add_to_path "export GOPATH=$GO_DIR"
add_to_path "export GOBIN=$GO_BIN"
add_to_path "export PATH=\$PATH:$GO_ROOT/bin:$GO_BIN:$LOCAL_BIN"

# ── Helpers ───────────────────────────────────────────────────
run_quiet() {
    if $VERBOSE; then
        "$@"
    else
        "$@" &>/dev/null
    fi
}

mark_ok()   { SUCCESS_TOOLS+=("$1"); echo -e "  ${GREEN}✓${NC} $1"; }
mark_fail() { FAILED_TOOLS+=("$1");  echo -e "  ${RED}✗${NC} $1 — FAILED"; }
step()      { echo -e "\n${YELLOW}${BOLD}━━━ $* ━━━${NC}"; }
sub_step()  { echo -e "  ${CYAN}→${NC} $*"; }

# ── Go installer (user-space, no sudo) ───────────────────────
install_golang() {
    step "Go language runtime"

    if command -v go &>/dev/null; then
        echo -e "  ${GREEN}✓ Go already in PATH: $(go version | awk '{print $3}')${NC}"
        export GOROOT=$(go env GOROOT 2>/dev/null || echo "$GO_ROOT")
        return
    fi

    if [ -f "$GO_ROOT/bin/go" ]; then
        echo -e "  ${GREEN}✓ Go already installed at $GO_ROOT${NC}"
        export PATH="$GO_ROOT/bin:$PATH"
        return
    fi

    sub_step "Downloading Go to $GO_ROOT (no sudo)..."
    local GO_VERSION="1.22.4"
    local ARCH
    case $(uname -m) in
        x86_64)        ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *)
            echo -e "  ${RED}✗ Unsupported architecture: $(uname -m)${NC}"
            echo -e "  ${YELLOW}Install Go manually: https://go.dev/dl/${NC}"
            return ;;
    esac

    local tarball="go${GO_VERSION}.linux-${ARCH}.tar.gz"
    if run_quiet wget -q "https://go.dev/dl/${tarball}" -O "/tmp/${tarball}"; then
        rm -rf "$GO_ROOT"
        mkdir -p "$HOME/.local"
        tar -C "$HOME/.local" -xzf "/tmp/${tarball}"
        mv "$HOME/.local/go" "$GO_ROOT"
        rm -f "/tmp/${tarball}"
        export PATH="$GO_ROOT/bin:$PATH"
        echo -e "  ${GREEN}✓ Go ${GO_VERSION} installed to $GO_ROOT${NC}"
    else
        echo -e "  ${RED}✗ Failed to download Go — install manually: https://go.dev/dl/${NC}"
    fi
}

# ── System dep checker (warn only, no apt/yum) ───────────────
check_system_deps() {
    step "System dependencies"
    local missing=()
    local deps=(git curl wget python3 pip3 make gcc cmake jq unzip)

    for dep in "${deps[@]}"; do
        if command -v "$dep" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $dep"
        else
            missing+=("$dep")
            echo -e "  ${YELLOW}⚠${NC} $dep — not found"
        fi
    done

    if ldconfig -p 2>/dev/null | grep -q libpcap || [ -f /usr/include/pcap.h ]; then
        echo -e "  ${GREEN}✓${NC} libpcap"
    else
        missing+=("libpcap-dev")
        echo -e "  ${YELLOW}⚠${NC} libpcap-dev — not found"
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        echo -e "  ${YELLOW}Missing system packages: ${missing[*]}${NC}"
        echo -e "  ${YELLOW}Install them once with sudo (only system packages need it):${NC}"
        if [ -f /etc/debian_version ]; then
            echo -e "    ${BOLD}sudo apt-get install -y ${missing[*]}${NC}"
        elif [ -f /etc/redhat-release ]; then
            echo -e "    ${BOLD}sudo yum install -y ${missing[*]}${NC}"
        fi
        echo -e "  ${YELLOW}Continuing — some tools may fail without these.${NC}"
    else
        echo -e "  ${GREEN}All system deps present${NC}"
    fi
}

# ── uv installer (user-space Python tool manager) ────────────
install_uv() {
    step "uv (Python tool manager)"
    if command -v uv &>/dev/null; then
        echo -e "  ${GREEN}✓ uv already installed: $(uv --version)${NC}"
        return
    fi

    sub_step "Installing uv to $HOME/.local/bin..."
    if curl -LsSf https://astral.sh/uv/install.sh | run_quiet sh; then
        export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
        add_to_path "export PATH=\$PATH:\$HOME/.cargo/bin"
        echo -e "  ${GREEN}✓ uv installed${NC}"
    else
        echo -e "  ${YELLOW}⚠ uv install failed — Python tools will use pip3 --user fallback${NC}"
    fi
}

# ── Go tool installer ─────────────────────────────────────────
install_go_tool() {
    local name=$1
    local pkg=$2
    local bin=${3:-$name}

    if [ -f "$GO_BIN/$bin" ]; then
        mark_ok "$name"
        return
    fi

    if command -v "$bin" &>/dev/null; then
        mark_ok "$name (system)"
        return
    fi

    if ! command -v go &>/dev/null; then
        mark_fail "$name (Go not found)"
        return
    fi

    if GOPATH="$GO_DIR" GOBIN="$GO_BIN" run_quiet go install "${pkg}@latest"; then
        if [ -f "$GO_BIN/$bin" ]; then
            mark_ok "$name"
        else
            mark_fail "$name (binary missing after install)"
        fi
    else
        mark_fail "$name"
    fi
}

# ── Python tool installer ─────────────────────────────────────
install_python_tool() {
    local name=$1
    local repo=$2
    local bin=${3:-$name}

    if command -v "$bin" &>/dev/null || [ -f "$HOME/.local/bin/$bin" ]; then
        mark_ok "$name"
        return
    fi

    if command -v uv &>/dev/null; then
        if run_quiet uv tool install "git+https://github.com/${repo}.git"; then
            export PATH="$HOME/.local/bin:$PATH"
            mark_ok "$name"
            return
        fi
    fi

    if command -v pip3 &>/dev/null; then
        if run_quiet pip3 install --user "git+https://github.com/${repo}.git"; then
            export PATH="$HOME/.local/bin:$PATH"
            mark_ok "$name (pip --user)"
            return
        fi
    fi

    mark_fail "$name"
}

# ── Repo clone + build ────────────────────────────────────────
clone_and_build() {
    local name=$1
    local repo=$2
    local dest="$REPOS_DIR/$name"

    if [ -d "$dest" ]; then
        mark_ok "$name (already cloned)"
        return
    fi

    sub_step "Cloning $name..."
    if ! run_quiet git clone "https://github.com/${repo}.git" "$dest"; then
        mark_fail "$name (clone failed)"
        return
    fi

    case $name in
        massdns)
            cd "$dest"
            if run_quiet make; then
                if [ -f "$dest/bin/massdns" ]; then
                    cp "$dest/bin/massdns" "$LOCAL_BIN/massdns"
                    chmod +x "$LOCAL_BIN/massdns"
                    mark_ok "massdns → $LOCAL_BIN/massdns"
                else
                    mark_fail "massdns (binary not found after make)"
                fi
            else
                mark_fail "massdns (make failed — is gcc/libpcap-dev installed?)"
            fi
            cd - &>/dev/null
            ;;
        gf)
            if GOPATH="$GO_DIR" GOBIN="$GO_BIN" run_quiet go install "github.com/tomnomnom/gf@latest"; then
                [ -d "$dest/examples" ] && cp "$dest/examples/"*.json "$GF_DIR/" 2>/dev/null
                mark_ok "gf → $GO_BIN/gf"
            else
                mark_fail "gf"
            fi
            ;;
        Gf-Patterns)
            cp "$dest/"*.json "$GF_DIR/" 2>/dev/null
            mark_ok "Gf-Patterns → $GF_DIR"
            ;;
    esac
}

# ── Wordlist downloader ───────────────────────────────────────
download_wordlists() {
    step "Wordlists & resolvers (→ $SEF_DIR)"

    declare -A WORDLISTS=(
        ["resolvers.txt"]="https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt"
        ["resolvers_trusted.txt"]="https://gist.githubusercontent.com/six2dez/ae9ed7e5c786461868abd3f2344401b6/raw"
        ["subdomains_n0kovo_big.txt"]="https://raw.githubusercontent.com/n0kovo/n0kovo_subdomains/main/n0kovo_subdomains_huge.txt"
        ["subdomains-top1million-5000.txt"]="https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt"
        ["permutations_list.txt"]="https://raw.githubusercontent.com/six2dez/reconftw/main/data/wordlists/permutations_list.txt"
        ["permutations_list_short.txt"]="https://raw.githubusercontent.com/six2dez/reconftw/main/data/wordlists/permutations_list_short.txt"
    )

    for file in "${!WORDLISTS[@]}"; do
        local dest="$SEF_DIR/$file"
        if [ -f "$dest" ] && [ -s "$dest" ]; then
            echo -e "  ${GREEN}✓${NC} $file (exists)"
        else
            sub_step "Downloading $file..."
            if curl -sL "${WORDLISTS[$file]}" -o "$dest"; then
                echo -e "  ${GREEN}✓${NC} $file ($(wc -l < "$dest") lines)"
            else
                echo -e "  ${RED}✗${NC} $file — download failed"
            fi
        fi
    done
}

# ── Summary ───────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║           INSTALLATION SUMMARY               ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""

    if [ ${#SUCCESS_TOOLS[@]} -gt 0 ]; then
        echo -e "${GREEN}${BOLD}Installed (${#SUCCESS_TOOLS[@]}):${NC}"
        for t in "${SUCCESS_TOOLS[@]}"; do
            echo -e "  ${GREEN}✓${NC} $t"
        done
    fi

    if [ ${#FAILED_TOOLS[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}${BOLD}Failed (${#FAILED_TOOLS[@]}):${NC}"
        for t in "${FAILED_TOOLS[@]}"; do
            echo -e "  ${RED}✗${NC} $t"
        done
        echo ""
        echo -e "${YELLOW}Tip: run ${BOLD}bash install.sh --verbose${YELLOW} to see failure details.${NC}"
    else
        echo -e "${GREEN}${BOLD}All tools installed successfully!${NC}"
    fi

    echo ""
    echo -e "${BOLD}Locations:${NC}"
    echo -e "  Go tools    → ${CYAN}$GO_BIN${NC}"
    echo -e "  Python tools→ ${CYAN}$HOME/.local/bin${NC}"
    echo -e "  massdns     → ${CYAN}$LOCAL_BIN/massdns${NC}"
    echo -e "  Wordlists   → ${CYAN}$SEF_DIR${NC}"
    echo -e "  gf patterns → ${CYAN}$GF_DIR${NC}"
    echo ""
    echo -e "${YELLOW}⚡ Reload your shell:  ${BOLD}source ~/.bashrc${NC}"
    echo -e "${YELLOW}⚡ Run enumeration:    ${BOLD}bash sef -d example.com${NC}"
}

# ── MAIN ──────────────────────────────────────────────────────
main() {
    check_system_deps
    install_uv
    install_golang

    step "Go tools (→ $GO_BIN)"
    install_go_tool "subfinder"              "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    install_go_tool "dnsx"                   "github.com/projectdiscovery/dnsx/cmd/dnsx"
    install_go_tool "httpx"                  "github.com/projectdiscovery/httpx/cmd/httpx"
    install_go_tool "puredns"                "github.com/d3mondev/puredns/v2"
    install_go_tool "anew"                   "github.com/tomnomnom/anew"
    install_go_tool "unfurl"                 "github.com/tomnomnom/unfurl"
    install_go_tool "github-subdomains"      "github.com/gwen001/github-subdomains"
    install_go_tool "gitlab-subdomains"      "github.com/gwen001/gitlab-subdomains"
    install_go_tool "gotator"                "github.com/Josue87/gotator"
    install_go_tool "analyticsrelationships" "github.com/Josue87/analyticsrelationships"
    install_go_tool "roboxtractor"           "github.com/Josue87/roboxtractor"
    install_go_tool "dsieve"                 "github.com/trickest/dsieve"
    install_go_tool "inscope"                "github.com/tomnomnom/hacks/inscope"
    install_go_tool "cdncheck"               "github.com/projectdiscovery/cdncheck/cmd/cdncheck"
    install_go_tool "tlsx"                   "github.com/projectdiscovery/tlsx/cmd/tlsx"
    install_go_tool "crt"                    "github.com/cemulus/crt"
    install_go_tool "mapcidr"                "github.com/projectdiscovery/mapcidr/cmd/mapcidr"
    install_go_tool "urlfinder"              "github.com/projectdiscovery/urlfinder/cmd/urlfinder"
    install_go_tool "csprecon"               "github.com/edoardottt/csprecon/cmd/csprecon"
    install_go_tool "katana"                 "github.com/projectdiscovery/katana/cmd/katana"
    install_go_tool "asnmap"                 "github.com/projectdiscovery/asnmap/cmd/asnmap"

    step "Python tools (→ ~/.local/bin)"
    install_python_tool "dnsvalidator" "vortexau/dnsvalidator"
    install_python_tool "waymore"      "xnl-h4ck3r/waymore"
    install_python_tool "urless"       "xnl-h4ck3r/urless"

    step "Repositories (→ $REPOS_DIR)"
    clone_and_build "massdns"     "blechschmidt/massdns"

    download_wordlists
    print_summary
}

main