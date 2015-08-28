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

VALUE bluez_module = Qnil;

void Init_bluez();
VALUE method_device_up(VALUE self, VALUE device_id);
VALUE method_device_down(VALUE self, VALUE device_id);
//VALUE method_set_connectable(VALUE self, VALUE connectable);
VALUE method_set_advertisement_bytes(VALUE self, VALUE rb_device_id, VALUE bytes);
VALUE method_start_advertising(VALUE klass, VALUE rb_device_id, VALUE random_address);
VALUE method_stop_advertising(VALUE klass, VALUE rb_device_id);
VALUE method_scan(int argc, VALUE *argv, VALUE klass);
VALUE method_devices();
VALUE method_set_addr(VALUE klass, VALUE rb_device_id, VALUE rb_str_addr);
void init_advertisement();

void Init_bluez()
{
  VALUE scan_beacon_module = rb_const_get(rb_cObject, rb_intern("ScanBeacon"));
  bluez_module = rb_define_module_under(scan_beacon_module, "BlueZ");
  rb_define_singleton_method(bluez_module, "device_up", method_device_up, 1);
  rb_define_singleton_method(bluez_module, "device_down", method_device_down, 1);
  rb_define_singleton_method(bluez_module, "start_advertising", method_start_advertising, 2);
  rb_define_singleton_method(bluez_module, "stop_advertising", method_stop_advertising, 1);
  rb_define_singleton_method(bluez_module, "set_advertisement_bytes", method_set_advertisement_bytes, 2);
  //rb_define_singleton_method(bluez_module, "connectable=", method_set_connectable, 1);
  rb_define_singleton_method(bluez_module, "scan", method_scan, -1);
  rb_define_singleton_method(bluez_module, "devices", method_devices, 0);
  rb_define_singleton_method(bluez_module, "set_addr", method_set_addr, 2);

  // initialize the advertisement
  init_advertisement();
}


#endif // linux
