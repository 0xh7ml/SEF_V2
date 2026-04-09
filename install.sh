#!/bin/bash

# SEF v2 Enhanced Debian-based Linux Installer
# Optimized for Debian, Ubuntu, Linux Mint, Elementary OS, and other Debian-based distributions
# x86_64 architecture support
# @0xh7ml

logo(){
echo " _____                      _ _        _     ";
echo "(_____)           _        | | |      | |    ";
echo "   _   ____   ___| |_  ____| | |   ___| | _  ";
echo "  | | |  _ \ /___|  _)/ _  | | |  /___| || \ ";
echo " _| |_| | | |___ | |_( ( | | | |_|___ | | | |";
echo "(_____|_| |_(___/ \___\_||_|_|_(_(___/|_| |_|";
echo "                                             ";
echo "  Enhanced Debian-based OS Installer v2.1   ";
echo "           Run it as a root user             ";
echo "                 @0xh7ml                     ";
echo "                                             ";
}

logo

# Clean line endings
sed -i 's/\r//' install.sh
sed -i 's/\r//' sef

# System detection and validation
detect_system() {
    if [[ ! -f /etc/os-release ]]; then
        echo -e "${RED}[!] Cannot detect OS. This installer is designed for Debian-based systems.${NC}"
        exit 1
    fi
    
    source /etc/os-release
    
    # Check if it's Debian-based (Ubuntu, Debian, Mint, Elementary, etc.)
    local is_debian_based=false
    
    # Check for ID_LIKE or common Debian-based IDs
    if [[ "$ID" == "debian" || "$ID" == "ubuntu" || "$ID_LIKE" == *"debian"* ]]; then
        is_debian_based=true
    fi
    
    if [[ "$is_debian_based" != true ]]; then
        echo -e "${RED}[!] This installer is optimized for Debian-based systems only.${NC}"
        echo -e "${RED}[!] Detected: $PRETTY_NAME (ID: $ID)${NC}"
        exit 1
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" ]]; then
        echo -e "${RED}[!] This installer supports x86_64 architecture only. Detected: $ARCH${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[+] System: $PRETTY_NAME ($ARCH)${NC}"
    echo -e "${GREEN}[+] Distribution: $ID (version $VERSION_ID)${NC}"
}

# Color codes for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[!] This script must be run as root${NC}"
   echo -e "${YELLOW}[*] Please run: sudo $0${NC}"
   exit 1
fi

# Detect and validate system
detect_system

# Update system packages
echo -e "${YELLOW}[*] Updating Debian-based system package lists...${NC}"
apt-get update -qq > /dev/null 2>&1

# Install essential dependencies for all Debian-based systems
echo -e "${YELLOW}[*] Installing essential dependencies...${NC}"
ESSENTIAL_PACKAGES=(
    "curl"
    "wget" 
    "git"
    "build-essential"
    "python3"
    "python3-pip"
    "unzip"
    "jq"
    "ca-certificates"
    "software-properties-common"
    "apt-transport-https"
)

for package in "${ESSENTIAL_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package "; then
        echo -e "${CYAN}[*] Installing $package...${NC}"
        apt-get install -y "$package" > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}[+] $package installed successfully${NC}"
        else
            echo -e "${RED}[!] Failed to install $package${NC}"
        fi
    else
        echo -e "${GREEN}[+] $package is already installed${NC}"
    fi
done

# Check if Go is already installed
GO_MIN_VERSION="1.20"
GO_INSTALLED=false

if command -v go &> /dev/null; then
    GO_CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    GO_VERSION_NUM=$(echo $GO_CURRENT_VERSION | cut -d. -f1,2)
    GO_MIN_NUM=$(echo $GO_MIN_VERSION | cut -d. -f1,2)

    if [ "$(printf '%s\n' "$GO_MIN_NUM" "$GO_VERSION_NUM" | sort -V | head -n1)" = "$GO_MIN_NUM" ]; then
        echo -e "${GREEN}[+] Go is already installed: $(go version)${NC}"
        GO_INSTALLED=true
    else
        echo -e "${YELLOW}[!] Go is installed but version $GO_CURRENT_VERSION is older than required $GO_MIN_VERSION${NC}"
        echo -e "${YELLOW}[*] Installing Go-Lang...${NC}"
    fi
fi

if [ "$GO_INSTALLED" = false ]; then
    # Install Golang
    echo -e "${YELLOW}[*] Installing Go-Lang...${NC}"
    GO_VERSION="1.23.5"
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz

    # Add Go to PATH
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
    source ~/.bashrc
    echo -e "${GREEN}[+] Go installed successfully${NC}"
