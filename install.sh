#! /bin/bash

logo(){

echo " _____                      _ _        _     ";
echo "(_____)           _        | | |      | |    ";
echo "   _   ____   ___| |_  ____| | |   ___| | _  ";
echo "  | | |  _ \ /___|  _)/ _  | | |  /___| || \ ";
echo " _| |_| | | |___ | |_( ( | | | |_|___ | | | |";
echo "(_____|_| |_(___/ \___\_||_|_|_(_(___/|_| |_|";
echo "                                             ";
echo "           Run it as a root user             ";
echo "                                             ";
echo "                 @0xh7ml                     ";


}
logo
#
sed -i 's/\r//' install.sh
sed -i 's/\r//' sef

# Color codes for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

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
mkdir -p ~/Tools
mkdir -p $HOME/go/bin

# Update PATH for current session
export PATH=$PATH:$HOME/go/bin

# Function to check and install Go tools
install_go_tool() {
    local tool_name=$1
    local package_path=$2
    local binary_name=$3

    # Check if tool already exists in PATH
    if command -v $binary_name &> /dev/null; then
        echo -e "${GREEN}[+] $tool_name is already installed: $($binary_name -version 2>/dev/null || $($binary_name version 2>/dev/null) || echo 'installed')${NC}"
        return
    fi

    # Check if binary exists in Go bin directory
    if [ -f $HOME/go/bin/$binary_name ]; then
        # Create symlink if not exists
        if [ ! -L /usr/local/bin/$binary_name ]; then
            ln -sf $HOME/go/bin/$binary_name /usr/local/bin/$binary_name
        fi
        echo -e "${GREEN}[+] $tool_name is already installed${NC}"
        return
    fi

    # Install the tool
    echo -e "${YELLOW}[*] Installing $tool_name${NC}"
    go install -v $package_path@latest 2>&1 | grep -E "(download|install|compile)"

    # Create symlink to /usr/local/bin
    if [ -f $HOME/go/bin/$binary_name ]; then
        ln -sf $HOME/go/bin/$binary_name /usr/local/bin/$binary_name
    fi
}

# Function to check and install binary tools
install_binary_tool() {
    local tool_name=$1
    local binary_path=$2
    local install_function=$3

    # Check if tool already exists
    if command -v $binary_path &> /dev/null; then
        echo -e "${GREEN}[+] $tool_name is already installed${NC}"
        return
    fi

    # Install the tool
    $install_function
}

echo -e "${YELLOW}[*] Checking tools and installing if needed...${NC}"

# Install Go tools
install_go_tool "Subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder" "subfinder"
install_go_tool "Puredns" "github.com/d3mondev/puredns/v2" "puredns"
install_go_tool "Httpx" "github.com/projectdiscovery/httpx/cmd/httpx" "httpx"
install_go_tool "Chaos" "github.com/projectdiscovery/chaos-client/cmd/chaos" "chaos"
install_go_tool "Assetfinder" "github.com/tomnomnom/assetfinder" "assetfinder"
install_go_tool "Anew" "github.com/tomnomnom/anew" "anew"
install_go_tool "Gotator" "github.com/Josue87/gotator" "gotator"
install_go_tool "Crobat" "github.com/cgboal/sonarsearch/cmd/crobat" "crobat"
install_go_tool "Github-subdomains" "github.com/gwen001/github-subdomains" "github-subdomains"
install_go_tool "Altdns" "github.com/infosec-au/altdns" "altdns"
install_go_tool "DNSx" "github.com/projectdiscovery/dnsx/cmd/dnsx" "dnsx"
install_go_tool "Tlsx" "github.com/projectdiscovery/tlsx/cmd/tlsx" "tlsx"
install_go_tool "Gitlab-subdomains" "github.com/gwen001/gitlab-subdomains" "gitlab-subdomains"

