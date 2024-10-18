/*
 * Commander Starry Night Screen Saver
 * A clone of the old Norton Commander 4 Saver
 *
 * ©️ 2024 Vino Rodrigues
 * 
 * @see: https://developer.apple.com/documentation/screensaver?language=objc
 */

#import "StarSaverView.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <math.h>

@implementation Star
@end

@implementation StarSaverView

// ------------------------------
// Initializer for normal and preview mode
// ------------------------------
- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
  self = [super initWithFrame:frame isPreview:isPreview];
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
  if (self) {
    [self internalInit];
  }
  return self;
}

// ------------------------------
// Load the screen saver settings
// ------------------------------
// TODO : Change this to use the `ScreenSaverDefaults` class
- (void)loadPreferences {
  // Load configuration from the JSON file
  NSString *configFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"config" ofType:@"json"];
  
  if (configFilePath) {
    NSData *data = [NSData dataWithContentsOfFile:configFilePath];
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
      
    if (!error && json) {
      NSNumber *starCount = json[@"starCount"];
      NSNumber *novaProbability = json[@"novaProbability"];
      NSNumber *animationTiming = json[@"animationTiming"];
          
      if (starCount) {
        self.numberOfStars = [starCount integerValue];
      }
      if (novaProbability) {
        self.novaProbability = [novaProbability integerValue];
      }
      if (animationTiming) {
        self.animationTiming = [animationTiming integerValue];
      }
    }
  }

  // Set default values if config is invalid
  if ((self.numberOfStars <= 0) || (self.numberOfStars > 1000)) {  // 1 to 1000
    // Default to 1% of the cell count
    // On Legacy iMac 27" that's `((2560/14)*(1440/14))*0.01` = `188`
    // Have not tested this on a Retina display :(
    self.numberOfStars = floor(((self.bounds.size.width / STAR_CELL_WIDTH) * (self.bounds.size.height / STAR_CELL_HEIGHT)) * 0.01);
  }
  if ((self.novaProbability < 0) || (self.novaProbability > 1000)) {  // 0 to 1000, NB: 0 = always
    // Default Nova probability to 1 in 40
    self.novaProbability = 25;
  }
  if ((self.animationTiming < 60) || (self.animationTiming > 60000)) {  // 1/60 s to 1 min
    // Default animation timing set so that each star lives for aprox. 1 m
    self.animationTiming = floor((1000 * 60) / (self.numberOfStars / 2));
  }
}

// ------------------------------
// Generate random co-ordinates
// ------------------------------
- (NSPoint)randomPosition {
  NSInteger cols = floor( self.bounds.size.width / STAR_CELL_WIDTH );
  NSInteger rows = floor( self.bounds.size.height / STAR_CELL_HEIGHT );

  CGFloat x = SSRandomIntBetween(0, (int)cols);
  CGFloat y = SSRandomIntBetween(0, (int)rows);
  NSPoint point = NSMakePoint(x, y);

  return point;
}

// ------------------------------
// Consolidated initialisation methods
// ------------------------------
- (void)internalInit {
  // Get the size of the screen
  CGFloat screenWidth = self.bounds.size.width;
  
  // ----- Initialize RandomSeed -----
  // Use the current time to set a unique seed
  srand((unsigned int)time(NULL));  // used by `rand()`
  srandom((unsigned int)time(NULL));  // used by `random()`

  // ----- Preferences -----
  
  // Load user configuration
  [self loadPreferences];
  
  // Adjust star count and animation timing based on screen width
  if (self.isPreview && screenWidth <= 639) {
    self.numberOfStars = 5;      // Set to 5 stars for smaller screens
    self.animationTiming = 2000; // Set to 2 seconds for smaller screens
  }
    
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
  
  // self.starHead = 0;  // Start the star "buffer" at the begining
  self.starHead = floor( self.numberOfStars / 4);  // Initially show 1/4 the stars ;)  OG started at 0, but...

  // Initialize the stars array
  self.stars = [NSMutableArray array];

  // Build the star array with initial random positions
  for (NSInteger i = 0; i < self.numberOfStars; i++) {
    Star *star = [[Star alloc] init];
    if (i >= self.starHead) {
      // star.position = NSMakePoint(0, 0);
      star.state = StarStateGone;
    } else {
      star.position = self.randomPosition;
      star.state = StarStateNormal;
    }
    [self.stars addObject:star];
  }

  //  // Needs `animateOneFrame`
  //  NSTimeInterval interval = self.animationTiming / 1000.0;  // settings is in ms
  //  [self setAnimationTimeInterval:interval];
}

// ------------------------------
- (void)startAnimation {
  [super startAnimation];
  
  // Create a timer that fires {every X} and calls the 'timerTick' method

  NSTimeInterval interval = self.animationTiming / 1000.0;
  self.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                target:self
                                              selector:@selector(timerTick)
                                              userInfo:nil
                                               repeats:YES];

  [self setNeedsDisplay:YES];  // redraw the whole screen
}

// ------------------------------
- (void)stopAnimation {
  [super stopAnimation];

  // Invalidate the timer when stopping the screen saver
  [self.timer invalidate];
  self.timer = nil;
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
    [starImage drawInRect:NSMakeRect(star.position.x * STAR_CELL_WIDTH,
                                     star.position.y * STAR_CELL_HEIGHT,
                                     STAR_CELL_WIDTH,
                                     STAR_CELL_HEIGHT)];
  }
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
    if (NSContainsRect(rect, NSMakeRect(star.position.x * STAR_CELL_WIDTH,
                                        star.position.y * STAR_CELL_HEIGHT,
                                        STAR_CELL_WIDTH,
                                        STAR_CELL_HEIGHT))) {
      [self drawStarAt:i];
    }
  }
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
      [self setNeedsDisplayInRect:NSMakeRect(star.position.x * STAR_CELL_WIDTH,
                                             star.position.y * STAR_CELL_HEIGHT,
                                             STAR_CELL_WIDTH,
                                             STAR_CELL_HEIGHT)];

      // New position
      star.position = self.randomPosition;  // new position
  
      // inc the header, i.e. move on to the next star
      self.starHead++;
      if (self.starHead >= self.numberOfStars) {
        self.starHead = 0;  // restart
      }
      break;
  }

  star.state = newState;

  // Force the star area to redraw
  [self setNeedsDisplayInRect:NSMakeRect(star.position.x * STAR_CELL_WIDTH,
                                         star.position.y * STAR_CELL_HEIGHT,
                                         STAR_CELL_WIDTH,
                                         STAR_CELL_HEIGHT)];
}

//// ------------------------------
//// Gets called repeatedly to draw states on timer ticks 
//// when used with `setAnimationTimeInterval`
//// ------------------------------
//- (void)animateOneFrame {
//  [super animateOneFrame];
//  [self timerTick];
//  return;
//}

// ------------------------------
// TODO: Later
// ------------------------------
- (BOOL)hasConfigureSheet {
  return NO;
}

// ------------------------------
// TODO: Later
// ------------------------------
- (NSWindow*)configureSheet {
  return nil;
}

@end
