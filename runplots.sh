#!/bin/bash
DATE=$1

if [ -z "$DATE" ] ; then
	printf "usage:\n\t$0 date\n\nparameters:\n\tdate\tdate in form YYY-MM-DD\n"
	exit 1
fi

TMPFILE=`mktemp runplots.XXXXXXX`

trap "rm -f -- $TMPFILE" EXIT

grep $DATE temp.log > $TMPFILE

doplot() {
	cut -d' ' -f2,$1 $TMPFILE | tr -s : ' ' | ./dayplot.pl $2 "$3" > $2.png
}

do2plot() {
	cut -d' ' -f2,$1 $TMPFILE | tr -s : ' ' | ./dayplot.pl $2 "$3" $4 "$5" > $2$4.png
}

doplot 3 temp degC
do2plot 5,7 hum %rH pressure hPa
do2plot 15,17 IAQ '' eCO2 ''

