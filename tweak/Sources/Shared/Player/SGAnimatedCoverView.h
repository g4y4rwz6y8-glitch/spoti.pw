#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SGAnimatedCoverView : UIView
@property (nonatomic, strong, readonly) AVPlayerLayer *playerLayer;
+ (instancetype)coverViewWithFrame:(CGRect)frame;
- (void)loadAnimatedCoverForAlbum:(NSString *)album artist:(NSString *)artist;
- (void)pausePlayback;
- (void)resumePlayback;
- (void)setupPlayerWithURL:(NSURL *)videoURL;
@end
