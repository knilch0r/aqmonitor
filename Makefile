.PHONY: test

test: temp.log
	time ./runplots.sh 2021-11-27 temp.log './sendstub'
	time ./runmonthly.sh 2021-12 temp.log './sendstub'
	for i in *.png ; do display $$i & done

temp.log:
	scp raspi:temp.log .

