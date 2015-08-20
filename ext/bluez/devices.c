#ifdef linux
#include "ruby.h"
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <bluetooth/bluetooth.h>
#include <bluetooth/hci.h>
#include <bluetooth/hci_lib.h>

#include "utils.h"

VALUE method_device_up(VALUE self, VALUE device_id)
{
  VALUE success;
  int ctl = socket(AF_BLUETOOTH, SOCK_RAW, BTPROTO_HCI);
  int hdev = NUM2INT(device_id);
  /* Start HCI device */
  if (ioctl(ctl, HCIDEVUP, hdev) < 0) {
    if (errno == EALREADY) {
      success = Qtrue;
    } else {
      rb_sys_fail("Can't init device");
      success = Qfalse;
    }
  } else {
    success = Qtrue;
  }
  close(ctl);
  return success;
}

VALUE method_device_down(VALUE self, VALUE device_id)
{
  VALUE success;
  int ctl = socket(AF_BLUETOOTH, SOCK_RAW, BTPROTO_HCI);
  int hdev = NUM2INT(device_id);
  /* Stop HCI device */
  if (ioctl(ctl, HCIDEVDOWN, hdev) < 0) {
    rb_sys_fail("Can't init device");
    success = Qfalse;
  } else {
    success = Qtrue;
  }
  close(ctl);
  return success;
}

VALUE di_to_hash(struct hci_dev_info *di)
{
  VALUE hash = rb_hash_new();
  rb_hash_aset(hash, ID2SYM(rb_intern("device_id")), INT2FIX(di->dev_id));
  rb_hash_aset(hash, ID2SYM(rb_intern("name")), rb_str_new2(di->name));
  rb_hash_aset(hash, ID2SYM(rb_intern("addr")), ba2value(&di->bdaddr));
  if (hci_test_bit(HCI_UP, &di->flags)) {
    rb_hash_aset(hash, ID2SYM(rb_intern("up")), Qtrue);
  } else {
    rb_hash_aset(hash, ID2SYM(rb_intern("up")), Qfalse);
  }
  return hash;
}

VALUE method_devices()
{
  struct hci_dev_list_req *dl;
  struct hci_dev_req *dr;
  struct hci_dev_info di;
  int i;

  if (!(dl = malloc(HCI_MAX_DEV * sizeof(struct hci_dev_req) + sizeof(uint16_t)))) {
    rb_raise(rb_eException, "Can't allocate memory");    
    return Qnil;
  }
  dl->dev_num = HCI_MAX_DEV;
  dr = dl->dev_req;

  int ctl = socket(AF_BLUETOOTH, SOCK_RAW, BTPROTO_HCI);
  if (ioctl(ctl, HCIGETDEVLIST, (void *) dl) < 0) {
    rb_raise(rb_eException, "Can't get device list");    
    return Qnil;
  }

  VALUE devices = rb_ary_new();

  for (i = 0; i< dl->dev_num; i++) {
    di.dev_id = (dr+i)->dev_id;
    if (ioctl(ctl, HCIGETDEVINFO, (void *) &di) < 0)
      continue;
    if (hci_test_bit(HCI_RAW, &di.flags) &&
        !bacmp(&di.bdaddr, BDADDR_ANY)) {
      int dd = hci_open_dev(di.dev_id);
      hci_read_bd_addr(dd, &di.bdaddr, 1000);
      hci_close_dev(dd);
    }
    rb_ary_push(devices, di_to_hash(&di));
  }
  return devices;
}

#endif // linux
