#!/bin/bash
cd rkn || { echo "no shit" >&2; exit 1; }
rm *
curl -k -X GET -H "Authorization: Bearer $BANLIST_TOKEN" $BANLIST_SERVER > rkn.zip
unzip rkn.zip
