//  ConfigureSheetController.m
//  StarSaver

#import "ConfigureSheetController.h"
#import "Constants.h"
#import <ScreenSaver/ScreenSaver.h>

@implementation ConfigureSheetController

- (instancetype)init {
  self = [super initWithWindowNibName:@"ConfigureSheet"];
//  if (self) {
//    // Initialization code here
//  }
  return self;
}

- (void)windowDidLoad {
  [super windowDidLoad];
  NSLog(@"ConfigureSheetController windowDidLoad");

  ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:kModuleName];
  
  // Load existing preferences
  NSInteger numberOfStars = [defaults integerForKey:kNumberOfStars];
  NSInteger novaProbability = [defaults integerForKey:kNovaProbability];
  NSInteger animationTiming = [defaults integerForKey:kAnimationTiming];

  // Set UI elements
  [self.numberOfStarsField setIntegerValue:numberOfStars];
  [self.novaProbabilityField setIntegerValue:novaProbability];
  [self.animationTimingField setIntegerValue:animationTiming];
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
}

- (IBAction)cancelButtonPressed:(id)sender {
  [NSApp endSheet:self.window];
}

@end
