#!/bin/bash
#sleepscan.sh
dateCreated="2/29/2020"
dateLastMod="3/1/2020"
#3/1/2020 - Wrong options for hd scan, and realized with -Pn that TCP targeted scans would report all hosts Up, so changed logic for finding live hosts from them for combining

#Space-delimited for FOR loop
tcpList="21 22 23 25 53 80 110 135 137 139 143 222 389 443 445 465 513 514 636 873 989 990 992 993 995 1433 2222 3306 3389 4786 5432 8000 8080 8443 8888 9443"
udpLoopList="53 69 123 161 162 500"
#Don't need to customize below, most are defaults overridden by options
#Convert udpLoopList to comma-delimited when option --single-udp used
udpSingleList=$(echo "$udpLoopList" | sed 's/ /,/g')
udpMode="LOOP"
doHD="N"
doSleep="N"
outDir="sleepscan-$(date +%F-%H-%M)"

function fnUsage {

  echo
  echo "=======================[ sleepscan.sh - Ted R (github: actuated) ]======================="
  echo
  echo "Script for setting up time-delayed targeted and general port scans for external pentest."
  echo
  echo "Sleeps if specified, then"
  echo "Individual TCP port scans for targeted ports against the target list, no discovery, then"
  echo "Optionally do host discovery scans, then"
  echo "Do invdividual UDP port scans (default) or a single UDP scan for targeted ports (optional)"
  echo "Then, a TCP port scan for --top-ports 5000."
  echo
  echo "Created $dateCreated, last modified $dateLastMod."
  echo
  echo "========================================[ usage ]========================================"
  echo
  echo "./sleepscan.sh [target file] [--sleep [interval]] [options]"
  echo "./sleepscan.sh hosts.txt --sleep 12h"
  echo
  echo "[target file]       List of targets for Nmap commands. Mandatory, must be first argument."
  echo
  echo "--sleep [interval]  Time-delay start of scans with the 'sleep' command."
  echo "                    Use 'sleep' command values for interval (ex: 12h)."
  echo
  echo "--out-dir [dir]     Set custom output directory, default is 'sleepscan-YYYY-MM-DD-HH'."
  echo
  echo "--single-udp        Do one UDP port/verion (nmap -sUV) scan for targeted UDP ports"
  echo "                    instead of individual scans per port."
  echo
  echo "--hd                Do host discovery before targeted UDP and general TCP port scans."
  echo "                    Targeted TCP port scans will still be run against [target file]."
  echo
  echo "=========================================[ fin ]========================================="
  echo

}

#Start script and check options before banner
inputFile="$1"
if [ ! -f "$inputFile" ]; then echo; echo "Error: Input file doesn't exist."; fnUsage; exit; fi
shift

# Check for options
while [ "$1" != "" ]; do
  case $1 in
    --single-udp ) udpMode="SINGLE"
         ;;
    --hd ) doHD="Y"
         ;;
    --sleep ) shift 
         doSleep="Y"
         sleepArg="$1"
         if [ "$sleepArg" = "" ]; then echo; echo "Error: --sleep specified with no interval."; fnUsage; exit; fi
         ;;
    --out-dir ) shift
         outDir="$1"
         if [ "$outDir" = "" ]; then echo; echo "Error: --out-dir option with no directory given."; fnUsage; exit; fi
         if [ -e "$outDir" ] && [ ! -d "$outDir" ]; then echo; echo "Error: '$outDir' exists and is not a directory."; fnUsage; exit; fi
         ;;
    -h ) fnUsage
         exit
         ;;
  esac
  shift
done

echo
echo "=======================[ sleepscan.sh - Ted R (github: actuated) ]======================="

if [ -d "$outDir" ]; then
  echo
  read -p "Output directory '$outDir' exists. Press Enter to continue anyway..."
else
  echo
  echo "Output will be written to '$outDir'."
  mkdir "$outDir"
fi

if [ "$doSleep" = "N" ]; then
  echo
  read -p "No sleep option specified, press Enter to start scans now..."
else
  echo
  read -p "Press Enter to start sleeping for $sleepArg before scans start..."
  timeNow=$(date +%r)
  echo -n "$timeNow - Starting $sleepArg sleep..."
  sleep "$sleepArg"
  timeNow=$(date +%r)
  echo " Done $timeNow."
fi

# Targeted TCP port scans
echo
timeNow=$(date +%r)
echo "$timeNow - Targeted TCP Scans Started..."

for thisPort in $tcpList; do
  timeNow=$(date +%r)
  echo -n "$timeNow - Starting Port $thisPort..."
  nmap -iL "$inputFile" -sS -Pn -n --open -p $thisPort -oG "$outDir"/tcp-targeted-$thisPort.gnmap > /dev/null
  timeNow=$(date +%r)
  echo " Done $timeNow."
done

# Check host discovery option
if [ "$doHD" = "Y" ]; then
  echo
  timeNow=$(date +%r)
  echo "$timeNow - Host Discovery Scans Started..."
  nmap -iL "$inputFile" -sn -n -oG "$outDir"/host-discovery.gnmap > /dev/null
  timeNow=$(date +%r)
  echo "$timeNow - Host Discovery Scans Done."
  echo
  echo "Creating live-hosts.txt from host discovery and targeted TCP port scan results."
  grep Up "$outDir"/host-discovery.gnmap | awk '{print $2}' | sort -V | uniq > "$outDir"/temp-live-hosts-from-hd.txt
  grep /open/ "$outDir"/tcp-targeted-*.gnmap | awk '{print $2}' | sort -V | uniq > "$outDir"/temp-live-hosts-from-tcp-targeted.txt
  cat "$outDir"/temp-live-hosts-* | sort -V | uniq > "$outDir"/live-hosts.txt
  inputFile="$outDir/live-hosts.txt"
fi

# Do UDP scans
if [ "$udpMode" = "LOOP" ]; then
  echo
  timeNow=$(date +%r)
  echo "$timeNow - Targeted UDP Scans Started..."
  for thisPort in $udpLoopList; do
    timeNow=$(date +%r)
    echo -n "$timeNow - Starting Port $thisPort..."
    nmap -iL "$inputFile" -sUV -Pn -n --open -p $thisPort -oG "$outDir"/udp-targeted-$thisPort.gnmap > /dev/null
    timeNow=$(date +%r)
    echo " Done $timeNow."
  done
else
  echo
  timeNow=$(date +%r)
  echo "$timeNow - UDP Scans Started..."
  nmap -iL "$inputFile" -sUV -Pn -n --open -p $udpSingleList -oG "$outDir"/udp-targeted.gnmap > /dev/null
  timeNow=$(date +%r)
  echo "$timeNow - UDP Scans Done."
fi

# Do general TCP scans
echo
timeNow=$(date +%r)
echo "$timeNow - Top 5k TCP Scans Started..."
nmap -iL "$inputFile" -sS -Pn -n --open --top-ports 5000 -oG "$outDir"/tcp-top5k.gnmap > /dev/null
timeNow=$(date +%r)
echo "$timeNow - Top 5k TCP Scans Done."

echo
echo "Combining results into $outDir/combined.gnmap."
echo "Note: There may be duplicated results between targeted and general TCP port scans."
echo "*slaps nmap-grep repository* this baby can parse so many gnmap results."
grep /open/ "$outDir"/*.gnmap -h --color=never | sort -V | uniq > "$outDir"/temp-combined.txt
mv "$outDir"/temp-combined.txt "$outDir"/combined.gnmap

echo
echo "=========================================[ fin ]========================================="
echo


