# sleepscan
Shell script to queue up targeted and general port scans for external pentests.

# Usage
```
./sleepscan.sh [target file] [--sleep [interval]] [options]
./sleepscan.sh hosts.txt --sleep 12h
```
* **[target file]** is your target list, can be any input Nmap will read. Must be the first parameter.
* **--sleep [interval]** optionally tells the script to start with the Linux `sleep` command, for the specified `sleep` interval (ex: 30m, 12h, etc).
* **--single-udp** optionally tells the script to do one UDP service scan (`-sUV`) for the targeted ports, instead of a separate scan for each port.
* **--hd** optionally does host discovery scans before doing UDP service scans and the top 5000 TCP port scan. Targeted TCP scans will still run without host discovery. Hosts from the targeted scans will be added to the host discovery results.
* **--out-dir** optionally specifies and output directory other than the default `sleepscan-YYYY-MM-DD-HH`.

# Function
* Checks the output directory and verifies the input file exists.
* Confirms whether the sleep option was set, prompting to continue.
* If set, sleep for the specified interval.
* Targeted TCP port scans
  - For the targeted TCP ports listed in the top of the script as `tcpList`, do an individual Nmap TCP SYN scan for that port against the target list, no host discovery or DNS resolution, writing open port results to a .gnmap file.
* If set, do host discovery scans to find live hosts for the remaining port scans. Hosts found in the targeted TCP port scans will be added.
* UDP version (`-sUV`) scans
  - By default, behaves like the targeted TCP port scans, doing an individual scan against all targets for each port in the `udpLoopList` variable.
  - Optionally, does one scan for all of the `udpLoopList` ports against the targets.
  - If host discovery was specified, the live hosts list will be used. If not, the original target list will be.
* General TCP port scans
  - Does `--top-ports 5000` against the targets.
  - If host discovery was specified, the live hosts list will be used. If not, the original target list will be.
* Combined all of the open port results from the .gnmap files into `combined.gnmap`. This is sorted and uniq'ed, but it may contain duplicates between the targeted and general TCP port scans.
