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
	cut -d' ' -f2,$1 $TMPFILE | tr -s : ' ' | ./dayplot.pl > $2.png
	MIN=`cut -d' ' -f$1 $TMPFILE | sort -n | head -1`
	MAX=`cut -d' ' -f$1 $TMPFILE | sort -rn | head -1`
	printf "$2 min: $MIN max: $MAX %s\n" "$3"
}

doplot 3 temp degC
doplot 5 hum %rH
doplot 7 pressure hPa
doplot 15 IAQ ''
doplot 17 eCO2 ''

