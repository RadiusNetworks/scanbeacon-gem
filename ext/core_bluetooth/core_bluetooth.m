#ifdef __APPLE__

// Include the Ruby headers and goodies
#include "ruby.h"
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

// Defining a space for information and references about the module to be stored internally
VALUE cb_module = Qnil;

// Prototype for the initialization method - Ruby calls this, not you
void Init_core_bluetooth();
VALUE method_scan();
VALUE method_new_adverts();
VALUE new_scan_hash(NSString* device, NSData *data, NSNumber *rssi);

@interface BLEDelegate : NSObject <CBCentralManagerDelegate>
- (NSArray *)scans;
@end

@implementation BLEDelegate {
  NSMutableArray *_scans;
}

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
  if (mfgData) {
    NSDictionary *scan = @{@"device": peripheral.identifier.UUIDString,
                             @"data": mfgData,
                             @"rssi": RSSI};
    @synchronized(_scans) {
      [_scans addObject: scan];
    }
  }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
  [central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey : @(YES)}];
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
BLEDelegate *bleDelegate;
CBCentralManager *centralManager;

// initialize our module here
void Init_core_bluetooth()
{
  VALUE scan_beacon_module = rb_const_get(rb_cObject, rb_intern("ScanBeacon"));
  cb_module = rb_define_module_under(scan_beacon_module, "CoreBluetooth");
  rb_define_singleton_method(cb_module, "scan", method_scan, 0);
  rb_define_singleton_method(cb_module, "new_adverts", method_new_adverts, 0);

  sym_device = ID2SYM(rb_intern("device"));
  sym_data = ID2SYM(rb_intern("data"));
  sym_rssi = ID2SYM(rb_intern("rssi"));
}

// create a ruby hash to yield back to ruby,
// of the form {device: "xxxx", data: "yyyy", rssi: -99}
VALUE new_scan_hash(NSString* device, NSData *data, NSNumber *rssi)
{
  VALUE hash = rb_hash_new();
  rb_hash_aset(hash, sym_device, rb_str_new_cstr(device.UTF8String));
  rb_hash_aset(hash, sym_data, rb_str_new(data.bytes, data.length));
  rb_hash_aset(hash, sym_rssi, INT2NUM( rssi.integerValue ));
  return hash;
}

VALUE method_new_adverts()
{
  @autoreleasepool {
    VALUE ary = rb_ary_new();
    NSArray *scans = bleDelegate.scans;
    for (NSDictionary *scan in scans) {
      VALUE hash = new_scan_hash( scan[@"device"], scan[@"data"], scan[@"rssi"] );
      rb_ary_push(ary, hash);
    }
    [scans release];
    return ary;
  }
}

VALUE method_scan()
{
  VALUE scans = rb_ary_new();

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

#endif // TARGET_OS_MAC
