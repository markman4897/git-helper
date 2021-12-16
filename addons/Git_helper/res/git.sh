#!/bin/bash

if
	git "$@" > >(tee git.log) 2> >(tee git-err.log >&2)
	! ((ret=$?))
then
	rm -f git.log git-err.log
fi

exit $ret