# Install Findomain
install_binary_tool "Findomain" "findomain" '
    echo -e "${YELLOW}[*] Installing Findomain${NC}"
    FINDOMAIN_VERSION=$(curl -s https://api.github.com/repos/Edu4rdSHL/findomain/releases/latest | grep '"'"'tag_name'"'"' | sed -E '"'"'s/.*"([^"]+)".*/\1/'"'"')
    wget -q https://github.com/Edu4rdSHL/findomain/releases/download/${FINDOMAIN_VERSION}/findomain-linux -O /tmp/findomain-linux
    chmod +x /tmp/findomain-linux
    mv /tmp/findomain-linux /usr/bin/findomain
'

# Install Amass (latest version)
install_binary_tool "Amass" "amass" '
    echo -e "${YELLOW}[*] Installing Amass${NC}"
    AMASS_VERSION=$(curl -s https://api.github.com/repos/owasp-amass/amass/releases/latest | grep '"'"'tag_name'"'"' | sed -E '"'"'s/.*"([^"]+)".*/\1/'"'"')
    cd /tmp && wget -q https://github.com/owasp-amass/amass/releases/download/${AMASS_VERSION}/amass_${AMASS_VERSION#v}_linux_amd64.zip
    unzip -q amass_${AMASS_VERSION#v}_linux_amd64.zip
    mv amass_${AMASS_VERSION#v}_linux_amd64/amass /usr/local/bin/
    rm -rf amass_* /tmp/amass*
'

# Install ctfr for CRT.sh enumeration
echo -e "${YELLOW}[*] Checking ctfr${NC}"
if [ ! -d ~/Tools/ctfr ]; then
    echo -e "${YELLOW}[*] Installing ctfr${NC}"
    git clone https://github.com/UnaPibaGeek/ctfr.git ~/Tools/ctfr
    pip3 install -q argparse requests
else
    echo -e "${GREEN}[+] ctfr is already installed${NC}"
fi

# Install massdns for ultra-fast DNS resolution
echo -e "${YELLOW}[*] Checking massdns${NC}"
if command -v massdns &> /dev/null; then
    echo -e "${GREEN}[+] massdns is already installed${NC}"
else
    echo -e "${YELLOW}[*] Installing massdns${NC}"
    if [ ! -d ~/massdns ]; then
        git clone https://github.com/blechschmidt/massdns.git ~/massdns
    fi
    cd ~/massdns
    make &>/dev/null
    mv ~/massdns/bin/massdns /usr/local/bin/
    cd - &>/dev/null
fi

# Wordlists and Resolvers (from reconftw - improved for better results)
echo -e "${YELLOW}[*] Downloading Wordlists and Resolvers${NC}"

# Main subdomain wordlist (from SecLists - comprehensive)
curl -s -o ~/Tools/subdomains.txt https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/DNS/subdomains-top1million-5000.txt

# Large subdomain wordlist for deep enumeration (assetnote)
curl -s -o ~/Tools/subdomains_big.txt https://raw.githubusercontent.com/assetnote/commonspeak2-wordlists/master/subdomains/subdomains.txt

# Full permutation wordlist (from reconftw - 1000+ entries for comprehensive permutations)
curl -s -o ~/Tools/permutations_list.txt https://raw.githubusercontent.com/six2dez/reconftw/main/data/wordlists/permutations_list.txt

# Short permutation wordlist (from reconftw - for faster scanning)
curl -s -o ~/Tools/permutations_list_short.txt https://raw.githubusercontent.com/six2dez/reconftw/main/data/wordlists/permutations_list_short.txt

# Trusted resolvers (from reconftw - optimized by six2dez)
cat > ~/Tools/resolvers_trusted.txt << 'EOF'
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

# Large resolver list (from trickest - maintained regularly)
curl -s --connect-timeout 10 --max-time 30 -o ~/Tools/resolvers.txt https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt

# DNS record type wordlists for additional enumeration
curl -s -o ~/Tools/srv_prefixes.txt https://raw.githubusercontent.com/six2dez/reconftw/main/data/wordlists/srv_prefixes.txt

# Create GitHub/GitLab tokens placeholder
touch ~/Tools/.github_tokens

# Ensure all Go tools are linked to /usr/local/bin for system-wide access
echo -e "${YELLOW}[*] Ensuring all tools are in system PATH...${NC}"
GO_TOOLS=("subfinder" "puredns" "httpx" "chaos" "assetfinder" "anew" "gotator" "crobat" "github-subdomains" "altdns" "dnsx" "tlsx" "gitlab-subdomains")
for tool in "${GO_TOOLS[@]}"; do
    if [ -f $HOME/go/bin/$tool ] && [ ! -L /usr/local/bin/$tool ]; then
        ln -sf $HOME/go/bin/$tool /usr/local/bin/$tool
    fi
done

echo -e "${GREEN}[+] Installation Completed Successfully!${NC}"
echo ""
echo "${YELLOW}[*] Tools installed:${NC}"
echo "  - Subfinder (passive subdomain discovery)"
echo "  - Assetfinder (subdomain enumeration)"
echo "  - Amass (comprehensive reconnaissance)"
echo "  - Findomain (fast subdomain discovery)"
echo "  - Puredns (mass DNS resolution)"
echo "  - Httpx (HTTP probing)"
echo "  - Chaos (bug bounty subdomains)"
echo "  - Gotator (permutation generation)"
echo "  - Altdns (alternative permutations)"
echo "  - DNSx (DNS resolution toolkit)"
echo "  - Crobat (multi-source subdomains)"
echo "  - Github-subdomains (GitHub search)"
echo "  - Gitlab-subdomains (GitLab search)"
echo "  - Ctfr (CRT.sh enumeration)"
echo "  - Massdns (ultra-fast DNS)"
echo "  - Tlsx (TLS certificate discovery)"
echo ""
echo "${YELLOW}[*] Wordlists installed (from reconftw sources):${NC}"
echo "  - ~/Tools/subdomains.txt - Main wordlist (5000 entries)"
echo "  - ~/Tools/subdomains_big.txt - Large wordlist (100000+ entries)"
echo "  - ~/Tools/permutations_list.txt - Full permutations (1000+ entries)"
echo "  - ~/Tools/permutations_list_short.txt - Short permutations (fast)"
echo ""
echo "${YELLOW}[*] Resolvers installed (from reconftw/trickest):${NC}"
echo "  - ~/Tools/resolvers_trusted.txt - Trusted resolvers (optimized)"
echo "  - ~/Tools/resolvers.txt - Large resolver list (trickest)"
echo "  - ~/Tools/srv_prefixes.txt - SRV record prefixes"
echo ""
echo -e "${GREEN}[+] Make sure to source ~/.bashrc or restart your terminal${NC}"
echo -e "${GREEN}[+] Add your GitHub/GitLab tokens to ~/Tools/.github_tokens${NC}"
