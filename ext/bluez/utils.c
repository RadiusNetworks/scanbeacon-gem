#ifdef linux
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <bluetooth/bluetooth.h>
#include <bluetooth/hci.h>
#include <bluetooth/hci_lib.h>
#include "ruby.h"

#include "utils.h"

VALUE ba2value(bdaddr_t *bdaddr)
{
  char addr[18];
  ba2str(bdaddr, addr);
  return rb_str_new2(addr);
}

#endif // linux
