#!/bin/bash

# rspamd client reads piped ham message from the standard input
exec /usr/bin/rspamc learn_ham
