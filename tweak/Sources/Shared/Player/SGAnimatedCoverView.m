#import "Shared/Player/SGAnimatedCoverView.h"

@interface SGAnimatedCoverView ()
@property (nonatomic, strong) AVQueuePlayer *player;
@property (nonatomic, strong) AVPlayerLooper *looper;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@end

@implementation SGAnimatedCoverView

+ (instancetype)coverViewWithFrame:(CGRect)frame {
    return [[self alloc] initWithFrame:frame];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0.0f;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.playerLayer) {
        self.playerLayer.frame = self.bounds;
    }
}

- (void)setupPlayerWithURL:(NSURL *)videoURL {
    if (!videoURL) return;

    [self.player pause];
    [self.playerLayer removeFromSuperlayer];

    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoURL];
    self.player = [AVQueuePlayer queuePlayerWithItems:@[playerItem]];
    self.player.muted = YES;

    self.looper = [AVPlayerLooper playerLooperWithPlayer:self.player templateItem:playerItem];

    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerLayer.frame = self.bounds;
    [self.layer addSublayer:self.playerLayer];

    [self.player play];

    [UIView animateWithDuration:0.45 animations:^{
        self.alpha = 1.0f;
    }];
}

- (void)loadAnimatedCoverForAlbum:(NSString *)album artist:(NSString *)artist {
    // Handled via SGAppleArtwork in AlbumHeader.x
}

- (void)pausePlayback {
    [self.player pause];
}

- (void)resumePlayback {
    [self.player play];
}

- (void)dealloc {
    [_player pause];
    _player = nil;
    _looper = nil;
}

@end
