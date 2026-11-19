//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<mobile_scanner/MobileScannerPlugin.h>)
#import <mobile_scanner/MobileScannerPlugin.h>
#else
@import mobile_scanner;
#endif

#if __has_include(<qr_bar_code/QrBarCodePlugin.h>)
#import <qr_bar_code/QrBarCodePlugin.h>
#else
@import qr_bar_code;
#endif

#if __has_include(<qr_code_scanner_plus/FlutterQrPlusPlugin.h>)
#import <qr_code_scanner_plus/FlutterQrPlusPlugin.h>
#else
@import qr_code_scanner_plus;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [MobileScannerPlugin registerWithRegistrar:[registry registrarForPlugin:@"MobileScannerPlugin"]];
  [QrBarCodePlugin registerWithRegistrar:[registry registrarForPlugin:@"QrBarCodePlugin"]];
  [FlutterQrPlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterQrPlusPlugin"]];
}

@end
