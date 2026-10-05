#import "Sources/Shared/Gestures/AirPodsGestures.h"
#import <CoreMotion/CoreMotion.h>

@interface AirPodsGestures ()
@property (nonatomic, strong) CMHeadphoneMotionManager *motionManager;
@property (nonatomic, assign) NSInteger nodCount;
@property (nonatomic, assign) NSTimeInterval lastNodTimestamp;
@property (nonatomic, assign) NSTimeInterval lastGestureTriggerTime;
@end

@implementation AirPodsGestures

+ (instancetype)sharedInstance {
    static AirPodsGestures *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AirPodsGestures alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _motionManager = [[CMHeadphoneMotionManager alloc] init];
        _nodCount = 0;
        _lastNodTimestamp = 0;
        _lastGestureTriggerTime = 0;
    }
    return self;
}

- (void)startMotionTracking {
    if (!self.motionManager.isDeviceMotionAvailable) return;
    if (self.motionManager.isDeviceMotionActive) return;

    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
        withHandler:^(CMDeviceMotion *motion, NSError *error) {
            if (!motion || error) return;

            NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
            if (currentTime - self.lastGestureTriggerTime < 1.5) return;

            double pitchAcceleration = motion.userAcceleration.z;
            double yawRotationRate = motion.rotationRate.z;

            // Head Shake -> Skip Track
            if (fabs(yawRotationRate) > 3.0) {
                Class playbackControllerClass = NSClassFromString(@"SPTPlayerContextPlaybackController");
                if (playbackControllerClass) {
                    id controller = [playbackControllerClass valueForKey:@"defaultController"];
                    if ([controller respondsToSelector:@selector(skipToNextWithOrigin:)]) {
                        [controller performSelector:@selector(skipToNextWithOrigin:) withObject:nil];
                    }
                }
                self.lastGestureTriggerTime = currentTime;
                self.nodCount = 0;
                return;
            }

            // Double Nod -> Heart / Like Track
            if (pitchAcceleration < -0.85) {
                if (currentTime - self.lastNodTimestamp < 0.7) {
                    self.nodCount++;
                    if (self.nodCount >= 2) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"SPTCollectionPlatformLikeCurrentTrack" object:nil];
                        self.lastGestureTriggerTime = currentTime;
                        self.nodCount = 0;
                    }
                } else {
                    self.nodCount = 1;
                }
                self.lastNodTimestamp = currentTime;
            }
        }];
}

- (void)stopMotionTracking {
    if (self.motionManager.isDeviceMotionActive) {
        [self.motionManager stopDeviceMotionUpdates];
    }
}

@end
__attribute__((constructor))
static void StartAirPodsTrackingOnLaunch(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[AirPodsGestures sharedInstance] startMotionTracking];
    });
}
