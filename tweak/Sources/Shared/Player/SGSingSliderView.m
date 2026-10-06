#import "SGSingSliderView.h"

@interface SGSingSliderView ()
@property (nonatomic, strong) UIVisualEffectView *pillBackground;
@property (nonatomic, strong) UIView *fillTrackView;
@property (nonatomic, strong) UIButton *micButton;
@property (nonatomic, strong) UIButton *spatialButton;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, assign) float currentLevel; // 0.0 to 2.0
@end

@implementation SGSingSliderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _isExpanded = NO;
        _currentLevel = 1.0f; // Normal 100%
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.clipsToBounds = NO;

    // Frosted Glass Pill
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    _pillBackground = [[UIVisualEffectView alloc] initWithEffect:blur];
    _pillBackground.layer.cornerRadius = 22.0f;
    _pillBackground.layer.cornerCurve = kCACornerCurveContinuous;
    _pillBackground.clipsToBounds = YES;
    _pillBackground.hidden = YES;
    _pillBackground.alpha = 0.0f;
    [self addSubview:_pillBackground];

    // White Fill Progress Track
    _fillTrackView = [[UIView alloc] init];
    _fillTrackView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    [_pillBackground.contentView addSubview:_fillTrackView];

    // Microphone Circle Button
    _micButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImageConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightSemibold];
    UIImage *micImg = [UIImage systemImageNamed:@"mic.fill" withConfiguration:config];
    [_micButton setImage:micImg forState:UIControlStateNormal];
    _micButton.tintColor = [UIColor whiteColor];
    _micButton.backgroundColor = [UIColor colorWithWhite:0.18 alpha:0.75];
    _micButton.layer.cornerRadius = 22.0f;
    _micButton.layer.cornerCurve = kCACornerCurveContinuous;
    [_micButton addTarget:self action:@selector(toggleExpanded) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_micButton];

    // Spatial Voice Icon Button (beside the pill)
    _spatialButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *spatialImg = [UIImage systemImageNamed:@"person.wave.2.fill" withConfiguration:config];
    [_spatialButton setImage:spatialImg forState:UIControlStateNormal];
    _spatialButton.tintColor = [UIColor whiteColor];
    _spatialButton.backgroundColor = [UIColor colorWithWhite:0.18 alpha:0.75];
    _spatialButton.layer.cornerRadius = 16.0f;
    _spatialButton.hidden = YES;
    _spatialButton.alpha = 0.0f;
    [_spatialButton addTarget:self action:@selector(toggleSpatialVoice) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_spatialButton];

    // Pan Gesture for vertical dragging on the pill
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [_pillBackground addGestureRecognizer:pan];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _micButton.frame = CGRectMake(self.bounds.size.width - 44, self.bounds.size.height - 44, 44, 44);

    if (_isExpanded) {
        _pillBackground.frame = CGRectMake(self.bounds.size.width - 44, self.bounds.size.height - 150, 44, 150);
        _spatialButton.frame = CGRectMake(self.bounds.size.width - 86, self.bounds.size.height - 100, 32, 32);

        // Update fill track height based on level (0.0 to 2.0, mapped to height)
        float normalized = _currentLevel / 2.0f; // 0.5 is normal 100%
        float fillHeight = 150.0f * normalized;
        _fillTrackView.frame = CGRectMake(0, 150.0f - fillHeight, 44, fillHeight);
    }
}

- (void)toggleExpanded {
    _isExpanded = !_isExpanded;
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.82 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (self.isExpanded) {
            self.pillBackground.hidden = NO;
            self.pillBackground.alpha = 1.0f;
            self.spatialButton.hidden = NO;
            self.spatialButton.alpha = 1.0f;
            self.micButton.backgroundColor = [UIColor clearColor];
        } else {
            self.pillBackground.alpha = 0.0f;
            self.spatialButton.alpha = 0.0f;
            self.micButton.backgroundColor = [UIColor colorWithWhite:0.18 alpha:0.75];
        }
        [self setNeedsLayout];
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (!self.isExpanded) {
            self.pillBackground.hidden = YES;
            self.spatialButton.hidden = YES;
        }
    }];
}

- (void)collapse {
    if (_isExpanded) [self toggleExpanded];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint loc = [pan locationInView:_pillBackground];
    float height = _pillBackground.bounds.size.height;
    float ratio = 1.0f - (loc.y / height); // 0.0 bottom, 1.0 top
    ratio = fminf(fmaxf(ratio, 0.0f), 1.0f);

    _currentLevel = ratio * 2.0f; // 0.0 = full karaoke, 1.0 = normal, 2.0 = acapella
    [self setNeedsLayout];

    if (self.onVocalLevelChanged) {
        self.onVocalLevelChanged(_currentLevel);
    }
}

- (void)toggleSpatialVoice {
    static BOOL spatialOn = NO;
    spatialOn = !spatialOn;
    _spatialButton.tintColor = spatialOn ? [UIColor colorWithRed:0.98 green:0.25 blue:0.38 alpha:1.0] : [UIColor whiteColor];
    if (self.onSpatialToggleTapped) {
        self.onSpatialToggleTapped(spatialOn);
    }
}

@end
