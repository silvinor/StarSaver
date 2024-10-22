#ifndef StarSaverView_h
#define StarSaverView_h

#import <ScreenSaver/ScreenSaver.h>
#import <Cocoa/Cocoa.h>

// size of stars as in resouce files  // TODO : Refactor names
#define STAR_CELL_WIDTH 14
#define STAR_CELL_HEIGHT 14

typedef NS_ENUM(NSInteger, StarState) {
  StarStateGone,
  StarStateNormal,
  StarStateExploding,
  StarStateNovaState1,
  StarStateNovaState2,
  StarStateNovaState3
};

@interface Star : NSObject
  @property (nonatomic, assign) StarState state;
  @property (nonatomic, assign) NSPoint position;
  @property (nonatomic, assign) NSPoint offset;
@end

@interface StarSaverView : ScreenSaverView
  @property (nonatomic, strong) NSArray *starImages;        // Array to hold star images (star1.png to star5.png)
  @property (nonatomic, strong) NSMutableArray *stars;      // Array to hold stars (Star objects)
  @property (nonatomic, strong) NSTimer *timer;             // Timer to control star movement and animation
  @property (nonatomic, assign) NSInteger starHead;         // Current star being processed

  @property (nonatomic, assign) NSInteger numberOfStars;    // Number of stars
  @property (nonatomic, assign) NSInteger novaProbability;  // Probability for Nova (1 in X chance)
  @property (nonatomic, assign) NSInteger animationTiming;  // Animation timing in milliseconds

  - (void)drawStarAt:(NSInteger)index;
  - (void)timerTick;
@end

#endif /* StarSaverView_h */
