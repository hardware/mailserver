#!/bin/bash

# rspamd client reads piped spam message from the standard input
exec /usr/bin/rspamc -h localhost:11334 learn_spam
