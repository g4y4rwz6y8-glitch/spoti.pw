#import <Foundation/Foundation.h>

@interface SGSingAudioProcessor : NSObject
@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, assign) float vocalLevel;     // 0.0 (Silent/Karaoke) to 1.0 (Normal) to 2.0 (Acapella)
@property (nonatomic, assign) BOOL spatialVoiceEnabled;
@property (nonatomic, assign) float headYawAngle;   // Head rotation from AirPods (-1.0 to 1.0)

+ (instancetype)sharedInstance;
- (void)processStereoBuffer:(float *)left right:(float *)right numFrames:(NSInteger)frames;
@end
