#ifdef linux
#include "ruby.h"
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <time.h>
#include <bluetooth/bluetooth.h>
#include <bluetooth/hci.h>
#include <bluetooth/hci_lib.h>

#include "utils.h"

VALUE method_scan();


VALUE stop_scan(VALUE device_id);
VALUE perform_scan(VALUE device_id);

struct hci_filter stored_filters[10];
int device_handles[10];

VALUE method_scan(int argc, VALUE *argv, VALUE klass)
{
  VALUE rb_device_id;
  int device_id;
  int device_handle;
  uint8_t scan_type = 0x01; //passive
  uint8_t own_type = 0x00; // I think this specifies not to use a random MAC
  uint8_t filter_dups = 0x00;
  uint8_t filter_policy = 0x00; // ?
  uint16_t interval = htobs(0x0005);
  uint16_t window = htobs(0x0005);

  struct hci_filter new_filter;

  // which device was specified?
  rb_scan_args(argc, argv, "01", &rb_device_id);
  if (rb_device_id == Qnil) {
    device_id = hci_get_route(NULL);
  } else {
    device_id = NUM2INT(rb_device_id);
  }
  // open the device
  if ( (device_handle = hci_open_dev(device_id)) < 0) {
    rb_raise(rb_eException, "Could not open device");
  }
  device_handles[device_id] = device_handle;
 
  // save the old filter so we can restore it later
  socklen_t filter_size = sizeof(stored_filters[0]);
  if (getsockopt(device_handle, SOL_HCI, HCI_FILTER, &stored_filters[device_id], &filter_size) < 0) {
    rb_raise(rb_eException, "Could not get socket options");
  }

  // new filter to only look for event packets
  hci_filter_clear(&new_filter);
  hci_filter_set_ptype(HCI_EVENT_PKT, &new_filter);
  hci_filter_set_event(EVT_LE_META_EVENT, &new_filter);
  if (setsockopt(device_handle, SOL_HCI, HCI_FILTER, &new_filter, sizeof(new_filter)) < 0) {
    rb_raise(rb_eException, "Could not set socket options");
  }

  // set the params
  hci_le_set_scan_parameters(device_handle, scan_type, interval, window, own_type, filter_policy, 1000);
  hci_le_set_scan_enable(device_handle, 0x01, filter_dups, 1000);

  // perform the scan and make sure device gets put back into a proper state
  // even in the case of being interrupted by a ruby exception
  rb_ensure(perform_scan, INT2FIX(device_id), stop_scan, INT2FIX(device_id));
  return Qnil;
}

VALUE perform_scan(VALUE device_id_in)
{
  int device_id = FIX2INT(device_id_in);
  int device_handle = device_handles[device_id];
  unsigned char buf[HCI_MAX_EVENT_SIZE], *ptr;
  int len;
  int keep_scanning = 1;
  while (keep_scanning) {
    evt_le_meta_event *meta;
    le_advertising_info *info;

    // wait for data with a timeout
    fd_set set;
    FD_ZERO(&set);
    FD_SET(device_handle, &set);
    struct timeval timeout;
    timeout.tv_sec = 0;
    timeout.tv_usec = 200000; // 200ms
    int ret = select(device_handle + 1, &set, NULL, NULL, &timeout);
    if (ret < 0) {
      rb_raise(rb_eException, "Error waiting for data");
    } else if (ret == 0) {
      // timeout.  yield nil to give ruby a chance to stop the scan.
      keep_scanning = rb_yield(Qnil) != Qfalse;
      continue;
    }

    // keep trying to read until we get something
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
      // check if this event is an advertisement
      if (meta->subevent != EVT_LE_ADVERTISING_REPORT) {
        continue;
      }
      // parse out the ad data, the mac, and the rssi
      info = (le_advertising_info *) (meta->data + 1);
      VALUE rssi = INT2FIX( (int8_t)info->data[info->length] );
      VALUE ad_data = rb_str_new((void *)info->data, info->length);
      VALUE addr = ba2value(&info->bdaddr);
      keep_scanning = rb_yield_values(3, addr, ad_data, rssi) != Qfalse;
    }
  }
  return Qnil;
}

VALUE stop_scan(VALUE device_id_in)
{
  int device_id = FIX2INT(device_id_in);
  int device_handle = device_handles[device_id];

  // put back the old filter
  setsockopt(device_handle, SOL_HCI, HCI_FILTER, &stored_filters[device_id], sizeof(stored_filters[0]));

  // stop scanning
  hci_le_set_scan_enable(device_handle, 0x00, 0x00, 1000);
  hci_close_dev(device_handle);
  return Qnil;
}

#endif // linux
