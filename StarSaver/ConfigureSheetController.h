//  ConfigureSheetController.h
//  StarSaver

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ConfigureSheetController : NSWindowController

//  @property (strong) IBOutlet NSWindow *configureSheet;

  @property (weak) IBOutlet NSTextField *numberOfStarsField;
  @property (weak) IBOutlet NSTextField *novaProbabilityField;
  @property (weak) IBOutlet NSTextField *animationTimingField;

  - (IBAction)okButtonPressed:(id)sender;
  - (IBAction)cancelButtonPressed:(id)sender;

@end

NS_ASSUME_NONNULL_END
