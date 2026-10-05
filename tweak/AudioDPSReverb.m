#import "AudioDSPReverb.h"

#define NUM_COMBS 4
#define NUM_ALLPASS 2

static const int COMB_DELAYS[NUM_COMBS] = {1310, 1636, 1812, 1927}; 
static const int ALLPASS_DELAYS[NUM_ALLPASS] = {220, 75};

@implementation AudioDSPReverb {
    float *combBuffers[NUM_COMBS];
    int combIndices[NUM_COMBS];
    float feedback;
    float *allpassBuffers[NUM_ALLPASS];
    int allpassIndices[NUM_ALLPASS];
    float allpassGain;
}

+ (instancetype)sharedInstance {
    static AudioDSPReverb *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AudioDSPReverb alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _wetLevel = 0.0f;
        feedback = 0.82f;
        allpassGain = 0.5f;

        for (int i = 0; i < NUM_COMBS; i++) {
            combBuffers[i] = (float *)calloc(COMB_DELAYS[i], sizeof(float));
            combIndices[i] = 0;
        }

        for (int i = 0; i < NUM_ALLPASS; i++) {
            allpassBuffers[i] = (float *)calloc(ALLPASS_DELAYS[i], sizeof(float));
            allpassIndices[i] = 0;
        }
    }
    return self;
}

- (void)dealloc {
    for (int i = 0; i < NUM_COMBS; i++) free(combBuffers[i]);
    for (int i = 0; i < NUM_ALLPASS; i++) free(allpassBuffers[i]);
}

- (void)processStereoBuffer:(float *)leftChannel right:(float *)rightChannel numFrames:(NSInteger)frames {
    if (self.wetLevel <= 0.001f) return;

    float wet = self.wetLevel;
    float dry = 1.0f - wet;

    for (NSInteger f = 0; f < frames; f++) {
        float monoIn = (leftChannel[f] + rightChannel[f]) * 0.5f;

        float combAccum = 0.0f;
        for (int c = 0; c < NUM_COMBS; c++) {
            int d = COMB_DELAYS[c];
            int idx = combIndices[c];
            float delayed = combBuffers[c][idx];
            combBuffers[c][idx] = monoIn + (delayed * feedback);
            combIndices[c] = (idx + 1) % d;
            combAccum += delayed;
        }
        combAccum *= 0.25f;

        float apCurrent = combAccum;
        for (int a = 0; a < NUM_ALLPASS; a++) {
            int d = ALLPASS_DELAYS[a];
            int idx = allpassIndices[a];
            float delayed = allpassBuffers[a][idx];
            float apOut = -allpassGain * apCurrent + delayed;
            allpassBuffers[a][idx] = apCurrent + (allpassGain * apOut);
            allpassIndices[a] = (idx + 1) % d;
            apCurrent = apOut;
        }

        leftChannel[f] = (leftChannel[f] * dry) + (apCurrent * wet);
        rightChannel[f] = (rightChannel[f] * dry) + (apCurrent * wet);
    }
}

@end
