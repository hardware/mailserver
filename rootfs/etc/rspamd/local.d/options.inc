map_watch_interval = 1min;
dns {
  enable_dnssec = true;
  timeout = 4s;
  retransmits = 5;
  # In this case, 127.0.0.11 (docker embedded DNS server)
  # will be used as a backup when local resolver returns
  # an error (i.e SERVFAIL) or can't be reached
  nameserver = "master-slave:127.0.0.1:53:10,127.0.0.11:53:1";
}
