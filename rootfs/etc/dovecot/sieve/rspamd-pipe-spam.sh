#!/bin/bash
/usr/bin/curl -s --data-binary @- http://0.0.0.0:11334/learnspam < /dev/stdin
exit 0
