#!/bin/bash

git "$@" 2>&1 > >(tee /dev/null)
exit $?
