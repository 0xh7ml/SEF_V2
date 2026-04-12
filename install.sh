#!/bin/bash

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

logo() {
    echo " _____                      _ _        _     "
    echo "(_____)           _        | | |      | |    "
    echo "   _   ____   ___| |_  ____| | |   ___| | _  "
    echo "  | | |  _ \\ /___|  _)/ _  | | |  /___| || \\ "
    echo " _| |_| | | |___ | |_( ( | | | |_|___ | | | |"
    echo "(_____|_| |_(___/ \\___\\_|\\||_|_|_(_(___/|_| |_|"
    echo "                                             "
    echo "           Run it as a root user             "
    echo "                                             "
    echo "                 @0xh7ml                     "
}

logo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Detect the real user who invoked sudo
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(eval echo ~$SUDO_USER)
else
    REAL_USER="$USER"
    REAL_HOME="$HOME"
fi

echo -e "${GREEN}[+] Installing for user: $REAL_USER${NC}"
echo -e "${GREEN}[+] Using home directory: $REAL_HOME${NC}"

# Remove Windows line endings
sed -i 's/\r//' install.sh
sed -i 's/\r//' sef

# Function to check and install dependencies
check_dependencies() {
    echo -e "${YELLOW}[*] Checking dependencies...${NC}"

    local deps=("git" "wget" "curl" "go" "python3" "pip3" "make" "gcc")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            missing+=("$dep")
        else
            echo -e "${GREEN}[+] $dep is installed${NC}"
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}[*] Installing missing dependencies: ${missing[*]}${NC}"

        # Detect OS
        if [ -f /etc/debian_version ]; then
            apt-get update -qq &>/dev/null
            apt-get install -y git wget curl golang python3 python3-pip make gcc unzip &>/dev/null
        elif [ -f /etc/redhat-release ]; then
            yum install -y git wget curl golang python3 python3-pip make gcc unzip &>/dev/null
        else
            echo -e "${RED}[!] Unsupported OS. Please install dependencies manually.${NC}"
            exit 1
        fi
    fi

    # Set Go PATH for real user
    export PATH=$PATH:/usr/local/go/bin:$REAL_HOME/go/bin
    echo "export PATH=\$PATH:/usr/local/go/bin:$REAL_HOME/go/bin" >> "$REAL_HOME/.bashrc"
}

# Function to check and install Go tools
install_go_tool() {
    local tool_name=$1
    local package_path=$2
    local binary_name=$3

    if command -v $binary_name &> /dev/null; then
        echo -e "${GREEN}[+] $tool_name is already installed${NC}"
        return
    fi

    if [ -f $REAL_HOME/go/bin/$binary_name ]; then
        ln -sf $REAL_HOME/go/bin/$binary_name /usr/local/bin/$binary_name
        echo -e "${GREEN}[+] $tool_name is already installed${NC}"
        return
    fi

    echo -e "${YELLOW}[*] Installing $tool_name...${NC}"
    go install $package_path@latest &>/dev/null

    if [ -f $REAL_HOME/go/bin/$binary_name ]; then
        ln -sf $REAL_HOME/go/bin/$binary_name /usr/local/bin/$binary_name
        echo -e "${GREEN}[+] $tool_name installed successfully${NC}"
    else
        echo -e "${RED}[!] Failed to install $tool_name${NC}"
    fi
}

