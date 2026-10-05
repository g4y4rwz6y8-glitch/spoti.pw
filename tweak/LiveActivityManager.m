#import "LiveActivityManager.h"

@interface LiveActivityManager ()
@property (nonatomic, strong) NSUserDefaults *sharedDefaults;
@end

@implementation LiveActivityManager

+ (instancetype)sharedInstance {
    static LiveActivityManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LiveActivityManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.spotify.client"];
    }
    return self;
}

- (void)updateTrack:(NSString *)track artist:(NSString *)artist duration:(NSTimeInterval)duration isPlaying:(BOOL)playing {
    if (!self.sharedDefaults) return;

    [self.sharedDefaults setObject:(track ?: @"") forKey:@"spoti_title"];
    [self.sharedDefaults setObject:(artist ?: @"") forKey:@"spoti_artist"];
    [self.sharedDefaults setDouble:duration forKey:@"spoti_duration"];
    [self.sharedDefaults setBool:playing forKey:@"spoti_is_playing"];
    [self.sharedDefaults synchronize];

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         CFSTR("com.spotify.mod.updateActivity"),
                                         NULL,
                                         NULL,
                                         YES);
}

- (void)updateLyricLine:(NSString *)currentLine {
    if (!self.sharedDefaults || !currentLine) return;

    [self.sharedDefaults setObject:currentLine forKey:@"spoti_current_lyric"];
    [self.sharedDefaults synchronize];

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         CFSTR("com.spotify.mod.updateLyric"),
                                         NULL,
                                         NULL,
                                         YES);
}

@end
