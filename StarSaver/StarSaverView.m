/*
 * Commander Starry Night Screen Saver
 * A clone of the old Norton Commander 4 Saver
 *
 * ©️ 2024 Vino Rodrigues
 * 
 * @see: https://developer.apple.com/documentation/screensaver?language=objc
 */

#import "StarSaverView.h"
#import "ConfigureSheetController.h"
#import "Constants.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <math.h>

@implementation Star
@end

@interface StarSaverView ()

  // Private vars
  @property (nonatomic, assign) CGFloat width;   // Width of screen at `init`
  @property (nonatomic, assign) CGFloat height;  // Height of screen at `init`
  @property (nonatomic, assign) NSInteger cols;  // Width / {star resources width}
  @property (nonatomic, assign) NSInteger rows;  // Height / {star resources height}
  @property (nonatomic, assign) BOOL doOffsets;  // To offset or not

  @property (strong) ConfigureSheetController *configureSheetController;

  @property (assign) NSInteger numberOfStars;    // Number of stars
  @property (assign) NSInteger novaProbability;  // Probability for Nova (1 in X chance)
  @property (assign) NSInteger animationTiming;  // Animation timing in milliseconds


  // Private methods
  - (NSPoint)randomPosition;
  - (NSPoint)randomOffset;
  - (NSRect)getStarRect:(Star*)star;
  - (void)internalInit;
@end

@implementation StarSaverView

// ==================================================
#pragma mark - Init Methods
// ==================================================

// ------------------------------
// Initializer for normal and preview mode
// ------------------------------
- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
  self = [super initWithFrame:frame isPreview:isPreview];
  NSLog(@"StarSaverView initWithFrame:isPreview:");
  if (self) {
    [self internalInit];
  }
  return self;
}

// ------------------------------
// Initializer for coder-based initialization
// ------------------------------
- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  NSLog(@"StarSaverView initWithCoder:isPreview:");
  if (self) {
    [self internalInit];
  }
  return self;
}