# Function to install Amass
install_amass() {
    if command -v amass &> /dev/null; then
        echo -e "${GREEN}[+] Amass is already installed${NC}"
        return
    fi

    echo -e "${YELLOW}[*] Installing Amass...${NC}"
    AMASS_VERSION=$(curl -s https://api.github.com/repos/owasp-amass/amass/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    cd /tmp
    if wget -q https://github.com/owasp-amass/amass/releases/download/${AMASS_VERSION}/amass_${AMASS_VERSION#v}_linux_amd64.tar.gz ; then
        tar -xzf amass_${AMASS_VERSION#v}_linux_amd64.tar.gz
        if [ -f amass_${AMASS_VERSION#v}_linux_amd64/amass ]; then
            mv amass_${AMASS_VERSION#v}_linux_amd64/amass /usr/local/bin/
            rm -rf amass_*
            cd - &>/dev/null
            echo -e "${GREEN}[+] Amass installed successfully${NC}"
        else
            cd - &>/dev/null
            echo -e "${RED}[!] Failed to install Amass - extracted file not found${NC}"
        fi
    else
        cd - &>/dev/null
        echo -e "${RED}[!] Failed to download Amass${NC}"
    fi
}

# Function to install ctfr
install_ctfr() {
    if [ -d $REAL_HOME/Tools/ctfr ]; then
        echo -e "${GREEN}[+] ctfr is already installed${NC}"
        return
    fi

    echo -e "${YELLOW}[*] Installing ctfr...${NC}"
    mkdir -p $REAL_HOME/Tools
    git clone -q https://github.com/UnaPibaGeek/ctfr.git $REAL_HOME/Tools/ctfr &>/dev/null
    pip3 install -q --break-system-packages argparse requests 2>/dev/null || pip3 install -q --user argparse requests 2>/dev/null
    echo -e "${GREEN}[+] ctfr installed successfully${NC}"
}

# Function to download wordlists
download_wordlists() {
    echo -e "${YELLOW}[*] Downloading wordlists...${NC}"
    mkdir -p $REAL_HOME/Tools

    # Main subdomain wordlist
    if [ ! -f $REAL_HOME/Tools/subdomains-top1million-5000.txt ]; then
        echo -e "${YELLOW}[*] Downloading subdomains-top1million-5000.txt...${NC}"
        curl -s -o $REAL_HOME/Tools/subdomains-top1million-5000.txt \
            https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt
    else
        echo -e "${GREEN}[+] subdomains-top1million-5000.txt already exists${NC}"
    fi

    # Large wordlist
    if [ ! -f $REAL_HOME/Tools/subdomains.txt ]; then
        echo -e "${YELLOW}[*] Downloading subdomains.txt...${NC}"
        curl -s -o $REAL_HOME/Tools/subdomains.txt \
            https://raw.githubusercontent.com/assetnote/commonspeak2-wordlists/master/subdomains/subdomains.txt
    else
        echo -e "${GREEN}[+] subdomains.txt already exists${NC}"
    fi

    # Full permutation wordlist
    if [ ! -f $REAL_HOME/Tools/permutations_list.txt ]; then
        echo -e "${YELLOW}[*] Downloading permutations_list.txt...${NC}"
        curl -s -o $REAL_HOME/Tools/permutations_list.txt \
            https://raw.githubusercontent.com/six2dez/reconftw/main/data/wordlists/permutations_list.txt
    else
        echo -e "${GREEN}[+] permutations_list.txt already exists${NC}"
    fi

    # Short permutation wordlist
    if [ ! -f $REAL_HOME/Tools/permutations_list_short.txt ]; then
        echo -e "${YELLOW}[*] Downloading permutations_list_short.txt...${NC}"
        curl -s -o $REAL_HOME/Tools/permutations_list_short.txt \
            https://raw.githubusercontent.com/six2dez/reconftw/main/data/wordlists/permutations_list_short.txt
    else
        echo -e "${GREEN}[+] permutations_list_short.txt already exists${NC}"
    fi

    # Create resolvers.txt
    if [ ! -f $REAL_HOME/Tools/resolvers.txt ]; then
        echo -e "${YELLOW}[*] Creating resolvers.txt...${NC}"
        curl -s -o $REAL_HOME/Tools/resolvers.txt \
            https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt
    else
        echo -e "${GREEN}[+] resolvers.txt already exists${NC}"
    fi
}

# Main installation workflow
main() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    SEF Installer${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    # Step 1: Check dependencies
    check_dependencies

    # Step 2: Install Go tools
    echo ""
    echo -e "${YELLOW}[*] Installing Go tools...${NC}"
    install_go_tool "Subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder" "subfinder"
    install_go_tool "Assetfinder" "github.com/tomnomnom/assetfinder" "assetfinder"
    install_go_tool "Puredns" "github.com/d3mondev/puredns/v2" "puredns"
    install_go_tool "Httpx" "github.com/projectdiscovery/httpx/cmd/httpx" "httpx"
    install_go_tool "Gotator" "github.com/Josue87/gotator" "gotator"

    # Step 3: Install Amass
    install_amass

    # Step 4: Install ctfr
    install_ctfr

    # Step 5: Download wordlists
    download_wordlists

    # Step 6: Create symlinks for all Go tools
    echo ""
    echo -e "${YELLOW}[*] Creating symlinks...${NC}"
    mkdir -p $REAL_HOME/go/bin
    for tool in subfinder assetfinder puredns httpx gotator; do
        if [ -f $REAL_HOME/go/bin/$tool ] && [ ! -L /usr/local/bin/$tool ]; then
            ln -sf $REAL_HOME/go/bin/$tool /usr/local/bin/$tool
        fi
    done

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Installation Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${GREEN}[+] Tools installed:${NC}"
    echo "  - subfinder (passive subdomain scanner)"
    echo "  - ctfr (CSP subdomain scanner)"
    echo "  - assetfinder (passive subdomain scanner)"
    echo "  - amass (passive subdomain scanner)"
    echo "  - httpx (CSP subdomain scanner)"
    echo "  - puredns (active bruteforce)"
    echo "  - gotator (permutation scanner)"
    echo ""
    echo -e "${GREEN}[+] Wordlists downloaded:${NC}"
    echo "  - $REAL_HOME/Tools/subdomains-top1million-5000.txt"
    echo "  - $REAL_HOME/Tools/subdomains.txt"
    echo "  - $REAL_HOME/Tools/permutations_list.txt"
    echo "  - $REAL_HOME/Tools/permutations_list_short.txt"
    echo "  - $REAL_HOME/Tools/resolvers.txt"
    echo ""
    echo -e "${YELLOW}[!] Run 'source ~/.bashrc' or restart your terminal${NC}"
    echo -e "${YELLOW}[!] Usage: ./sef <domain>${NC}"
}

main
