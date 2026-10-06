#import "SGSingSliderView.h"

@interface SGSingSliderView ()
@property (nonatomic, strong) UIVisualEffectView *pillBackground;
@property (nonatomic, strong) UIView *fillTrackView;
@property (nonatomic, strong) UIButton *micButton;
@property (nonatomic, strong) UIImageView *micIconInsidePill;
@property (nonatomic, strong) UIButton *spatialButton;
@property (nonatomic, strong) UISelectionFeedbackGenerator *hapticScrubber;
@property (nonatomic, strong) UIImpactFeedbackGenerator *hapticNotch;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, assign) float currentLevel; // 0.0 (Karaoke) to 1.0 (Normal) to 2.0 (Acapella)
@property (nonatomic, assign) BOOL passedNotch;
@end

@implementation SGSingSliderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _isExpanded = NO;
        _currentLevel = 1.0f; // Default 100% normal
        _hapticScrubber = [[UISelectionFeedbackGenerator alloc] init];
        _hapticNotch = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [self setupAppleMusicUI];
    }
    return self;
}

- (void)setupAppleMusicUI {
    self.clipsToBounds = NO;

    // 1. Frosted Liquid Glass Pill
    UIVisualEffect *glassEffect;
    if (@available(iOS 26.0, *)) {
        // Native Liquid Glass material if available
        Class glassClass = NSClassFromString(@"UIGlassEffect");
        glassEffect = glassClass ? [glassClass performSelector:@selector(effectWithStyle:) withObject:@(0)] : [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    } else {
        glassEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    }

    _pillBackground = [[UIVisualEffectView alloc] initWithEffect:glassEffect];
    _pillBackground.layer.cornerRadius = 23.0f;
    _pillBackground.layer.cornerCurve = kCACornerCurveContinuous;
    _pillBackground.layer.borderWidth = 0.5f;
    _pillBackground.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
    _pillBackground.clipsToBounds = YES;
    _pillBackground.hidden = YES;
    _pillBackground.alpha = 0.0f;
    [self addSubview:_pillBackground];

    // 2. Pure White Level Fill Track
    _fillTrackView = [[UIView alloc] init];
    _fillTrackView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.96];
    _fillTrackView.layer.cornerRadius = 23.0f;
    _fillTrackView.layer.cornerCurve = kCACornerCurveContinuous;
    [_pillBackground.contentView addSubview:_fillTrackView];

    // 3. Static Icon Inside the Pill Bottom
    UIImageConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:19 weight:UIImageSymbolWeightSemibold];
    UIImage *micImg = [UIImage systemImageNamed:@"mic.fill" withConfiguration:config];
    
    _micIconInsidePill = [[UIImageView alloc] initWithImage:micImg];
    _micIconInsidePill.tintColor = [UIColor colorWithWhite:0.12 alpha:1.0]; // Dark icon when covered by white fill
    _micIconInsidePill.contentMode = UIViewContentModeCenter;
    [_pillBackground.contentView addSubview:_micIconInsidePill];

    // 4. Circular Microphone Toggle Button (Collapsed State)
    _micButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_micButton setImage:micImg forState:UIControlStateNormal];
    _micButton.tintColor = [UIColor whiteColor];
    _micButton.backgroundColor = [UIColor colorWithWhite:0.18 alpha:0.75];
    _micButton.layer.cornerRadius = 23.0f;
    _micButton.layer.cornerCurve = kCACornerCurveContinuous;
    _micButton.layer.borderWidth = 0.5f;
    _micButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.15].CGColor;
    [_micButton addTarget:self action:@selector(toggleExpanded) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_micButton];

    // 5. Duet / Spatial Voice Button (Left of Pill)
    _spatialButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *spatialImg = [UIImage systemImageNamed:@"person.wave.2.fill" withConfiguration:config];
    [_spatialButton setImage:spatialImg forState:UIControlStateNormal];
    _spatialButton.tintColor = [UIColor whiteColor];
    _spatialButton.backgroundColor = [UIColor colorWithWhite:0.18 alpha:0.75];
    _spatialButton.layer.cornerRadius = 17.0f;
    _spatialButton.layer.cornerCurve = kCACornerCurveContinuous;
    _spatialButton.layer.borderWidth = 0.5f;
    _spatialButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.15].CGColor;
    _spatialButton.hidden = YES;
    _spatialButton.alpha = 0.0f;
    [_spatialButton addTarget:self action:@selector(toggleSpatialVoice) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_spatialButton];

    // Vertical Drag Pan Gesture
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [_pillBackground addGestureRecognizer:pan];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat rightX = self.bounds.size.width - 60.0f;
    CGFloat bottomY = self.bounds.size.height - 60.0f;

    _micButton.frame = CGRectMake(rightX, bottomY, 44.0f, 44.0f);

    if (_isExpanded) {
        _pillBackground.frame = CGRectMake(rightX, bottomY - 110.0f, 44.0f, 154.0f);
        _spatialButton.frame = CGRectMake(rightX - 46.0f, bottomY - 55.0f, 36.0f, 36.0f);
        _micIconInsidePill.frame = CGRectMake(0, 154.0f - 44.0f, 44.0f, 44.0f);

        // Map Level (0.0 to 2.0) to Fill Height
        float normalized = _currentLevel / 2.0f;
        float fillHeight = 154.0f * normalized;
        _fillTrackView.frame = CGRectMake(0, 154.0f - fillHeight, 46, fillHeight);

        // Dynamic Contrast Masking:
        // If fill covers the bottom mic area, mic turns dark; if fill drops below it, mic turns white
        if (fillHeight < 32.0f) {
            _micIconInsidePill.tintColor = [UIColor whiteColor];
        } else {
            _micIconInsidePill.tintColor = [UIColor colorWithWhite:0.12 alpha:1.0];
        }
    }
}

