#!/bin/bash

DATE=$1
INFILE=$2
CMD2T=$3

usage() {
	printf "usage:\n\t$0 month file [cmd2t]\n\nparameters:\n"
	printf "\tdate \tmonth in form YYY-MM\n"
	printf "\tfile \tinput file (temp.log)\n"
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
	# ...and generated stuff will be deleted afterwards, haha
	CMD2T=true
fi

MONPLOT=`dirname $0`/monthplot.pl

if [ ! -x "$MONPLOT" ] ; then
	echo "error: $MONPLOT not executable"
	exit 5
fi

printf "==== monthly report for $DATE ====" | $CMD2T send

TMPDIR=`mktemp -d runplots.XXXXXXX`

if [ -z "$TMPDIR" ] ; then
	exit 1
fi

trap "rm -rf -- $TMPDIR" EXIT

TMPFILE="$TMPDIR/grepped"

grep ^$DATE "$INFILE" > "$TMPFILE"

do2plot() {
	OFILE="$TMPDIR/$2$4.png"
	OUT=`tr -s :- ' ' < "$TMPFILE" | cut -d' ' -f 3-6,$1 | "$MONPLOT" $2 "$3" $4 "$5" 2>&1 >"$OFILE"`
	if [ -s "$OFILE" ] ; then
		$CMD2T sendfile "$OFILE" photo "$OUT"
	else
		printf '%s\n' "$OUT" >&2
		printf 'Error creating plot: %s' "$OUT" | $CMD2T send
	fi
}

do2plot 7,11 temp '°C' pressure hPa
do2plot 9,11 hum %rH pressure hPa

