`Nordvpn Multithreaded account check tool Created by matrix`
Nordvpn checker

Two tools:

`chk3.sh`  checker notdvpn accounts

`fix_proxychains.sh` recombine tool to get live proxy (only for nordvpn and proxychains)


`Run like:` bash chk3.sh filename.txt 

`filename.txt must be in login:password format`

Working proxy accounts will be stored into work.txt. 
`By default 500 threads, you can change inside.`

`IMPORTANT NOTES: by default, getting info about founded account making over proxychains.`

If any, just replace "proxychains curl" with "curl"


`requests:`
`proxychains, curl`



`-Download proxy list from nordvpn servers`

`-Check accounts over socks auth`

`-Check accounts of exp date`

`-Generating proxychains.conf file`

