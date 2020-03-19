# sleepscan
Shell script to queue up targeted and general port scans for external pentests.

# Usage
```
./sleepscan.sh [target file] [--sleep [interval]] [options]
./sleepscan.sh hosts.txt --sleep 12h
```
* **[target file]** is your target list, can be any input Nmap will read. Must be the first parameter.
* **--sleep [interval]** optionally tells the script to start with the Linux `sleep` command, for the specified `sleep` interval (ex: 30m, 12h, etc).
* **--single-tcp** optionally tells the script to do one TCP port scan (`-sS`) for the targeted ports, instead of a separate scan for each port.
* **--single-udp** optionally tells the script to do one UDP service scan (`-sUV`) for the targeted ports, instead of a separate scan for each port.
* **--hd** optionally does host discovery scans before doing UDP service scans and the top 5000 TCP port scan. Targeted TCP scans will still run without host discovery. Hosts from the targeted scans will be added to the host discovery results.
* **--out-dir** optionally specifies and output directory other than the default `sleepscan-YYYY-MM-DD-HH`.

# Function
* Checks the output directory and verifies the input file exists.
* Confirms whether the sleep option was set, prompting to continue.
* If set, sleep for the specified interval.
* By default, targeted scans do one port scan per targeted port defined in the script, against all of the applicable targets.
  - **--single-tcp** and **--single-udp** direct the script to perform one TCP or UDP port scan for all of the target ports against all of the applicable targets.
* Targeted TCP port scans
  - Use the targeted TCP ports listed in the top of the script as `tcpList`
  - No host discovery or DNS resolution
  - Open port results output in .gnmap format.
* If set, do host discovery scans to find live hosts for the remaining port scans. Hosts found in the targeted TCP port scans will be added.
* UDP version (`-sUV`) scans
  - Like the targeted TCP port scans, but with with UDP ports listed as `udpLoopList`.
* General TCP port scans
  - Does `--top-ports 5000` against the targets.
* Combined all of the open port results from the .gnmap files into `combined.gnmap`. This is sorted and uniq'ed, but it may contain duplicates between the targeted and general TCP port scans.
