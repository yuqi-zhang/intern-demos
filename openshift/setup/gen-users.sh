#!/bin/bash

export HTPASSWD_FILE=./htpasswd

USERS=$1

htpasswd -c -B -b $HTPASSWD_FILE admin admin
for user in $(cat "$USERS"); do
  htpasswd -b -B $HTPASSWD_FILE "$user" openshift
done

cat $HTPASSWD_FILE
