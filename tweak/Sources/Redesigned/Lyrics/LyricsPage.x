// The redesign's full screen lyrics page, on glass over the redesigned player, which shows through it:
// the lyrics card under the player reads as having grown to the screen. A copy of
// Native/Lyrics/LyricsPage.x without its switch.
//
// Page (trees/lyrics.txt): a page of its own, presented over the player by a
// _UIOverFullscreenPresentationController, which is why the card's glass stops at the card's edge.
// Tome_PageTemplateImpl paints the template view #121212 and FullscreenView paints itself the
// album colour on top, both opaque; clearing them lets the player's blurred artwork through.
//
// The album colour is the stubborn one: it arrives per track, after the page has laid out, and it
// comes back through a path SGRRepaint.x never sees, so a sweep at layout time loses the race.
// FullscreenView is asked not to keep it at all instead. The pane goes inside FullscreenView, in
// front of whatever that view still fills itself with, rather than behind the whole page.
// The redesign's full screen lyrics page, on glass over the redesigned player, which shows through it:
#import "Core/SGCore.h"
#import "Redesigned/Kit/SGRRepaint.h"
#import "Shared/Player/SGSingSliderView.h"
#import "Shared/AudioEffects/SGSingAudioProcessor.h"

static char kPageGlassKey;

static UIView *clearAncestors(UIView *view) {
    UIView *top = view;
    for (UIView *v = view; v && ![v isKindOfClass:UIWindow.class]
            && ![NSStringFromClass(v.class) hasPrefix:@"UITransition"]; v = v.superview) {
        v.layer.backgroundColor = NULL;
        top = v;
    }
    return top;
}

%hook _TtC32Lyrics_FullscreenElementPageImpl14FullscreenView

- (void)setBackgroundColor:(UIColor *)color {
    static dispatch_once_t once;
    dispatch_once(&once, ^{ SGLog(@"lyrics page paints itself %@ through UIView", color); });
    %orig(nil);
}

- (void)layoutSubviews {
    %orig;
    UIView *page = (UIView *)self;
    if (page.bounds.size.height < 200) return;

    page.layer.backgroundColor = NULL;
    sgr_lyricsPageRoot = clearAncestors(page);

    UIVisualEffectView *glass = SGGlassFor(page, &kPageGlassKey);
    if (glass.overrideUserInterfaceStyle != UIUserInterfaceStyleDark) glass.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    glass.frame = page.bounds;
    glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    SGShapeGlass(glass, 0, NO);

    // --- MOUNT THE SING MIC PILL ON THE LYRICS GLASS ---
    static SGSingSliderView *singSlider = nil;
    if (!singSlider) {
        singSlider = [[SGSingSliderView alloc] initWithFrame:CGRectMake(page.bounds.size.width - 56, page.bounds.size.height - 180, 46, 154)];
        singSlider.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;

        singSlider.onVocalLevelChanged = ^(float level) {
            [SGSingAudioProcessor sharedInstance].isEnabled = YES;
            [SGSingAudioProcessor sharedInstance].vocalLevel = level;
        };

        singSlider.onSpatialToggleTapped = ^(BOOL isEnabled) {
            [SGSingAudioProcessor sharedInstance].spatialVoiceEnabled = isEnabled;
        };

        [page addSubview:singSlider];
    }
}

%end

%ctor {
    if (!SGRedesignedUI()) return;
    %init;
    SGRequireClasses(@[@"_TtC32Lyrics_FullscreenElementPageImpl14FullscreenView"]);
}