fi

# Ensure Go is in PATH
export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

# Create Tools directory
mkdir -p "$HOME/Tools"
mkdir -p "$HOME/go/bin"

if [ ! -d "$HOME/Tools" ]; then
    echo -e "${RED}[!] Failed to create Tools directory${NC}"
    exit 1
fi
echo -e "${GREEN}[+] Tools directory ready${NC}"

# Enhanced function to check and install Go tools
install_go_tool() {
    local tool_name=$1
    local package_path=$2
    local binary_name=$3

    # Check if already installed
    if [ -f "/usr/bin/$binary_name" ]; then
        echo -e "${GREEN}[+] $tool_name is already installed${NC}"
        return 0
    fi

    # Install the tool directly to /usr/bin
    echo -e "${CYAN}[*] Installing $tool_name${NC}"
    export GOBIN=/usr/bin
    export GOPATH=$HOME/go
    export PATH=$PATH:/usr/local/go/bin:$GOBIN
    
    if timeout 300 go install "$package_path@latest" > /dev/null 2>&1; then
        if [ -f "/usr/bin/$binary_name" ]; then
            chmod 755 "/usr/bin/$binary_name"
            echo -e "${GREEN}[+] $tool_name installed${NC}"
            return 0
        else
            echo -e "${RED}[!] $tool_name installation failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}[!] $tool_name installation failed${NC}"
        return 1
    fi
}

# Enhanced function to check and install binary tools with better validation
install_binary_tool() {
    local tool_name=$1
    local binary_name=$2
    local install_cmd=$3
    
    echo -e "${CYAN}[*] Checking $tool_name...${NC}"
    
    # Check if tool exists and is functional
    if command -v "$binary_name" &> /dev/null; then
        if timeout 5 "$binary_name" --version &> /dev/null || timeout 5 "$binary_name" -v &> /dev/null || timeout 5 "$binary_name" -h &> /dev/null; then
            local version_output=$("$binary_name" --version 2>/dev/null | head -1 || echo "installed")
            echo -e "${GREEN}[+] $tool_name is already installed and functional: $version_output${NC}"
            return 0
        else
            echo -e "${YELLOW}[!] $tool_name binary exists but is not functional, reinstalling...${NC}"
        fi
    fi
    
    # Install the tool with retry logic
    echo -e "${YELLOW}[*] Installing $tool_name${NC}"
    
    if timeout 300 bash -c "$install_cmd"; then
        # Verify installation
        if timeout 5 "$binary_name" --version &> /dev/null || timeout 5 "$binary_name" -v &> /dev/null || timeout 5 "$binary_name" -h &> /dev/null; then
            echo -e "${GREEN}[+] $tool_name installed successfully${NC}"
            return 0
        else
            echo -e "${RED}[!] $tool_name installed but not functional${NC}"
            return 1
        fi
    else
        echo -e "${RED}[!] $tool_name installation failed or timed out${NC}"
        return 1
    fi
}

# Retry function with exponential backoff
retry_cmd() {
    local attempts=$1
    local delay=$2
    shift 2
    local n=0
    until "$@"; do
        n=$((n + 1))
        if ((n >= attempts)); then
            return 1
        fi
        sleep $((delay * n))
    done
}

# Initialize statistics tracking
declare -A TOOL_STATS
TOOL_STATS[go_ok]=0
TOOL_STATS[go_fail]=0
TOOL_STATS[go_total]=0
TOOL_STATS[bin_ok]=0
TOOL_STATS[bin_fail]=0
TOOL_STATS[bin_total]=0
TOOL_STATS[repo_ok]=0
TOOL_STATS[repo_fail]=0
TOOL_STATS[repo_total]=0

failed_go_tools=()
failed_binary_tools=()
failed_repos=()

echo -e "${YELLOW}[*] Starting tool installation process...${NC}"
echo ""

# Install Go tools with statistics tracking
echo -e "${BLUE}=== Installing Go Tools ===${NC}"
GO_TOOLS=(
    "subfinder:github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    "puredns:github.com/d3mondev/puredns/v2"
    "httpx:github.com/projectdiscovery/httpx/cmd/httpx"
    "chaos:github.com/projectdiscovery/chaos-client/cmd/chaos"
    "assetfinder:github.com/tomnomnom/assetfinder"
    "anew:github.com/tomnomnom/anew"
    "gotator:github.com/Josue87/gotator"
    "github-subdomains:github.com/gwen001/github-subdomains"
    "dnsx:github.com/projectdiscovery/dnsx/cmd/dnsx"
    "tlsx:github.com/projectdiscovery/tlsx/cmd/tlsx"
)

