#!/bin/bash

# rspamd client reads piped spam message from the standard input
exec /usr/bin/rspamc learn_spam
