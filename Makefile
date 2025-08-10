.PHONY: test toast wait

test:
	echo "TEST"

toast:
	echo "toast" && fail-now

wait:
	sleep 2 && fail-now
