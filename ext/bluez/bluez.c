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
#pragma pack(1)

VALUE bluez_module = Qnil;

void Init_bluez();
VALUE method_device_up();
VALUE method_device_down();
VALUE method_set_connectable(VALUE self, VALUE connectable);
VALUE method_set_advertisement_bytes(VALUE self, VALUE bytes);
VALUE method_start_advertising();
VALUE method_stop_advertising();
VALUE method_scan();

#define FLAGS_NOT_CONNECTABLE 0x1A
#define FLAGS_CONNECTABLE     0x18

typedef struct {
  uint8_t len;
  struct {
    uint8_t len;
    uint8_t type;
    uint8_t data;
  } flags;
  uint8_t ad_len;
  uint8_t ad_data[27];
} Advertisement;

Advertisement advertisement;
int advertising;

void Init_bluez()
{
  VALUE scan_beacon_module = rb_const_get(rb_cObject, rb_intern("ScanBeacon"));
  bluez_module = rb_define_module_under(scan_beacon_module, "BlueZ");
  rb_define_singleton_method(bluez_module, "device_up", method_device_up, 0);
  rb_define_singleton_method(bluez_module, "device_down", method_device_down, 0);
  rb_define_singleton_method(bluez_module, "start_advertising", method_start_advertising, 0);
  rb_define_singleton_method(bluez_module, "stop_advertising", method_stop_advertising, 0);
  rb_define_singleton_method(bluez_module, "advertisement_bytes=", method_set_advertisement_bytes, 1);
  rb_define_singleton_method(bluez_module, "connectable=", method_set_connectable, 1);
  rb_define_singleton_method(bluez_module, "scan", method_scan, 0);

  // bring up the device, in case it's not already up
  method_device_up();

  // initialize the advertisement
  memset(&advertisement, 0, sizeof(advertisement));
  advertisement.flags.len = 2;
  advertisement.flags.type = 1;
  advertisement.flags.data = FLAGS_NOT_CONNECTABLE;
  advertising = 0;
}

VALUE method_set_connectable(VALUE self, VALUE connectable)
{
  if ( RTEST(connectable) )
  {
    advertisement.flags.data = FLAGS_CONNECTABLE;
  } else {
    advertisement.flags.data = FLAGS_NOT_CONNECTABLE;
  };
  if (advertising) {
    method_start_advertising();
  }
  return connectable;
}

VALUE method_set_advertisement_bytes(VALUE self, VALUE bytes)
{
  uint8_t len = RSTRING_LEN(bytes);
  if (len > 27) {
    len = 27;
  }
  advertisement.len = len + advertisement.flags.len + 2; // + 2 is to account for the flags length field and the ad length field
  advertisement.ad_len = len;
  memcpy(advertisement.ad_data, RSTRING_PTR(bytes), len);
  if (advertising) {
    method_start_advertising();
  }
  return bytes;
}

VALUE method_start_advertising()
{
  struct hci_request rq;
  le_set_advertising_parameters_cp adv_params_cp;
  uint8_t status;
  
  // open connection to the device
  int device_id = hci_get_route(NULL);
  int device_handle = hci_open_dev(device_id);

  // set advertising data
  memset(&rq, 0, sizeof(rq));
  rq.ogf = OGF_LE_CTL;
  rq.ocf = OCF_LE_SET_ADVERTISING_DATA;
  rq.cparam = &advertisement;
  rq.clen = sizeof(advertisement);
  rq.rparam = &status;
  rq.rlen = 1;
  hci_send_req(device_handle, &rq, 1000);

  // set advertising params
  memset(&adv_params_cp, 0, sizeof(adv_params_cp));
  uint16_t interval_100ms = htobs(0x00A0); // 0xA0 * 0.625ms = 100ms
  adv_params_cp.min_interval = interval_100ms;
  adv_params_cp.max_interval = interval_100ms;
  adv_params_cp.advtype = 0x03; // non-connectable undirected advertising
  adv_params_cp.chan_map = 0x07;// all 3 channels
  memset(&rq, 0, sizeof(rq));
  rq.ogf = OGF_LE_CTL;
  rq.ocf = OCF_LE_SET_ADVERTISING_PARAMETERS;
  rq.cparam = &adv_params_cp;
  rq.clen = LE_SET_ADVERTISING_PARAMETERS_CP_SIZE;
  rq.rparam = &status;
  rq.rlen = 1;
  hci_send_req(device_handle, &rq, 1000);

  // turn on advertising
  hci_le_set_advertise_enable(device_handle, 0x01, 1000);

  // and close the connection
  hci_close_dev(device_handle);
  advertising = 1;
  return Qnil;
}

