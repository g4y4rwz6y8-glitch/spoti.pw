#import <Foundation/Foundation.h>

@interface AirPodsGestures : NSObject
+ (instancetype)sharedInstance;
- (void)startMotionTracking;
- (void)stopMotionTracking;
@end
