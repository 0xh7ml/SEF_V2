#!/bin/bash

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

#Install Golang.
echo -e "Installing Go-Lang";
wget -q -O - https://git.io/vQhTU | bash
source ~/.bashrc
echo -e " ";


#Install Subfinder.
echo -e "Installing Subfinder";
GO111MODULE=on go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder
echo -e " ";

#Install Amass.
AMASS_VERSION=3.10.5
echo -e "Installing Amass";
cd ~ && echo -e "Downloading amass version ${AMASS_VERSION} ..." && wget -q https://github.com/OWASP/Amass/releases/download/v${AMASS_VERSION}/amass_linux_amd64.zip &>/dev/null && unzip amass_linux_amd64.zip &>/dev/null && mv amass_linux_amd64/amass /usr/bin/
cd ~ && rm -rf amass_linux_amd64* amass_linux_amd64.zip*
echo -e " ";

#Install Assetfinder.
echo -e "Installing Assetfinder";
go get -u github.com/tomnomnom/assetfinder
echo -e " ";

#Install massdns
echo "Installing massdns"
git clone https://github.com/blechschmidt/massdns.git ~/massdns
cd ~/massdns
make &>/dev/null
mv ~/massdns/bin/massdns /usr/local/bin/
cd -
echo -e " ";

#Install Findomain.
echo -e "Installing Findomain";
wget https://github.com/Edu4rdSHL/findomain/releases/latest/download/findomain-linux
sudo chmod +x findomain-linux
sudo cp findomain-linux /usr/bin/findomain
sudo rm findomain-linux
echo -e " ";

#Install Anew.
echo -e "Installing Anew";
go get -u github.com/tomnomnom/anew
echo -e " ";
#Install Httpx
echo -e "Installing Httpx";
GO111MODULE=on go get -v github.com/projectdiscovery/httpx/cmd/httpx
echo -e " ";

#Wordlist
echo -e "Downloading Wordlist";
curl -O https://raw.githubusercontent.com/assetnote/commonspeak2-wordlists/master/subdomains/subdomains.txt
echo -e "Downloading Resolvers"
curl -O https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt

echo -e "Installation Completed.";
