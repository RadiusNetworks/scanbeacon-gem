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


#define FLAGS_NOT_CONNECTABLE 0x1A
#define FLAGS_CONNECTABLE     0x18

typedef struct {
  uint8_t len;
  struct {
    uint8_t len;
    uint8_t type;
    uint8_t data;
  } flags;
  uint8_t ad_data[28];
} Advertisement;

Advertisement advertisement;
int advertising;

VALUE method_start_advertising();

void init_advertisement()
{
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
  if (len > 28) {
    len = 28;
  }
  advertisement.len = len + advertisement.flags.len + 1; // + 1 is to account for the flags length field
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


#endif // linux
