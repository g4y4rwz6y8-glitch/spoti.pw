#import <Foundation/Foundation.h>

@interface LiveActivityManager : NSObject
+ (instancetype)sharedInstance;
- (void)updateTrack:(NSString *)track artist:(NSString *)artist duration:(NSTimeInterval)duration isPlaying:(BOOL)playing;
- (void)updateLyricLine:(NSString *)currentLine;
@end