// ------------------------------
// Consolidated initialisation method
// ------------------------------
- (void)internalInit {
  NSLog(@"StarSaverView internalInit");
  self.isRunning = false;
  
  // ----- Initialize RandomSeed -----
  NSLog(@"StarSaverView internalInit A");
  // Use the current time to set a unique seed
  srand((unsigned int)time(NULL));  // used by `rand()`
  srandom((unsigned int)time(NULL));  // used by `random()`

  // ----- Get the size of the screen -----
  NSLog(@"StarSaverView internalInit B");
  self.width = self.bounds.size.width; if (self.width <= 0) { self.width = 1; }
  self.height = self.bounds.size.height; if (self.height <= 0) { self.width = 1; }
  self.cols = floor( self.width / STAR_CELL_WIDTH ); if (self.cols <= 0) { self.cols = 1; }
  self.rows = floor( self.height / STAR_CELL_HEIGHT ); if (self.rows <= 0) { self.rows = 1; }
    
  // ----- Preferences -----

  NSLog(@"StarSaverView internalInit C");
  NSNumber *fallbackNumberOfStars;
  NSNumber *fallbackNovaProbability;
  NSNumber *fallbackAnimationTiming;

  @try {
    // Default to 1% of the cell count
    // On Legacy iMac 27" that's `((2560/14)*(1440/14))*0.01` = `188`
    // Have not tested this on a Retina display :(
    NSLog(@"StarSaverView internalInit self.rows = %ld, self.cols = %ld", (long)self.rows, (long)self.cols);
    fallbackNumberOfStars = @(floor((self.rows * self.cols) * 0.01));
    // Default Nova probability to 1 in 25
    fallbackNovaProbability = @(25);
    // Default animation timing set so that each star lives for aprox. 1 m
    NSLog(@"StarSaverView internalInit self.numberOfStars = %ld", (long)self.numberOfStars);
    if (self.numberOfStars > 0) {
      fallbackAnimationTiming = @(floor((1000 * 60) / (self.numberOfStars / 2)));
    } else {
      fallbackAnimationTiming = @(250);
    }
  }
  @catch (NSException *exception) {
    NSLog(@"StarSaverView internalInit Exception: %@", exception);
    return;
  }

  NSLog(@"StarSaverView internalInit 1");
  ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:kModuleName];
  NSLog(@"StarSaverView internalInit 2");

  NSLog(@"StarSaverView internalInit D");
  // Register default preferences
  [defaults registerDefaults:@{
    kNumberOfStars: fallbackNumberOfStars,
    kNovaProbability: fallbackNovaProbability,
    kAnimationTiming: fallbackAnimationTiming
    }];

  // Load user configuration
  NSLog(@"StarSaverView internalInit 3");
  [self loadPreferences];
  NSLog(@"StarSaverView internalInit 4");
  
  NSLog(@"StarSaverView internalInit E");
  // Adjust star count and animation timing based on screen width
  if (self.isPreview && self.width <= 639) {
    self.numberOfStars = 10;      // Set to 5 stars for smaller screens
    self.animationTiming = 2000; // Set to 2 seconds for smaller screens
    self.starHead = self.numberOfStars - 1;
  } else {
    // Initially show 1/4 the stars ;)  OG started at 0, but...
    self.starHead = floor( self.numberOfStars / 4);
  }
  
  NSLog(@"StarSaverView internalInit F");
  // Load all the star images (`star1.png` to `star5.png`)
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSMutableArray *loadedImages = [NSMutableArray array];
  for (int i = 1; i <= 5; i++) {
    NSString *imagePath = [bundle pathForResource:[NSString stringWithFormat:@"star%d", i] ofType:@"png"];
    if (imagePath) {
      NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
      if (image) {
        [loadedImages addObject:image];
      }
    }
  }
  self.starImages = [loadedImages copy];
  
  // ----- Initialise the Stars -----
  
  NSLog(@"StarSaverView internalInit G");
  // Initialize the stars array
  self.stars = [NSMutableArray array];

  // Build the star array with initial random positions
  for (NSInteger i = 0; i < self.numberOfStars; i++) {
    Star *star = [[Star alloc] init];
    if (i >= self.starHead) {
      star.state = StarStateGone;
    } else {
      star.state = StarStateNormal;
      star.position = self.randomPosition;
      if (self.doOffsets) {
        star.offset = self.randomOffset;
      } else {
        star.offset = NSMakePoint(0, 0);
      }
    }
    [self.stars addObject:star];
  }

  NSLog(@"StarSaverView internalInit H");
  // Needs `animateOneFrame`
  NSTimeInterval interval = self.animationTiming / 1000.0;  // settings is in ms
  [self setAnimationTimeInterval:interval];
}

// ==================================================
#pragma mark - Preference Methods
// ==================================================

// ------------------------------
// Load the screen saver settings
// ------------------------------
- (void)loadPreferences {
  NSLog(@"StarSaverView loadPreferences");
  ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:kModuleName];

  self.numberOfStars = [defaults integerForKey:kNumberOfStars];
  self.novaProbability = [defaults integerForKey:kNovaProbability];
  self.animationTiming = [defaults integerForKey:kAnimationTiming];
}

// ==================================================
#pragma mark - Private Helper Methods
// ==================================================

// ------------------------------
// Generate random co-ordinates
// ------------------------------
- (NSPoint)randomPosition {
  return NSMakePoint( SSRandomIntBetween(0, (int)self.cols),
                      SSRandomIntBetween(0, (int)self.rows) );
}

// ------------------------------
// Generate random offsets
// ------------------------------
- (NSPoint)randomOffset {
  return NSMakePoint( SSRandomIntBetween(0, (int)STAR_CELL_WIDTH),
                      SSRandomIntBetween(0, (int)STAR_CELL_HEIGHT) );
}

// ------------------------------
// Get the Rect that the star lives in
// ------------------------------
- (NSRect)getStarRect:(Star *)star {
  NSInteger ox = star.offset.x;
  NSInteger oy = star.offset.y;

  // adjust so that it's not off screen
  while (((star.position.x * STAR_CELL_WIDTH) + ox) > self.width) {
    ox--;
  }
  while (((star.position.y * STAR_CELL_HEIGHT) + oy) > self.height) {
    oy--;
  }
  
  return NSMakeRect( (star.position.x * STAR_CELL_WIDTH) + ox,
                    (star.position.y * STAR_CELL_HEIGHT) + oy,
                    STAR_CELL_WIDTH,
                    STAR_CELL_HEIGHT );
}

