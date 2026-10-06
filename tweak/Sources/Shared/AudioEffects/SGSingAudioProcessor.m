#import "SGSingAudioProcessor.h"
#import <CoreMotion/CoreMotion.h>

@interface SGSingAudioProcessor ()
@property (nonatomic, strong) CMHeadphoneMotionManager *motionManager;
@end

@implementation SGSingAudioProcessor {
    // 2nd-order IIR bandpass filter state for vocal range (300 Hz - 3400 Hz)
    float bp_x1, bp_x2, bp_y1, bp_y2;
    float b0, b1, b2, a1, a2;
}

+ (instancetype)sharedInstance {
    static SGSingAudioProcessor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SGSingAudioProcessor alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _isEnabled = NO;
        _vocalLevel = 1.0f; // Default normal volume
        _spatialVoiceEnabled = NO;
        _headYawAngle = 0.0f;

        // Bandpass filter coefficients centered at 1 kHz (Q = 1.0) at 44.1 kHz
        float w0 = 2.0f * M_PI * 1000.0f / 44100.0f;
        float alpha = sinf(w0) / (2.0f * 1.0f);
        b0 = alpha;
        b1 = 0.0f;
        b2 = -alpha;
        float a0 = 1.0f + alpha;
        a1 = -2.0f * cosf(w0) / a0;
        a2 = (1.0f - alpha) / a0;
        b0 /= a0;
        b2 /= a0;

        _motionManager = [[CMHeadphoneMotionManager alloc] init];
    }
    return self;
}

- (void)setSpatialVoiceEnabled:(BOOL)spatialVoiceEnabled {
    _spatialVoiceEnabled = spatialVoiceEnabled;
    if (spatialVoiceEnabled && self.motionManager.isDeviceMotionAvailable) {
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]
            withHandler:^(CMDeviceMotion *motion, NSError *error) {
                if (motion) {
                    // Head rotation left/right (yaw)
                    self.headYawAngle = (float)motion.attitude.yaw;
                }
            }];
    } else {
        [self.motionManager stopDeviceMotionUpdates];
        self.headYawAngle = 0.0f;
    }
}

- (void)processStereoBuffer:(float *)left right:(float *)right numFrames:(NSInteger)frames {
    if (!self.isEnabled || fabsf(self.vocalLevel - 1.0f) < 0.01f) {
        if (!self.spatialVoiceEnabled) return;
    }

    float vocalGain = self.vocalLevel;

    // Spatial panning offsets based on head turn
    float panL = 1.0f;
    float panR = 1.0f;
    if (self.spatialVoiceEnabled) {
        // If head turns right, voice pans left to stay anchored in front
        panL = fminf(fmaxf(1.0f - self.headYawAngle, 0.2f), 1.8f);
        panR = fminf(fmaxf(1.0f + self.headYawAngle, 0.2f), 1.8f);
    }

    for (NSInteger i = 0; i < frames; i++) {
        float l = left[i];
        float r = right[i];

        // 1. Mid/Side decomposition
        float mid = (l + r) * 0.5f;
        float side = (l - r) * 0.5f;

        // 2. Bandpass filter the center Mid channel (isolate vocal frequencies)
        float midVocal = b0 * mid + b1 * bp_x1 + b2 * bp_x2 - a1 * bp_y1 - a2 * bp_y2;
        bp_x2 = bp_x1;
        bp_x1 = mid;
        bp_y2 = bp_y1;
        bp_y1 = midVocal;

        float midResidual = mid - midVocal;

        if (vocalGain <= 1.0f) {
            // Karaoke Mode: scale down center vocals
            float newMid = midResidual + (midVocal * vocalGain);
            left[i] = (newMid + side) * (self.spatialVoiceEnabled ? panL : 1.0f);
            right[i] = (newMid - side) * (self.spatialVoiceEnabled ? panR : 1.0f);
        } else {
            // Acapella Mode: attenuate instrumentals, boost center vocal
            float acapellaFactor = vocalGain - 1.0f; // 0.0 to 1.0
            float instrumentalGain = 1.0f - acapellaFactor;
            left[i] = (midResidual * instrumentalGain) + (midVocal * panL);
            right[i] = (midResidual * instrumentalGain) + (midVocal * panR);
        }
    }
}

@end
