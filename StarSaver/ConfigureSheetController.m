//  ConfigureSheetController.m
//  StarSaver

#import "ConfigureSheetController.h"
#import "Constants.h"
#import <ScreenSaver/ScreenSaver.h>

NSString * const kXIBName = @"ConfigureSheet";

@implementation ConfigureSheetController

- (instancetype)init {
  self = [super initWithWindowNibName:kXIBName];
  if (self) {
    // NSLog(@"ConfigureSheetController initialized with window: %@", self.window);
    // Initialization code here
  }
  return self;
}

- (void)windowDidLoad {
  [super windowDidLoad];
  // NSLog(@"ConfigureSheetController windowDidLoad");

  ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:kModuleName];
  
  // Load existing preferences
  // NSLog(@"ConfigureSheetController windowDidLoad A");
  NSInteger numberOfStars = [defaults integerForKey:kNumberOfStars];
  NSInteger novaProbability = [defaults integerForKey:kNovaProbability];
  NSInteger animationTiming = [defaults integerForKey:kAnimationTiming];

  // Set UI elements
  // NSLog(@"ConfigureSheetController windowDidLoad B");
  [self.numberOfStarsField setIntegerValue:numberOfStars];
  [self.novaProbabilityField setIntegerValue:novaProbability];
  [self.animationTimingField setIntegerValue:animationTiming];
  
  // NSLog(@"ConfigureSheetController windowDidLoad C");
}

- (IBAction)okButtonPressed:(id)sender {
  ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:kModuleName];

  NSInteger numberOfStars = [self.numberOfStarsField integerValue];
  NSInteger novaProbability = [self.novaProbabilityField integerValue];
  NSInteger animationTiming = [self.animationTimingField integerValue];

  // Validate numberOfStars
  if (numberOfStars < 1) numberOfStars = 1;
  if (numberOfStars > 1000) numberOfStars = 1000;

  // Validate novaProbability
  if (novaProbability < 1) novaProbability = 1;
  if (novaProbability > 1000) novaProbability = 1000;

  // Validate animationTiming
  if (animationTiming < 60) animationTiming = 60;
  if (animationTiming > 10000) animationTiming = 10000;

  [defaults setInteger:numberOfStars forKey:kNumberOfStars];
  [defaults setInteger:novaProbability forKey:kNovaProbability];
  [defaults setInteger:animationTiming forKey:kAnimationTiming];
  [defaults synchronize];

  [NSApp endSheet:self.window];
  [self.window orderOut:nil];
}

- (IBAction)cancelButtonPressed:(id)sender {
  [NSApp endSheet:self.window];
  [self.window orderOut:nil];
}

@end
