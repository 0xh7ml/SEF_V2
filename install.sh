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
if command -v go &> /dev/null; then
    echo -e "${GREEN}[+] Go is already installed: $(go version)${NC}"
else
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

echo -e "${YELLOW}[*] Installing tools...${NC}"

# Install Subfinder
echo -e "${YELLOW}[*] Installing Subfinder${NC}"
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>&1 | grep -E "(download|install|compile)"

# Install Puredns
echo -e "${YELLOW}[*] Installing Puredns${NC}"
go install -v github.com/d3mondev/puredns/v2@latest 2>&1 | grep -E "(download|install|compile)"

# Install Httpx
echo -e "${YELLOW}[*] Installing Httpx${NC}"
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest 2>&1 | grep -E "(download|install|compile)"

# Install Chaos (ProjectDiscovery's subdomain discovery)
echo -e "${YELLOW}[*] Installing Chaos${NC}"
go install -v github.com/projectdiscovery/chaos-client/cmd/chaos@latest 2>&1 | grep -E "(download|install|compile)"

# Install Assetfinder
echo -e "${YELLOW}[*] Installing Assetfinder${NC}"
go install -v github.com/tomnomnom/assetfinder@latest 2>&1 | grep -E "(download|install|compile)"

# Install Anew
echo -e "${YELLOW}[*] Installing Anew${NC}"
go install -v github.com/tomnomnom/anew@latest 2>&1 | grep -E "(download|install|compile)"

# Install Gotator
echo -e "${YELLOW}[*] Installing Gotator${NC}"
go install -v github.com/Josue87/gotator@latest 2>&1 | grep -E "(download|install|compile)"

# Install Crobat
echo -e "${YELLOW}[*] Installing Crobat${NC}"
go install -v github.com/cgboal/sonarsearch/cmd/crobat@latest 2>&1 | grep -E "(download|install|compile)"

# Install Github-subdomains
echo -e "${YELLOW}[*] Installing Github-subdomains${NC}"
go install -v github.com/gwen001/github-subdomains@latest 2>&1 | grep -E "(download|install|compile)"

# Install Altdns (alternative to gotator for permutations)
echo -e "${YELLOW}[*] Installing Altdns${NC}"
go install -v github.com/infosec-au/altdns@latest 2>&1 | grep -E "(download|install|compile)"

# Install DNSx (faster DNS resolution)
echo -e "${YELLOW}[*] Installing DNSx${NC}"
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest 2>&1 | grep -E "(download|install|compile)"

# Install Tlsx (TLS certificate subdomain discovery - from reconftw)
echo -e "${YELLOW}[*] Installing Tlsx${NC}"
go install -v github.com/projectdiscovery/tlsx/cmd/tlsx@latest 2>&1 | grep -E "(download|install|compile)"

# Install Gitlab-subdomains (additional passive source - from reconftw)
echo -e "${YELLOW}[*] Installing Gitlab-subdomains${NC}"
go install -v github.com/gwen001/gitlab-subdomains@latest 2>&1 | grep -E "(download|install|compile)"

# Install Findomain
echo -e "${YELLOW}[*] Installing Findomain${NC}"
FINDOMAIN_VERSION=$(curl -s https://api.github.com/repos/Edu4rdSHL/findomain/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
wget -q https://github.com/Edu4rdSHL/findomain/releases/download/${FINDOMAIN_VERSION}/findomain-linux -O /tmp/findomain-linux
chmod +x /tmp/findomain-linux
mv /tmp/findomain-linux /usr/bin/findomain

# Install Amass (latest version)
echo -e "${YELLOW}[*] Installing Amass${NC}"
AMASS_VERSION=$(curl -s https://api.github.com/repos/owasp-amass/amass/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
cd /tmp && wget -q https://github.com/owasp-amass/amass/releases/download/${AMASS_VERSION}/amass_${AMASS_VERSION#v}_linux_amd64.zip
unzip -q amass_${AMASS_VERSION#v}_linux_amd64.zip
mv amass_${AMASS_VERSION#v}_linux_amd64/amass /usr/local/bin/
rm -rf amass_* /tmp/amass*

# Install ctfr for CRT.sh enumeration
echo -e "${YELLOW}[*] Installing ctfr${NC}"
if [ ! -d ~/Tools/ctfr ]; then
    git clone https://github.com/UnaPibaGeek/ctfr.git ~/Tools/ctfr
fi
pip3 install -q argparse requests

# Install massdns for ultra-fast DNS resolution
echo -e "${YELLOW}[*] Installing massdns${NC}"
if [ ! -d ~/massdns ]; then
    git clone https://github.com/blechschmidt/massdns.git ~/massdns
fi
cd ~/massdns
make &>/dev/null
mv ~/massdns/bin/massdns /usr/local/bin/
cd - &>/dev/null

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