// ------------------------------
// Draw star at n-th position
// ------------------------------
- (void)drawStarAt:(NSInteger)index {
  NSImage *starImage;
  Star *star = [self.stars objectAtIndex:(index)];  // Get the start at the head position

  // Select the appropriate star image based on Nova stage
  switch (star.state) {
    case StarStateNormal:
      starImage = self.starImages[0];
      break;
    case StarStateExploding:
      starImage = self.starImages[1];
      break;
    case StarStateNovaState1:
      starImage = self.starImages[2];
      break;
    case StarStateNovaState2:
      starImage = self.starImages[3];
      break;
    case StarStateNovaState3:
      starImage = self.starImages[4];
      break;
    default:
      starImage = nil;
      break;
  }

  // Draw the star
  if (starImage != nil) {
    [starImage drawInRect:[self getStarRect:star]];
  }
}

// ==================================================
#pragma mark - Key Screen Saver Methods
// ==================================================

// ------------------------------
- (void)startAnimation {
  NSLog(@"StarSaverView startAnimation");
  [super startAnimation];
 
  [self loadPreferences];
  
  self.isRunning = true;
  [self setNeedsDisplay:YES];  // redraw the whole screen
}

// ------------------------------
- (void)stopAnimation {
  NSLog(@"StarSaverView stopAnimation");
  [super stopAnimation];
  
  self.isRunning = false;
}

// ------------------------------
// Draw area needed
// ------------------------------
- (void)drawRect:(NSRect)rect {
  [super drawRect:rect];
  
  // Fill the background with black
  [[NSColor blackColor] setFill];
  NSRectFill(rect);  // Fill the rect with black

  // Draw the stars if needed
  for (NSInteger i = 0; i < self.numberOfStars; i++) {
    Star *star = [self.stars objectAtIndex:(i)];
    if (NSContainsRect( rect, [self getStarRect:star] )) {
      [self drawStarAt:i];
    }
  }
}

// ------------------------------
// Gets called repeatedly to draw states on timer ticks
// when used with `setAnimationTimeInterval`
// ------------------------------
- (void)animateOneFrame {
  [super animateOneFrame];
  if (self.isRunning) {
    [self timerTick];
  }
  return;
}

// ---------------------------------
// Abstracting Timer Ticks here
// ---------------------------------
- (void)timerTick {
  NSInteger index = self.starHead;
  
  Star *star = [self.stars objectAtIndex:(index)];  // Get the start at the head position
  StarState newState = StarStateNormal;

  switch (star.state) {
    case StarStateNormal:
      newState = StarStateExploding;
      break;
    case StarStateExploding:
      if (SSRandomIntBetween(0, (int)self.novaProbability) == 0) {
        newState = StarStateNovaState1;
      } else {
        newState = StarStateGone;
      }
      break;
    case StarStateNovaState1:
      newState = StarStateNovaState2;
      break;
    case StarStateNovaState2:
      newState = StarStateNovaState3;
      break;
    case StarStateNovaState3:
      newState = StarStateGone;
      break;
    default: // StarSateGone
      
      // Invalidate old position
      [self setNeedsDisplayInRect:[self getStarRect:star]];

      // New position
      star.position = self.randomPosition;  // new position
      if (self.doOffsets) {
        star.offset = self.randomOffset;  // new offset
      }
  
      // inc the header, i.e. move on to the next star
      self.starHead++;
      if (self.starHead >= self.numberOfStars) {
        self.starHead = 0;  // restart
      }
      break;
  }

  star.state = newState;

  // Force the star area to redraw
  [self setNeedsDisplayInRect:[self getStarRect:star]];
}

// ==================================================
#pragma mark - Configuration Sheet Methods
// ==================================================

// ------------------------------
// ------------------------------
- (BOOL)hasConfigureSheet {
  NSLog(@"StarSaverView hasConfigureSheet");
  return YES;
}

// ------------------------------
// ------------------------------
- (NSWindow*)configureSheet {
  NSLog(@"StarSaverView configureSheet");
  
  if (!self.configureSheetController) {
    self.configureSheetController = [[ConfigureSheetController alloc] init];
  }
  return self.configureSheetController.window;
}

@end
