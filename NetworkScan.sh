#!/bin/bash
#set -x
clear 

#Variables
DATAFILE="/var/tmp/NetworkScan.data"
MACFILE="/var/tmp/NetworkScan.mac"
TMPFILE="/var/tmp/NetworkScan.tmp"
OUTFILE="/var/tmp/NetworkScan.out"
OUTFILE2="/var/tmp/NetworkScan.out2"
HISTFILE="/var/tmp/NetworkScan.history"

for i in {1..254} ;do (/bin/ping 192.168.0.$i -c 1 -w 5  >/dev/null &) ;done

TIMER=`date +"%D %T"`
IFS="
"
cat << _EOF > $MACFILE
00:00:00:00:00:01 - HOST1
00:00:00:00:00:02 - HOST2
00:00:00:00:00:03 - HOST3
_EOF

/usr/sbin/arp -an | grep -v '<incomplete>' > $TMPFILE

rm $DATAFILE.tmp
for lijn in `cat $DATAFILE`; do
  MAC=`echo $lijn | awk '{print $4}'`
  if [ ! "`grep $MAC $TMPFILE`" = "" ]; then
    echo $lijn >> $DATAFILE.tmp
  else
    echo `grep $MAC $OUTFILE` >> $HISTFILE
  fi
done
cat $HISTFILE | grep -v 'exclude1|exclude2' > $HISTFILE.tmp
mv $HISTFILE.tmp $HISTFILE
mv $DATAFILE.tmp $DATAFILE

echo "<html>" > $OUTFILE
echo "<meta http-equiv="refresh" content="60" />" >> $OUTFILE
echo "<span style=\"font-family: monospace;\">" >> $OUTFILE
lijn=""
IP=""
MAC=""
HOSTNAME=""
for lijn in `cat $TMPFILE` ;do
  IP=`echo $lijn | awk '{print $2}' | sed 's/(//g' | sed 's/)//g'`
  MAC=`echo $lijn | awk '{print $4}'`
  HOSTNAME=`grep -i "$MAC" $MACFILE | awk '{print $3}'`
  if [ "`grep $MAC $DATAFILE`" = "" ]; then echo $TIMER" - "$MAC >> $DATAFILE; fi
  if [ "$HOSTNAME" = "" ]; then python /home/pi/Code/SillyTweeter/SillyTweeter.py "ALARM - "$TIMER" : Intruder "$IP" with MAC "$MAC; fi
  if [ "`echo $IP | cut -d "." -f4`" -lt 10 ]; then echo $TIMER" - "$IP"   - "$MAC" - "$HOSTNAME" - online since: "`grep $MAC $DATAFILE | cut -c1-17`"<p>
" >> $OUTFILE
    elif [ "`echo $IP | cut -d "." -f4`" -ge 10 ] && [ "`echo $IP | cut -d "." -f4`" -lt 100 ]; then echo $TIMER" - "$IP"  - "$MAC" - "$HOSTNAME" - online since: "`grep $MAC $DATAFILE | cut -c1-17`"<p>
" >> $OUTFILE
    elif [ "`echo $IP | cut -d "." -f4`" -ge 100 ]; then echo $TIMER" - "$IP" - "$MAC" - "$HOSTNAME" - online since: "`grep $MAC $DATAFILE | cut -c1-17`"<p>
" >> $OUTFILE
  fi
done
echo "<a href=\"http://192.168.0.254/NetworkScan_history.html\">History</a>" >> $OUTFILE
echo "</span>" >> $OUTFILE
echo "</html>" >> $OUTFILE

echo "<html>" > $OUTFILE2
echo "<meta http-equiv="refresh" content="60" />" >> $OUTFILE2
echo "<span style=\"font-family: monospace;\">" >> $OUTFILE2
cat $HISTFILE >> $OUTFILE2
echo "<a href=\"http://192.168.0.254/NetworkScan.html\">Current status</a>" >> $OUTFILE2
echo "</span>" >> $OUTFILE2
echo "</html>" >> $OUTFILE2

cp $OUTFILE /usr/share/nginx/www/NetworkScan.html
mv $OUTFILE2 /usr/share/nginx/www/NetworkScan_history.html
rm $MACFILE $TMPFILE

exit 0
