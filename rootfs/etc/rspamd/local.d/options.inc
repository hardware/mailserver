map_watch_interval = 1min;
dns {
  enable_dnssec = true;
  timeout = 4s;
  retransmits = 5;
  # In this case, 84.200.69.80 (resolver1.dns.watch) public resolver
  # will be used as a backup when local resolver is down
  # https://dns.watch/
  nameserver = "master-slave:127.0.0.1:53:10,84.200.69.80:53:1";
}
