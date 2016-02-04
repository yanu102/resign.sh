#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo 'Usage: rsign.sh ipa mobileprovision'
    exit
fi

ipafile=$1
provfile=$2

if [[ ! ${ipafile##*.} = 'ipa' ]]; then
    echo 'Usage: rsign.sh ipa mobileprovision'
    exit
fi

if [[ ! ${provfile##*.} = 'mobileprovision' ]]; then
    echo 'Usage: rsign.sh ipa mobileprovision'
    exit
fi

unzip -q $ipafile
appfile=Payload/`ls Payload`

rm -r "${appfile}/_CodeSignature"

cp ${provfile} "${appfile}/embedded.mobileprovision"

body=''
provfilebody=`cat $provfile`
bodystart=0
while read line
do
    if [[ $bodystart = 1 ]]; then
        body=$body$line
    fi
    if [[ $line = '</dict>' ]]; then
        bodystart=0
    fi
    if [[ $line = '<key>Entitlements</key>' ]]; then
        bodystart=1
    fi
done <<EOF
$provfilebody
EOF

if [[ $body != '' ]]; then
    body='<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0">'$body'</plist>'
    echo $body > e.plist
fi

sign=`security find-identity -p codesigning -v | grep Distribution | awk '{for(i=3;i<NF;i++){printf("%s ",$i)}print $NF}'`

codesign -f -s "$sign" --entitlements e.plist - $appfile

destfile=${ipafile%.*}'-resigned.'${ipafile##*.}

zip -qr $destfile Payload

rm entitlements.plist
rm e.plist
rm -r Payload
