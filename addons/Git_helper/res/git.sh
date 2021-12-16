#!/bin/bash

func() {
	git "$@"
}

func "$@" 2>&1 | tee log.tmp
