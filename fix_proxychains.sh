rm -f plist.txt
rm -f plist1.txt
rm -f plist2.txt
rm -f plist_ip.txt
rm -f proxychains.conf.tmp

echo create proxychains
dd=`grep -n meanwile /etc/proxychains.conf|awk -F":" '{print $1}'`
head -$dd -q  /etc/proxychains.conf >proxychains.conf.new
echo downloading
curl -i -s https://nordvpn.com/ru/ovpn/ |grep '<span class="mr-2">'|cut -d\> -f2|cut -d\< -f1|shuf -n 150 >plist.txt
echo nmappin
nmap -Pn -n --open --min-rate 1000 -p1080 -iL plist.txt|grep "report for"|awk '{print $5}'>plist1.txt

echo plist1
while read h; do
  host $h|cut -d " " -f4- >>plist_ip.txt
done <plist1.txt

echo plist2
cat /etc/proxychains.conf|grep socks5|grep 1080|awk '{print $4":"$5}'|sort|uniq>plist2.txt

echo create list
while read g; do
  pr=`sort --random-sort plist_ip.txt |shuf -n 1`
  (timeout 10 curl -sf -U ${g} --socks5 ${pr}:1080 google.com >>/dev/null && echo "socks5 ${pr}:gghhfff ${g}"|sed 's/:/ /g'|sed 's/gghhfff/1080/g' >> proxychains.conf.tmp)&
done <plist2.txt

echo Sleeping 12 seconds
sleep 12

while read g; do
  pr=`sort --random-sort plist_ip.txt |shuf -n 1`
  (timeout 10 curl -sf -U ${g} --socks5 ${pr}:1080 google.com >>/dev/null && echo "socks5 ${pr}:gghhfff ${g}"|sed 's/:/ /g'|sed 's/gghhfff/1080/g' >> proxychains.conf.tmp)&
done <plist2.txt

echo Sleeping 12 seconds
sleep 12

cat proxychains.conf.tmp|sort|uniq >>proxychains.conf.new

rm -f plist.txt
rm -f plist1.txt
rm -f plist2.txt
rm -f plist_ip.txt
rm -f proxychains.conf.tmp

#cp /etc/proxychains.conf /etc/proxychains.conf.$RANDOM
#cat proxychains.conf.new >/etc/proxychains.conf

