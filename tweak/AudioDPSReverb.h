#import <Foundation/Foundation.h>

@interface AudioDSPReverb : NSObject
@property (nonatomic, assign) float wetLevel;
+ (instancetype)sharedInstance;
- (void)processStereoBuffer:(float *)leftChannel right:(float *)rightChannel numFrames:(NSInteger)frames;
@end
