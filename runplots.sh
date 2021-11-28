#!/bin/bash

DATE=$1
INFILE=$2
CMD2T=$3

usage() {
	printf "usage:\n\t$0 date [cmd2t]\n\nparameters:\n"
	printf "\tdate \tdate in form YYY-MM-DD\n"
	printf "\tcmd2t\tpath to cmd2telegram\n"
}

if [ -z "$DATE" ] ; then
	echo "error: must specify date"
	usage
	exit 1
fi

if [ ! -f "$INFILE" ] ; then
	echo "error: '$INFILE' not found"
	usage
	exit 2
fi

if [ -z "$CMD2T" ] ; then
	echo "not sending, only generating"
	CMD2T=true
fi

printf "==== report for $DATE ====" | $CMD2T send

TMPDIR=`mktemp -d runplots.XXXXXXX`

if [ -z "$TMPDIR" ] ; then
	exit 1
fi

trap "rm -rf -- $TMPDIR" EXIT

TMPFILE="$TMPDIR/grepped"

grep $DATE temp.log > $TMPFILE

doplot() {
	OFILE="$TMPDIR/$2.png"
	OUT=`cut -d' ' -f2,$1 "$TMPFILE" | tr -s : ' ' | ./dayplot.pl $2 "$3" 2>&1 >"$OFILE"`
	if [ -s "$OFILE" ] ; then
		$CMD2T sendfile "$OFILE" photo "$OUT"
	else
		printf '%s' $OUT >&2
	fi
}

do2plot() {
	OFILE="$TMPDIR/$2$4.png"
	OUT=`cut -d' ' -f2,$1 "$TMPFILE" | tr -s : ' ' | ./dayplot.pl $2 "$3" $4 "$5" 2>&1 >"$OFILE"`
	if [ -s "$OFILE" ] ; then
		$CMD2T sendfile "$OFILE" photo "$OUT"
	else
		printf '%s' $OUT >&2
	fi
}

doplot 3 temp degC
do2plot 5,7 hum %rH pressure hPa
do2plot 15,17 IAQ '' eCO2 ''

