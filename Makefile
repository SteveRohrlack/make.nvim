.PHONY: test toast wait

test:
	echo "TEST"

toast:
	echo "toast" && fail-now
	# comment
	# comment
	# comment

wait:
	sleep 2 && fail-now
