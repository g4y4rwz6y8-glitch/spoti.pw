#import "Shared/Player/SGSingSliderView.h"

@interface SGSingSliderView ()
@property (nonatomic, strong) UIVisualEffectView *pillBackground;
@property (nonatomic, strong) UIView *fillTrackView;
@property (nonatomic, strong) UIButton *micButton;
@property (nonatomic, strong) UIImageView *micIconInsidePill;
@property (nonatomic, strong) UIButton *spatialButton;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, assign) float currentLevel;
@end

@implementation SGSingSliderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _isExpanded = NO;
        _currentLevel = 1.0f;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.clipsToBounds = NO;

    // 1. Frosted Glass Slider Pill (Hidden by default until tapped!)
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    _pillBackground = [[UIVisualEffectView alloc] initWithEffect:blur];
    _pillBackground.layer.cornerRadius = 22.0f;
    _pillBackground.layer.cornerCurve = kCACornerCurveContinuous;
    _pillBackground.layer.borderWidth = 0.5f;
    _pillBackground.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
    _pillBackground.clipsToBounds = YES;
    _pillBackground.hidden = YES;
    _pillBackground.alpha = 0.0f;
    [self addSubview:_pillBackground];

    // 2. White Fill Track
    _fillTrackView = [[UIView alloc] init];
    _fillTrackView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.95];
    _fillTrackView.layer.cornerRadius = 22.0f;
    _fillTrackView.layer.cornerCurve = kCACornerCurveContinuous;
    [_pillBackground.contentView addSubview:_fillTrackView];

    // 3. Static Icon at the bottom of the pill
    UIImageConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightSemibold];
    UIImage *micImg = [UIImage systemImageNamed:@"mic.fill" withConfiguration:config];

    _micIconInsidePill = [[UIImageView alloc] initWithImage:micImg];
    _micIconInsidePill.tintColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    _micIconInsidePill.contentMode = UIViewContentModeCenter;
    [_pillBackground.contentView addSubview:_micIconInsidePill];

    // 4. Compact Mic Button (Collapsed state by default - neat 44x44 circle)
    _micButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_micButton setImage:micImg forState:UIControlStateNormal];
    _micButton.tintColor = [UIColor whiteColor];
    _micButton.backgroundColor = [UIColor colorWithWhite:0.18 alpha:0.8];
    _micButton.layer.cornerRadius = 22.0f;
    _micButton.layer.cornerCurve = kCACornerCurveContinuous;
    _micButton.layer.borderWidth = 0.5f;
    _micButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
    [_micButton addTarget:self action:@selector(toggleExpanded) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_micButton];

    // 5. Spatial Voice Button (Tucked to the left of the pill, hidden when collapsed)
    _spatialButton = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *spatialImg = [UIImage systemImageNamed:@"person.wave.2.fill" withConfiguration:config];
    [_spatialButton setImage:spatialImg forState:UIControlStateNormal];
    _spatialButton.tintColor = [UIColor whiteColor];
    _spatialButton.backgroundColor = [UIColor colorWithWhite:0.18 alpha:0.8];
    _spatialButton.layer.cornerRadius = 18.0f;
    _spatialButton.layer.cornerCurve = kCACornerCurveContinuous;
    _spatialButton.hidden = YES;
    _spatialButton.alpha = 0.0f;
    [_spatialButton addTarget:self action:@selector(toggleSpatialVoice) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_spatialButton];

    // Drag gesture for the slider
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [_pillBackground addGestureRecognizer:pan];
    
    // Tap on pill collapses it
    UITapGestureRecognizer *tapCollapse = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleExpanded)];
    [_pillBackground addGestureRecognizer:tapCollapse];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Padded 16pt from the right edge so it NEVER gets cut off
    CGFloat rightX = self.bounds.size.width - 50.0f;
    CGFloat bottomY = self.bounds.size.height - 50.0f;

    _micButton.frame = CGRectMake(rightX, bottomY, 44.0f, 44.0f);

    if (_isExpanded) {
        _pillBackground.frame = CGRectMake(rightX, bottomY - 120.0f, 44.0f, 164.0f);
        _spatialButton.frame = CGRectMake(rightX - 46.0f, bottomY - 60.0f, 36.0f, 36.0f);
        _micIconInsidePill.frame = CGRectMake(0, 164.0f - 44.0f, 44.0f, 44.0f);

        float normalized = _currentLevel / 2.0f;
        float fillHeight = 164.0f * normalized;
        _fillTrackView.frame = CGRectMake(0, 164.0f - fillHeight, 44.0f, fillHeight);

        _micIconInsidePill.tintColor = (fillHeight < 30.0f) ? [UIColor whiteColor] : [UIColor colorWithWhite:0.15 alpha:1.0];
    }
}

- (void)toggleExpanded {
    _isExpanded = !_isExpanded;
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
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

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint loc = [pan locationInView:_pillBackground];
    float ratio = 1.0f - (loc.y / _pillBackground.bounds.size.height);
    ratio = fminf(fmaxf(ratio, 0.0f), 1.0f);
    _currentLevel = ratio * 2.0f;

    [self setNeedsLayout];
    if (self.onVocalLevelChanged) {
        self.onVocalLevelChanged(_currentLevel);
    }
}

- (void)toggleSpatialVoice {
    static BOOL spatialOn = NO;
    spatialOn = !spatialOn;
    _spatialButton.tintColor = spatialOn ? [UIColor colorWithRed:0.98 green:0.22 blue:0.38 alpha:1.0] : [UIColor whiteColor];
    if (self.onSpatialToggleTapped) {
        self.onSpatialToggleTapped(spatialOn);
    }
}

@end
