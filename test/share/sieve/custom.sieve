if header :contains "X-Spam-Level" "**********" {
  discard;
  stop;
}
