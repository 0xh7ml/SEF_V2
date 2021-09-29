# SEF

```
 _____ _____ _____
/  ___|  ___|  ___|
\  -- | |__ | |_
  --  \  __||  _ |
/\__/ / |___| |
\____/\____/\_| @0xh7ml
Subdomain Enumeration Framework v2.0
```
``` Little bit update version of remonsec SEF ```
``` https://github.com/remonsec/SEF ```
# Info

SEF will cover  
* Active Enumeration
* Passive Enumeration
* Permuted Enumeration

You also can have a quick passive scan \
The aim is to give you as much subdomain as possible

# Warning

If you are using `--all` `--dLa` flag then make sure you are using this script from VPS \
Your local machine may face problems as it will perform hard DNS active enumeration

# Requirnment 

* Subfinder
* Findomain
* Assetfinder
* Amass
* Anew
* PureDns
* MassDns
* Gotator
* Crobat
* Github Subdomain
* CTFR
* Notify
* Httpx

Run install.sh and it will install all the requirnments \
Make sure that, you are running install.sh as root

# Usage

make sure to use `--quick` and `--all` after setting the `-w` `-r` `-d` cause this param sets value and `-o` at the end to save everything in a specific directory. Also about `--dL` in which tool are they going to imported

### Example

```
bash sef -d -w -r --ac --all -o
```
### Quick Mode 

```
bash sef -d target.com --ac config.ini --quick -o target
```

### All Enum Mode

```
bash sef -d target.com -w wordlist.txt -r resolver.txt --ac config.ini --all -o target 
```
### Single Domain Scanning

```
bash sef -d target.com -w wordlist.txt -r resolvers.txt --ac amass_config.ini --all -o target.com
```

### Domain-List Scanning 

```
bash sef -w wordlist.txt -r resolvers.txt --ac amass_config.ini --dLa domain_list.txt
```
### Flags

```
Usage: 
       sef -d       To Specify Domain.
       sef -w       To Specify wordlist to use else (Default).
       sef -r       To Specify resolver to use else (Default).
       sef -o       To Store all the result in specific folder.
       sef --dLq    To quick passive scan Domain-list.
       sef --dLa    To full scan Domain-list.
       sef --ac     To Specify Amass-config file.
       sef --quick  To quicky perform passive scan of domain.
       sef --all    To fully scan using all functionality.
```

# Note

If you are using `--dLq` `--dLa` then no need to use `--quick` `--all` `-o` \
Make sure you are using `-w` `-r` `--ac` before `--dLa` `--dLq`
