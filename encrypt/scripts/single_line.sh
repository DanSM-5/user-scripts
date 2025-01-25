#!/usr/bin/env bash

# Take a file and print it as a single line string
# You can use this line for embedding it into
# environmet variables, json files, etc.

awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' "${*}"

