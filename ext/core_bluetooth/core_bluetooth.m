#ifdef __APPLE__

// Include the Ruby headers and goodies
#include "ruby.h"
#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import <CoreBluetooth/CoreBluetooth.h>

// Defining a space for information and references about the module to be stored internally
VALUE cb_module = Qnil;

// Prototype for the initialization method - Ruby calls this, not you
void Init_core_bluetooth();
VALUE method_scan();
VALUE method_new_adverts();
VALUE new_scan_hash(NSString* device, NSData *data, NSNumber *rssi, NSData *service_uuid);

VALUE method_get_addr();
VALUE method_set_random_addr();
VALUE method_set_advertisement_data(VALUE klass, VALUE data);
VALUE method_start_advertising();
VALUE method_stop_advertising();

// define some hidden methods so we can call them more easily
@interface IOBluetoothHostController ()
- (int)BluetoothHCILESetAdvertiseEnable:(unsigned char)arg1;
- (int)BluetoothHCILESetAdvertisingData:(unsigned char)arg1 advertsingData:(char *)arg2;
- (int)BluetoothHCILESetAdvertisingParameters:(unsigned short)arg1 advertisingIntervalMax:(unsigned short)arg2 advertisingType:(unsigned char)arg3 ownAddressType:(unsigned char)arg4 directAddressType:(unsigned char)arg5 directAddress:(struct BluetoothDeviceAddress { unsigned char x1[6]; }*)arg6 advertisingChannelMap:(unsigned char)arg7 advertisingFilterPolicy:(unsigned char)arg8;
- (int)BluetoothHCILESetScanParameters:(unsigned char)arg1 LEScanInterval:(unsigned short)arg2 LEScanWindow:(unsigned short)arg3 ownAddressType:(unsigned char)arg4 scanningFilterPolicy:(unsigned char)arg5;
- (int)BluetoothHCILESetScanEnable:(unsigned char)arg1 filterDuplicates:(unsigned char)arg2;
- (int)getAddress:(struct BluetoothDeviceAddress { unsigned char x1[6]; }*)arg1;
- (int)BluetoothHCILESetRandomAddress:(const char*)arg1;
@end

@interface BLEDelegate : NSObject <CBCentralManagerDelegate> {
  @private
  NSMutableArray *_scans;
}
- (NSArray *)scans;
@end


@implementation BLEDelegate

- (id)init
{
  self = [super init];
  _scans = [[NSMutableArray alloc] init];
  return self;
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
  NSData *mfgData =  advertisementData[@"kCBAdvDataManufacturerData"];
  NSDictionary *serviceData =  advertisementData[@"kCBAdvDataServiceData"];
  if (mfgData) {
    NSDictionary *scan = @{@"device": peripheral.identifier.UUIDString,
                             @"data": mfgData,
                             @"rssi": RSSI
    };
    @synchronized(_scans) {
      [_scans addObject: scan];
    }
  } else if (serviceData) {
    NSData *svcData = [serviceData allValues][0];
    CBUUID *uuid = serviceData.allKeys[0];
    NSDictionary *scan = @{@"device": peripheral.identifier.UUIDString,
                             @"data": svcData,
                             @"rssi": RSSI,
                              @"service_uuid": uuid.data
    };
    @synchronized(_scans) {
      [_scans addObject: scan];
    }
  }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
  [central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @(YES)}];

  // set custom scan params to achieve better scanning performance
  IOBluetoothHostController * device = IOBluetoothHostController.defaultController;
  [device BluetoothHCILESetScanParameters:0x01
                           LEScanInterval:200
                             LEScanWindow:200
                           ownAddressType:0x00
                     scanningFilterPolicy:0x00];
  [device BluetoothHCILESetScanEnable:0x01 filterDuplicates:0x00];
}

- (NSArray *) scans
{
  NSArray *scanCopy;
  @synchronized(_scans) {
    scanCopy = _scans;
    _scans = [[NSMutableArray alloc] init];
  }
  return scanCopy;
}

@end

VALUE sym_device = Qnil;
VALUE sym_data = Qnil;
VALUE sym_rssi = Qnil;
VALUE sym_service_uuid = Qnil;
BLEDelegate *bleDelegate;
CBCentralManager *centralManager;

// initialize our module here
void Init_core_bluetooth()
{
  VALUE scan_beacon_module = rb_const_get(rb_cObject, rb_intern("ScanBeacon"));
  cb_module = rb_define_module_under(scan_beacon_module, "CoreBluetooth");
  rb_define_singleton_method(cb_module, "scan", method_scan, 0);
  rb_define_singleton_method(cb_module, "new_adverts", method_new_adverts, 0);

  rb_define_singleton_method(cb_module, "get_addr", method_get_addr, 0);
  rb_define_singleton_method(cb_module, "set_random_addr", method_set_random_addr, 0);
  rb_define_singleton_method(cb_module, "set_advertisement_data", method_set_advertisement_data, 1);
  rb_define_singleton_method(cb_module, "start_advertising", method_start_advertising, 1);
  rb_define_singleton_method(cb_module, "stop_advertising", method_stop_advertising, 0);

  sym_device = ID2SYM(rb_intern("device"));
  sym_data = ID2SYM(rb_intern("data"));
  sym_rssi = ID2SYM(rb_intern("rssi"));
  sym_service_uuid = ID2SYM(rb_intern("service_uuid"));
}