VALUE method_stop_advertising()
{
  int device_id = hci_get_route(NULL);
  int device_handle = hci_open_dev(device_id);
  hci_le_set_advertise_enable(device_handle, 0x00, 1000);
  hci_close_dev(device_handle);
  advertising = 0;
  return Qnil;
}

VALUE method_device_up()
{
  VALUE success;
  int ctl = socket(AF_BLUETOOTH, SOCK_RAW, BTPROTO_HCI);
  int hdev = 0;
  /* Start HCI device */
  if (ioctl(ctl, HCIDEVUP, hdev) < 0) {
    if (errno == EALREADY) {
      success = Qtrue;
    } else {
      fprintf(stderr, "Can't init device hci%d: %s (%d)\n", hdev, strerror(errno), errno);
      success = Qfalse;
    }
  } else {
    success = Qtrue;
  }
  close(ctl);
  return success;
}

VALUE method_device_down()
{
  VALUE success;
  int ctl = socket(AF_BLUETOOTH, SOCK_RAW, BTPROTO_HCI);
  int hdev = 0;
  /* Stop HCI device */
  if (ioctl(ctl, HCIDEVDOWN, hdev) < 0) {
    fprintf(stderr, "Can't down device hci%d: %s (%d)\n", hdev, strerror(errno), errno);
    success = Qfalse;
  } else {
    success = Qtrue;
  }
  close(ctl);
  return success;
}


VALUE method_scan()
{
  int device_id = hci_get_route(NULL);
  int device_handle = hci_open_dev(device_id);
  uint8_t scan_type = 0x01; //passive
  uint8_t own_type = 0x00; // I think this specifies not to use a random MAC
  uint8_t filter_dups = 0x00;
  uint8_t filter_policy = 0x00; // ?
  uint16_t interval = htobs(0x010);
  uint16_t window = htobs(0x010);
  hci_le_set_scan_parameters(device_handle, scan_type, interval, window, own_type, filter_policy, 1000);
  hci_le_set_scan_enable(device_handle, 0x01, 0x00, 1000);

  unsigned char buf[HCI_MAX_EVENT_SIZE], *ptr;
  struct hci_filter new_filter, old_filter;
  socklen_t olen;
  int len;

  olen = sizeof(old_filter);
  if (getsockopt(device_handle, SOL_HCI, HCI_FILTER, &old_filter, &olen) < 0) {
    printf("Could not get socket options\n");
    return -1;
  }

  hci_filter_clear(&new_filter);
  hci_filter_set_ptype(HCI_EVENT_PKT, &new_filter);
  hci_filter_set_event(EVT_LE_META_EVENT, &new_filter);

  if (setsockopt(device_handle, SOL_HCI, HCI_FILTER, &new_filter, sizeof(new_filter)) < 0) {
    printf("Could not set socket options\n");
    return -1;
  }

  int keep_scanning = 1;
  while (keep_scanning) {
    evt_le_meta_event *meta;
    le_advertising_info *info;
    char addr[18];

    while ((len = read(device_handle, buf, sizeof(buf))) < 0) {
      if (errno == EAGAIN || errno == EINTR) {
        continue;
      }
      keep_scanning = 0;
      break;
    }

    if (len > 0) {
      ptr = buf + (1 + HCI_EVENT_HDR_SIZE);
      len -= (1 + HCI_EVENT_HDR_SIZE);
      meta = (void *) ptr;
      // check if this event is an  advertisement
      if (meta->subevent != EVT_LE_ADVERTISING_REPORT) {
        break;
      }
      // parse out the ad data, the mac, and the rssi
      info = (le_advertising_info *) (meta->data + 1);
      int8_t rssi = (int8_t)info->data[info->length];
      VALUE ad_data = rb_str_new(info->data, info->length);
      ba2str(&info->bdaddr, addr);
      VALUE rb_addr = rb_str_new(addr, strlen(addr));
      VALUE rb_ary = rb_ary_new();
      rb_ary_push(rb_ary, rb_addr);
      rb_ary_push(rb_ary, ad_data);
      rb_ary_push(rb_ary, INT2NUM(rssi));
      // ... and yield it to ruby
      keep_scanning = rb_yield(rb_ary) != Qfalse;
    }
  }

  // put back the old filter
  setsockopt(device_handle, SOL_HCI, HCI_FILTER, &old_filter, sizeof(old_filter));

  // stop scanning
  hci_le_set_scan_enable(device_handle, 0x00, 0x00, 1000);
  hci_close_dev(device_handle);
  return Qnil;
}

#endif // linux
