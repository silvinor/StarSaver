#ifndef StarSaverView_h
#define StarSaverView_h

#import <ScreenSaver/ScreenSaver.h>
#import <Cocoa/Cocoa.h>

@interface Star : NSObject

@property (nonatomic, assign) NSPoint position;
@property (nonatomic, assign) NSInteger novaStage;  // 0 means not going Nova, 1-4 means in Nova stages

@end

@interface StarSaverView : ScreenSaverView

@property (nonatomic, strong) NSArray *starImages;        // Array to hold star images (star1.png to star5.png)
@property (nonatomic, strong) NSMutableArray *stars;      // Array to hold stars (Star objects)
@property (nonatomic, strong) NSMutableArray *novaStars;  // Array to hold stars currently in Nova
@property (nonatomic, strong) NSTimer *moveTimer;         // Timer to control star movement and animation
@property (nonatomic, assign) NSInteger numberOfStars;    // Number of stars
@property (nonatomic, assign) NSInteger novaProbability;  // Probability for Nova (1 in X chance)
@property (nonatomic, assign) NSInteger animationTiming;  // Animation timing in milliseconds
@property (nonatomic, assign) NSSize starSize;            // Size of each star

@property (nonatomic, assign) NSInteger ticksBeforeMove;  // Clock movement frequency
@property (nonatomic, strong) NSString *dateFormat;       // Date format string for the clock
@property (nonatomic, strong) NSColor *clockColor;        // Clock font color
@property (nonatomic, strong) NSFont *clockFont;          // Clock font

- (void)doInit;
- (void)generateStarPositions;
- (void)updateStars;
- (void)moveOrNovaRandomStar;
- (void)loadConfig;  // Method to load configuration from JSON

@end

#endif /* StarSaverView_h */
