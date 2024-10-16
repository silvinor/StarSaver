#import "StarSaverView.h"

@implementation Star

@end

@implementation StarSaverView

// Initializer for normal and preview mode
- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self doInit];
    }
    return self;
}

// Initializer for coder-based initialization
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self doInit];
    }
    return self;
}

// Consolidated initialization method
- (void)doInit {
    // Load configuration from the JSON file
    [self loadConfig];
    
    // Set default values if config is invalid
    if (self.numberOfStars <= 0) {
        self.numberOfStars = 100;  // Default to 100 stars
    }
    if (self.novaProbability <= 0) {
        self.novaProbability = 40;  // Default Nova probability to 1 in 40
    }
    if (self.animationTiming <= 0) {
        self.animationTiming = 250;  // Default animation timing to 250ms
    }
    
    // Adjust star count and animation timing based on screen width
    CGFloat screenWidth = self.bounds.size.width;
    if (screenWidth <= 600) {
        self.numberOfStars = 5;          // Set to 5 stars for smaller screens
        self.animationTiming = 2000;     // Set to 2 seconds for smaller screens
    }
    
    // Set the size of each star (14x14 pixels)
    self.starSize = NSMakeSize(14, 14);
    
    // Load all the star images (star1.png to star5.png)
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
    
    // Initialize the stars array
    self.stars = [NSMutableArray array];
    self.novaStars = [NSMutableArray array];  // Track stars that are in Nova
    
    // Generate star positions based on the screen size
    [self generateStarPositions];
    
    // Set up a timer to move or animate stars based on the animation timing
    self.moveTimer = [NSTimer scheduledTimerWithTimeInterval:(self.animationTiming / 1000.0)
                                                      target:self
                                                    selector:@selector(updateStars)
                                                    userInfo:nil
                                                     repeats:YES];
}

// Method to load configuration from config.json
- (void)loadConfig {
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
}

// Generate random positions for the stars based on the screen size
- (void)generateStarPositions {
    // Get the size of the screen
    CGFloat screenWidth = self.bounds.size.width;
    CGFloat screenHeight = self.bounds.size.height;
    
    // Calculate how many 14x14 cells fit in the screen
    NSInteger cols = screenWidth / self.starSize.width;
    NSInteger rows = screenHeight / self.starSize.height;
    
    // Create a grid of possible positions
    NSMutableArray *possiblePositions = [NSMutableArray array];
    
    for (NSInteger row = 0; row < rows; row++) {
        for (NSInteger col = 0; col < cols; col++) {
            CGFloat x = col * self.starSize.width;
            CGFloat y = row * self.starSize.height;
            NSPoint point = NSMakePoint(x, y);
            [possiblePositions addObject:[NSValue valueWithPoint:point]];
        }
    }
    
    // Shuffle the positions for randomness
    for (NSUInteger i = possiblePositions.count - 1; i > 0; i--) {
        NSUInteger j = arc4random_uniform((uint32_t)(i + 1));
        [possiblePositions exchangeObjectAtIndex:i withObjectAtIndex:j];
    }
    
    // Create stars and assign the first N positions
    for (NSInteger i = 0; i < self.numberOfStars; i++) {
        Star *star = [[Star alloc] init];
        star.position = [[possiblePositions objectAtIndex:i] pointValue];
        star.novaStage = 0;  // 0 means not going Nova
        [self.stars addObject:star];
    }
}

// Update the state of stars (move or progress Nova stages)
- (void)updateStars {
    // First, progress all stars currently in Nova stages
    NSMutableArray *novaStarsToRemove = [NSMutableArray array];  // Temporary array to store stars that finish Nova
    
    for (Star *novaStar in self.novaStars) {
        // Progress through Nova stages
        if (novaStar.novaStage < 4) {
            novaStar.novaStage++;
        } else {
            // Once the star finishes Nova, move it to a new random position and remove it from the Nova list
            [self moveStarToNewPosition:novaStar];
            [novaStarsToRemove addObject:novaStar];
        }
    }
    
    // Remove stars that have completed their Nova
    [self.novaStars removeObjectsInArray:novaStarsToRemove];
    
    // Now pick a random non-Nova star and decide whether to move it or start Nova
    [self moveOrNovaRandomStar];
    
    // Redraw the view with the updated star positions
    [self setNeedsDisplay:YES];
}

// Move or trigger Nova for a random star
- (void)moveOrNovaRandomStar {
    // Find a random star that is not in Nova
    NSUInteger randomIndex = arc4random_uniform((uint32_t)self.stars.count);
    Star *star = [self.stars objectAtIndex:randomIndex];
    
    // Check if the star will go Nova (1 in novaProbability chance)
    if (arc4random_uniform((uint32_t)self.novaProbability) == 0) {
        star.novaStage = 1;  // Start the Nova animation
        [self.novaStars addObject:star];  // Track this star in the Nova list
    } else {
        // If not going Nova, move the star
        [self moveStarToNewPosition:star];
    }
}

// Move the star to a new random position
- (void)moveStarToNewPosition:(Star *)star {
    // Get the size of the screen
    CGFloat screenWidth = self.bounds.size.width;
    CGFloat screenHeight = self.bounds.size.height;
    
    // Calculate how many 14x14 cells fit in the screen
    NSInteger cols = screenWidth / self.starSize.width;
    NSInteger rows = screenHeight / self.starSize.height;
    
    // Pick a new random position
    CGFloat newX = arc4random_uniform((uint32_t)cols) * self.starSize.width;
    CGFloat newY = arc4random_uniform((uint32_t)rows) * self.starSize.height;
    star.position = NSMakePoint(newX, newY);
    
    // Reset the Nova stage
    star.novaStage = 0;
}

// Draw the stars at the assigned positions
- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
    
    // Fill the background with black
    [[NSColor blackColor] setFill];
    NSRectFill(rect);  // Fill the entire screen with black
    
    // Draw the stars at the random positions
    for (Star *star in self.stars) {
        NSImage *starImage;
        
        // Select the appropriate star image based on Nova stage
        if (star.novaStage > 0) {
            starImage = self.starImages[star.novaStage];  // star2.png to star5.png
        } else {
            starImage = self.starImages[0];  // star1.png (default)
        }
        
        // Draw the star
        NSRect starRect = NSMakeRect(star.position.x, star.position.y, self.starSize.width, self.starSize.height);
        [starImage drawInRect:starRect];
    }
}

@end