- (void)toggleExpanded {
    _isExpanded = !_isExpanded;
    [_hapticNotch impactOccurred];

    [UIView animateWithDuration:0.38 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (self.isExpanded) {
            self.pillBackground.hidden = NO;
            self.pillBackground.alpha = 1.0f;
            self.spatialButton.hidden = NO;
            self.spatialButton.alpha = 1.0f;
            self.micButton.alpha = 0.0f;
        } else {
            self.pillBackground.alpha = 0.0f;
            self.spatialButton.alpha = 0.0f;
            self.micButton.alpha = 1.0f;
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
    float ratio = 1.0f - (loc.y / height); // 0.0 (bottom) to 1.0 (top)
    ratio = fminf(fmaxf(ratio, 0.0f), 1.0f);

    _currentLevel = ratio * 2.0f; // 0.0 = full instrumental, 1.0 = normal, 2.0 = acapella

    // Haptic Notch Feedback at exactly 100% normal vocals (middle mark)
    if (fabsf(_currentLevel - 1.0f) < 0.05f) {
        if (!_passedNotch) {
            [_hapticNotch impactOccurred];
            _passedNotch = YES;
        }
    } else {
        _passedNotch = NO;
        [_hapticScrubber selectionChanged];
    }

    [self setNeedsLayout];

    if (self.onVocalLevelChanged) {
        self.onVocalLevelChanged(_currentLevel);
    }
}

- (void)toggleSpatialVoice {
    static BOOL spatialOn = NO;
    spatialOn = !spatialOn;
    [_hapticNotch impactOccurred];
    
    // Pink accent glow matching Apple Music & chroma.pw
    _spatialButton.tintColor = spatialOn ? [UIColor colorWithRed:0.98 green:0.22 blue:0.38 alpha:1.0] : [UIColor whiteColor];
    if (self.onSpatialToggleTapped) {
        self.onSpatialToggleTapped(spatialOn);
    }
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    // If the tap didn't land on the mic button or the pill slider, pass it through to the lyrics!
    return (hit == self) ? nil : hit;
}
@end
