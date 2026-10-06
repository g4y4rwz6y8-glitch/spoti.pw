#import <UIKit/UIKit.h>

@interface SGSingSliderView : UIView
@property (nonatomic, copy) void (^onVocalLevelChanged)(float level);
@property (nonatomic, copy) void (^onSpatialToggleTapped)(BOOL isEnabled);
- (void)collapse;
@end