// create a ruby hash to yield back to ruby,
// of the form {device: "xxxx", data: "yyyy", rssi: -99}
VALUE new_scan_hash(NSString* device, NSData *data, NSNumber *rssi, NSData *service_uuid)
{
  VALUE hash = rb_hash_new();
  rb_hash_aset(hash, sym_device, rb_str_new_cstr(device.UTF8String));
  rb_hash_aset(hash, sym_data, rb_str_new(data.bytes, data.length));
  rb_hash_aset(hash, sym_rssi, INT2FIX( rssi.integerValue ));
  if (service_uuid) {
    uint16_t uuid = *((uint16_t *)service_uuid.bytes);
    uuid = NSSwapShort(uuid);
    rb_hash_aset(hash, sym_service_uuid, rb_str_new( (void*)&uuid, 2));
  }
  return hash;
}

VALUE method_new_adverts()
{
  @autoreleasepool {
    VALUE ary = rb_ary_new();
    NSArray *scans = bleDelegate.scans;
    for (NSDictionary *scan in scans) {
      VALUE hash = new_scan_hash( scan[@"device"], scan[@"data"], scan[@"rssi"], scan[@"service_uuid"] );
      rb_ary_push(ary, hash);
    }
    [scans release];
    return ary;
  }
}

VALUE method_scan()
{
  @autoreleasepool {
    @try {
      bleDelegate = [[BLEDelegate alloc] init];
      dispatch_queue_t scanQueue;
      scanQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
      centralManager = [[CBCentralManager alloc] initWithDelegate:bleDelegate queue:scanQueue];
      BOOL exit = NO;
      while (!exit) {
        VALUE ret = rb_yield( Qnil );
        exit = (ret == Qfalse);
      }
    }
    @finally {
      [centralManager stopScan];
    }
  }
  return Qnil;
}

VALUE addr_to_rbstr(uint8_t* addr)
{
  char c_str[20];
  sprintf(c_str, "%2.2X:%2.2X:%2.2X:%2.2X:%2.2X:%2.2X",
		addr[5], addr[4], addr[3], addr[2], addr[1], addr[0]);
  return rb_str_new2(c_str);
}

VALUE method_get_addr()
{
  IOBluetoothHostController *device = [IOBluetoothHostController defaultController];
  uint8_t addr[6];
  [device getAddress: (void*)addr];
  return addr_to_rbstr(addr);
}

VALUE method_set_random_addr()
{
  uint8_t addr[6];
  SecRandomCopyBytes(kSecRandomDefault, 6, addr);
  addr[0] = addr[0] & 0x7F;
  IOBluetoothHostController *device = [IOBluetoothHostController defaultController];
  [device BluetoothHCILESetRandomAddress: (void*)addr];
  return addr_to_rbstr(addr);
}

VALUE method_set_advertisement_data(VALUE klass, VALUE data)
{
  IOBluetoothHostController *device = [IOBluetoothHostController defaultController];
  char flags_and_data[40];
  memcpy(flags_and_data, "\x02\x01\x1A", 3);
  memcpy(flags_and_data+3, RSTRING_PTR(data), RSTRING_LEN(data));
  // NOTE: Mac OS X has a typo in the method definition.  This may get fixed in the future.
  [device BluetoothHCILESetAdvertisingData: RSTRING_LEN(data)+3 advertsingData: flags_and_data];
  return Qnil;
}

VALUE method_start_advertising(VALUE klass, VALUE random)
{
  unsigned char ownAddrType = 0x00;
  if (random == Qtrue) {
    ownAddrType = 0x01;
  }
  IOBluetoothHostController *device = [IOBluetoothHostController defaultController];
  [device BluetoothHCILESetAdvertisingParameters: 0x00A0
                          advertisingIntervalMax: 0x00A0 // 100ms
                                 advertisingType: 0x03
                                  ownAddressType: ownAddrType
                               directAddressType: 0x00
                                   directAddress: (void*)"\x00\x00\x00\x00\x00\x00"
                                   advertisingChannelMap: 0x07 // all 3 channels
                                 advertisingFilterPolicy: 0x00];
  if (random == Qtrue) {
    method_set_random_addr();
  }
  [device BluetoothHCILESetAdvertiseEnable: 1];
  return Qnil;
}

VALUE method_stop_advertising()
{
  IOBluetoothHostController *device = [IOBluetoothHostController defaultController];
  [device BluetoothHCILESetAdvertiseEnable: 0];
  return Qnil;
}

#endif // TARGET_OS_MAC
