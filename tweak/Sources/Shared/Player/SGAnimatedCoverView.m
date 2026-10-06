#import "SGAnimatedCoverView.h"

static NSCache<NSString *, NSURL *> *coverVideoCache = nil;

@interface SGAnimatedCoverView ()
@property (nonatomic, strong) AVQueuePlayer *player;
@property (nonatomic, strong) AVPlayerLooper *looper;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) NSString *currentAlbumKey;
@end

@implementation SGAnimatedCoverView

+ (void)initialize {
    if (self == [SGAnimatedCoverView class]) {
        coverVideoCache = [[NSCache alloc] init];
        coverVideoCache.countLimit = 30; // Cache up to 30 animated albums in RAM
    }
}

+ (instancetype)coverViewWithFrame:(CGRect)frame {
    return [[self alloc] initWithFrame:frame];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0.0f; // Hidden until video is ready to prevent flashing
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.playerLayer) {
        self.playerLayer.frame = self.bounds;
    }
}

- (void)loadAnimatedCoverForAlbum:(NSString *)album artist:(NSString *)artist {
    if (!album || !artist) return;

    NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", artist.lowercaseString, album.lowercaseString];
    self.currentAlbumKey = cacheKey;

    // Check RAM Cache first
    NSURL *cachedURL = [coverVideoCache objectForKey:cacheKey];
    if (cachedURL) {
        [self setupPlayerWithURL:cachedURL];
        return;
    }

    // Query Apple Music Catalog Search API
    NSString *query = [NSString stringWithFormat:@"%@ %@", artist, album];
    NSString *encodedQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *searchURLString = [NSString stringWithFormat:@"https://itunes.apple.com/search?term=%@&entity=album&limit=1", encodedQuery];

    NSURL *searchURL = [NSURL URLWithString:searchURLString];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:searchURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data || error) return;

        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSArray *results = json[@"results"];
        if (!results || results.count == 0) return;

        NSDictionary *firstResult = results.firstObject;
        NSNumber *collectionId = firstResult[@"collectionId"];
        if (!collectionId) return;

        // Fetch Apple Music Storefront album details to retrieve editorial video stream
        [self fetchMotionVideoForCollectionId:collectionId cacheKey:cacheKey];
    }];
    [task resume];
}

- (void)fetchMotionVideoForCollectionId:(NSNumber *)collectionId cacheKey:(NSString *)cacheKey {
    NSString *lookupURLString = [NSString stringWithFormat:@"https://itunes.apple.com/lookup?id=%@&extend=editorialArtwork", collectionId];
    NSURL *lookupURL = [NSURL URLWithString:lookupURLString];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:lookupURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data || error) return;

        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray *results = json[@"results"];
        if (!results || results.count == 0) return;

        NSDictionary *albumData = results.firstObject;
        NSDictionary *editorial = albumData[@"editorialArtwork"];
        
        // Extract motion video URL (motionSquare or motionTall)
        NSString *videoUrlString = editorial[@"motionSquare"][@"video"] ?: editorial[@"motionTall"][@"video"];
        if (!videoUrlString) return;

        NSURL *videoURL = [NSURL URLWithString:videoUrlString];
        if (videoURL) {
            [coverVideoCache setObject:videoURL forKey:cacheKey];

            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.currentAlbumKey isEqualToString:cacheKey]) {
                    [self setupPlayerWithURL:videoURL];
                }
            });
        }
    }];
    [task resume];
}

- (void)setupPlayerWithURL:(NSURL *)videoURL {
    // Tear down existing player if any
    [self.player pause];
    [self.playerLayer removeFromSuperlayer];

    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoURL];
    self.player = [AVQueuePlayer queuePlayerWithItems:@[playerItem]];
    self.player.muted = YES; // Always silent

    // Seamless zero-gap hardware looping
    self.looper = [AVPlayerLooper playerLooperWithPlayer:self.player templateItem:playerItem];

    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerLayer.frame = self.bounds;
    [self.layer addSublayer:self.playerLayer];

    [self.player play];

    // Smooth Apple-style crossfade from static image into motion
    [UIView animateWithDuration:0.45 animations:^{
        self.alpha = 1.0f;
    }];
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