TOOL_STATS[go_total]=${#GO_TOOLS[@]}
go_step=0

for tool_entry in "${GO_TOOLS[@]}"; do
    ((go_step++))
    IFS=':' read -r binary_name package_path <<< "$tool_entry"
    
    if install_go_tool "$binary_name" "$package_path" "$binary_name"; then
        ((TOOL_STATS[go_ok]++))
    else
        ((TOOL_STATS[go_fail]++))
        failed_go_tools+=("$binary_name")
    fi
done

echo ""

# Install Binary Tools - Amass
echo -e "${BLUE}=== Installing Binary Tools ===${NC}"

amass_install() {
    echo -e "${CYAN}[*] Fetching latest Amass version...${NC}"
    AMASS_VERSION=$(retry_cmd 3 2 curl -s https://api.github.com/repos/owasp-amass/amass/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$AMASS_VERSION" ]]; then
        echo -e "${RED}[!] Could not fetch Amass version${NC}"
        return 1
    fi
    
    echo -e "${CYAN}[*] Downloading Amass ${AMASS_VERSION}...${NC}"
    local amass_file="amass_${AMASS_VERSION#v}_linux_amd64.zip"
    
    if retry_cmd 3 2 wget -q https://github.com/owasp-amass/amass/releases/download/${AMASS_VERSION}/${amass_file} -O /tmp/${amass_file}; then
        cd /tmp
        unzip -q ${amass_file} 2>/dev/null
        if [ -f "amass_${AMASS_VERSION#v}_linux_amd64/amass" ]; then
            mv "amass_${AMASS_VERSION#v}_linux_amd64/amass" /usr/local/bin/
            rm -rf "amass_${AMASS_VERSION#v}_linux_amd64" ${amass_file}
            cd - > /dev/null
            return 0
        else
            echo -e "${RED}[!] Amass binary not found in archive${NC}"
            cd - > /dev/null
            return 1
        fi
    else
        echo -e "${RED}[!] Failed to download Amass${NC}"
        return 1
    fi
}

TOOL_STATS[bin_total]=1
if install_binary_tool "Amass" "amass" "$(declare -f amass_install); amass_install"; then
    ((TOOL_STATS[bin_ok]++))
else
    ((TOOL_STATS[bin_fail]++))
    failed_binary_tools+=("amass")
fi

echo ""
echo -e "${BLUE}=== Installing Repository Tools ===${NC}"

TOOL_STATS[repo_total]=2
ctfr_step=0

echo -e "${CYAN}[*] Checking ctfr${NC}"
if [ ! -d ~/Tools/ctfr ]; then
    echo -e "${YELLOW}[*] Cloning ctfr repository...${NC}"
    if retry_cmd 3 2 git clone https://github.com/UnaPibaGeek/ctfr.git ~/Tools/ctfr 2>/dev/null; then
        echo -e "${YELLOW}[*] Installing Python dependencies for ctfr...${NC}"
        if pip3 install -q argparse requests --break-system-packages 2>/dev/null; then
            echo -e "${GREEN}[+] ctfr installed successfully${NC}"
            ((TOOL_STATS[repo_ok]++))
        else
            echo -e "${RED}[!] Failed to install ctfr dependencies${NC}"
            ((TOOL_STATS[repo_fail]++))
            failed_repos+=("ctfr")
        fi
    else
        echo -e "${RED}[!] Failed to clone ctfr repository${NC}"
        ((TOOL_STATS[repo_fail]++))
        failed_repos+=("ctfr")
    fi
else
    echo -e "${GREEN}[+] ctfr is already installed${NC}"
    ((TOOL_STATS[repo_ok]++))
fi

# Install massdns for ultra-fast DNS resolution
echo -e "${CYAN}[*] Checking massdns${NC}"
if command -v massdns &> /dev/null; then
    echo -e "${GREEN}[+] massdns is already installed and functional${NC}"
    ((TOOL_STATS[repo_ok]++))
else
    echo -e "${YELLOW}[*] Installing massdns${NC}"
    if [ ! -d ~/massdns ]; then
        if retry_cmd 3 2 git clone https://github.com/blechschmidt/massdns.git ~/massdns 2>/dev/null; then
            cd ~/massdns
            if make &>/dev/null; then
                if [ -f ~/massdns/bin/massdns ]; then
                    mv ~/massdns/bin/massdns /usr/local/bin/
                    echo -e "${GREEN}[+] massdns installed successfully${NC}"
                    ((TOOL_STATS[repo_ok]++))
                else
                    echo -e "${RED}[!] massdns binary not found after compilation${NC}"
                    ((TOOL_STATS[repo_fail]++))
                    failed_repos+=("massdns")
                fi
            else
                echo -e "${RED}[!] massdns compilation failed${NC}"
                ((TOOL_STATS[repo_fail]++))
                failed_repos+=("massdns")
            fi
            cd - &>/dev/null
        else
            echo -e "${RED}[!] Failed to clone massdns repository${NC}"
            ((TOOL_STATS[repo_fail]++))
            failed_repos+=("massdns")
        fi
    fi
fi

echo ""

# Wordlists and Resolvers (from reconftw - improved for better results)
echo -e "${BLUE}=== Downloading Wordlists and Resolvers ===${NC}"

# Download helper with improved retry and error handling
download_file() {
    local url=$1
    local output=$2
    local description=$3
    local attempts=5
    local attempt=0
    
    echo -e "${CYAN}[*] $description${NC}"
    
    while [ $attempt -lt $attempts ]; do
        ((attempt++))
        
        if wget -L --connect-timeout=15 --timeout=120 -O "$output" "$url" 2>/dev/null; then
            if [ -s "$output" ]; then
                echo -e "${GREEN}[+] Downloaded: $(basename $output)${NC}"
                return 0
            else
                echo -e "${YELLOW}[!] Downloaded file is empty, retrying...${NC}"
                rm -f "$output"
            fi
        else
            echo -e "${YELLOW}[!] Download attempt $attempt/$attempts failed, retrying...${NC}"
            rm -f "$output"
        fi
        
        if [ $attempt -lt $attempts ]; then
            sleep $((attempt * 2))
        fi
    done
    
    echo -e "${RED}[!] Failed to download after $attempts attempts: $(basename $output)${NC}"
    return 1
}

# Main subdomain wordlist (from SecLists - comprehensive)
download_file "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt" \
    "$HOME/Tools/subdomains.txt" "Downloading main subdomain wordlist (5000 entries)"

# Large subdomain wordlist for deep enumeration (assetnote)
download_file "https://raw.githubusercontent.com/assetnote/commonspeak2-wordlists/master/subdomains/subdomains.txt" \
    "$HOME/Tools/subdomains_big.txt" "Downloading large subdomain wordlist (100000+ entries)"

# Full permutation wordlist (from reconftw - 1000+ entries for comprehensive permutations)
download_file "https://raw.githubusercontent.com/six2dez/reconftw/main/data/wordlists/permutations_list.txt" \
    "$HOME/Tools/permutations_list.txt" "Downloading full permutation list"

# Short permutation wordlist (from reconftw - for faster scanning)
download_file "https://raw.githubusercontent.com/six2dez/reconftw/main/data/wordlists/permutations_list_short.txt" \
    "$HOME/Tools/permutations_list_short.txt" "Downloading short permutation list"

# Large resolver list (from trickest - maintained regularly)
download_file "https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt" \
    "$HOME/Tools/resolvers.txt" "Downloading resolver list from trickest"

# DNS record type wordlists for additional enumeration
download_file "https://raw.githubusercontent.com/six2dez/reconftw/main/data/wordlists/srv_prefixes.txt" \
    "$HOME/Tools/srv_prefixes.txt" "Downloading SRV prefixes list"

# Trusted resolvers (from reconftw - optimized by six2dez)
echo -e "${CYAN}[*] Creating trusted resolvers list${NC}"
cat > "$HOME/Tools/resolvers_trusted.txt" << 'EOF'
8.8.8.8
8.8.4.4
1.1.1.1
1.0.0.1
9.9.9.9
149.112.112.112
1.0.0.3
208.67.222.222
208.67.220.220
64.6.64.6
64.6.65.6
EOF
echo -e "${GREEN}[+] Created trusted resolvers list${NC}"

# Create GitHub/GitLab tokens placeholder
echo -e "${CYAN}[*] Creating token placeholders${NC}"
touch "$HOME/Tools/.github_tokens"
touch "$HOME/Tools/.gitlab_tokens"
echo -e "${GREEN}[+] Created token files${NC}"

# Ensure all Go tools are in system PATH
echo ""
echo -e "${BLUE}=== Finalizing Installation ===${NC}"
echo -e "${CYAN}[*] All tools have been installed to /usr/bin${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Installation Summary Report${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""

# Display statistics
echo -e "${BLUE}Go Tools:${NC}"
echo -e "  Total: ${TOOL_STATS[go_total]} | ${GREEN}Success: ${TOOL_STATS[go_ok]}${NC} | ${RED}Failed: ${TOOL_STATS[go_fail]}${NC}"
if [ ${#failed_go_tools[@]} -gt 0 ]; then
    echo -e "  ${RED}Failed tools: ${failed_go_tools[*]}${NC}"
fi

echo ""
echo -e "${BLUE}Binary Tools:${NC}"
echo -e "  Total: ${TOOL_STATS[bin_total]} | ${GREEN}Success: ${TOOL_STATS[bin_ok]}${NC} | ${RED}Failed: ${TOOL_STATS[bin_fail]}${NC}"
if [ ${#failed_binary_tools[@]} -gt 0 ]; then
    echo -e "  ${RED}Failed tools: ${failed_binary_tools[*]}${NC}"
fi

echo ""
echo -e "${BLUE}Repository Tools:${NC}"
echo -e "  Total: ${TOOL_STATS[repo_total]} | ${GREEN}Success: ${TOOL_STATS[repo_ok]}${NC} | ${RED}Failed: ${TOOL_STATS[repo_fail]}${NC}"
if [ ${#failed_repos[@]} -gt 0 ]; then
    echo -e "  ${RED}Failed repositories: ${failed_repos[*]}${NC}"
fi

echo ""
echo -e "${BLUE}Installed Tools:${NC}"
echo "  Go-based tools:"
echo "    • Subfinder (passive subdomain discovery)"
echo "    • Assetfinder (subdomain enumeration)"
echo "    • Puredns (mass DNS resolution)"
echo "    • Httpx (HTTP probing)"
echo "    • Chaos (bug bounty subdomains)"
echo "    • Gotator (permutation generation)"
echo "    • DNSx (DNS resolution toolkit)"
echo "    • Crobat (multi-source subdomains)"
echo "    • Github-subdomains (GitHub search)"
echo "    • Gitlab-subdomains (GitLab search)"
echo "    • Tlsx (TLS certificate discovery)"
echo "    • Anew (unique filtering)"
echo ""
echo "  Binary tools:"
echo "    • Amass (comprehensive reconnaissance)"
echo ""
echo "  Repository tools:"
echo "    • Ctfr (CRT.sh enumeration)"
echo "    • Massdns (ultra-fast DNS resolution)"
echo ""

echo -e "${BLUE}Downloaded Resources:${NC}"
echo "  Wordlists:"
echo "    • ~/Tools/subdomains.txt (5000 entries)"
echo "    • ~/Tools/subdomains_big.txt (100000+ entries)"
echo "    • ~/Tools/permutations_list.txt (1000+ entries)"
echo "    • ~/Tools/permutations_list_short.txt (fast scanning)"
echo ""
echo "  Resolvers:"
echo "    • ~/Tools/resolvers_trusted.txt (optimized)"
echo "    • ~/Tools/resolvers.txt (large list)"
echo "    • ~/Tools/srv_prefixes.txt (SRV records)"
echo ""

# Calculate total statistics
total_tools=$((${TOOL_STATS[go_ok]} + ${TOOL_STATS[bin_ok]} + ${TOOL_STATS[repo_ok]}))
total_failed=$((${TOOL_STATS[go_fail]} + ${TOOL_STATS[bin_fail]} + ${TOOL_STATS[repo_fail]}))
total_attempted=$((${TOOL_STATS[go_total]} + ${TOOL_STATS[bin_total]} + ${TOOL_STATS[repo_total]}))

echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${BLUE}Overall Results:${NC}"
echo -e "  Total Attempted: $total_attempted"
echo -e "  ${GREEN}Successfully Installed: $total_tools${NC}"
echo -e "  ${RED}Failed Installations: $total_failed${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""

if [ $total_failed -eq 0 ]; then
    echo -e "${GREEN}[✓] Installation completed successfully!${NC}"
else
    echo -e "${YELLOW}[!] Installation completed with some failures.${NC}"
    echo -e "${YELLOW}[*] Re-run the installer to retry failed items.${NC}"
fi

echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "  1. Source your shell profile:"
echo -e "     ${CYAN}source ~/.bashrc${NC}"
echo ""
echo "  2. Configure API keys:"
echo -e "     ${CYAN}# GitHub/GitLab tokens${NC}"
echo -e "     ${CYAN}nano ~/Tools/.github_tokens${NC}"
echo -e "     ${CYAN}nano ~/Tools/.gitlab_tokens${NC}"
echo ""
echo "  3. Verify installation:"
echo -e "     ${CYAN}subfinder --version${NC}"
echo -e "     ${CYAN}amass --version${NC}"
echo -e "     ${CYAN}findomain --version${NC}"
echo ""
echo -e "${GREEN}[+] Setup complete! Happy hunting!${NC}"
