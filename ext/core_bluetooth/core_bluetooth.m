// Include the Ruby headers and goodies
#include "ruby.h"
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

// Defining a space for information and references about the module to be stored internally
VALUE cb_module = Qnil;
dispatch_group_t scanGroup;

// Prototype for the initialization method - Ruby calls this, not you
void Init_scanbeaconcb();
VALUE method_cb_scan();

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
    scanCopy = [_scans copy];
    [_scans removeAllObjects];
  }
  return scanCopy;
}

@end


void Init_core_bluetooth()
{
  printf("Init_scanbeaconcb()");
  VALUE scan_beacon_module = rb_const_get(rb_cObject, rb_intern("ScanBeacon"));
  cb_module = rb_define_module_under(scan_beacon_module, "CoreBluetooth");
  rb_define_method(cb_module, "cb_scan", method_cb_scan, 0);
}

VALUE method_cb_scan()
{
  VALUE scans = rb_ary_new();
  VALUE sym_device = ID2SYM(rb_intern("device"));
  VALUE sym_data = ID2SYM(rb_intern("data"));
  VALUE sym_rssi = ID2SYM(rb_intern("rssi"));

  @autoreleasepool {
    BLEDelegate *bleDelegate = [[BLEDelegate alloc] init];
    dispatch_queue_t scanQueue;// = dispatch_queue_create("com.example.ScanBeacon.scan", DISPATCH_QUEUE_CONCURRENT);
    scanQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    CBCentralManager *centralManager = [[CBCentralManager alloc] initWithDelegate:bleDelegate queue:scanQueue];
    BOOL exit = NO;
    while (!exit) {
      [NSThread sleepForTimeInterval:0.1f];
      //sleep(0.1);
      NSArray *scans = bleDelegate.scans;
      for (NSDictionary *scan in scans) {
        VALUE hash = rb_hash_new();
        NSString *device = scan[@"device"];
        NSData *data = scan[@"data"];
        NSNumber *rssi = scan[@"rssi"];
        rb_hash_aset(hash, sym_device, rb_str_new_cstr(device.UTF8String));
        rb_hash_aset(hash, sym_data, rb_str_new(data.bytes, data.length));
        rb_hash_aset(hash, sym_rssi, INT2NUM( rssi.integerValue ));
        VALUE ret = rb_yield( hash );
        exit = (ret == Qfalse);
      }
    }
    [centralManager stopScan];
  }
  return Qnil;
}

