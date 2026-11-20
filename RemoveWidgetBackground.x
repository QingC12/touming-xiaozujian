#import <UIKit/UIKit.h>

#import <HBLog.h>

static BOOL kIsEnabled = YES;
static BOOL kIsEnabledForSystemWidgets = YES;
static BOOL kIsEnabledForMaterialView = YES;

static BOOL kForceDarkMode = YES;

static CGFloat kMaxWidgetWidth = 150;
static CGFloat kMaxWidgetHeight = 150;
static NSSet<NSString *> *kWidgetBundleIdentifiers = nil;

static BOOL gIsWidgetRenderer = NO;
// iOS 17 起每个小组件通常由独立的 WidgetRenderer 进程渲染。
// 区分「专用渲染进程」与 Default/CarPlay 共用渲染进程，用于窗口标记丢失时兜底。
static BOOL gIsDedicatedWidgetRenderer = NO;

static void ReloadPrefs() {
    static NSUserDefaults *prefs = nil;
    if (gIsWidgetRenderer && !prefs) {
        prefs = [[NSUserDefaults alloc] initWithSuiteName:@"/var/mobile/Library/Preferences/com.82flex.removewidgetbgprefs.plist"];
    }
    if (!prefs) {
        prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.82flex.removewidgetbgprefs"];
    }

    NSDictionary *settings = [prefs dictionaryRepresentation];

    if (settings[@"IsEnabled"]) {
        kIsEnabled = [settings[@"IsEnabled"] boolValue];
    } else {
        kIsEnabled = YES;
    }

    if (settings[@"IsSystemWidgetsEnabled"]) {
        kIsEnabledForSystemWidgets = [settings[@"IsSystemWidgetsEnabled"] boolValue];
    } else {
        kIsEnabledForSystemWidgets = YES;
    }

    if (settings[@"IsMaterialViewEnabled"]) {
        kIsEnabledForMaterialView = [settings[@"IsMaterialViewEnabled"] boolValue];
    } else {
        kIsEnabledForMaterialView = YES;
    }

    if (settings[@"ForceDarkMode"]) {
        kForceDarkMode = [settings[@"ForceDarkMode"] boolValue];
    } else {
        kForceDarkMode = YES;
    }

    if (settings[@"MaxWidgetWidth"]) {
        kMaxWidgetWidth = [settings[@"MaxWidgetWidth"] floatValue];
    } else {
        kMaxWidgetWidth = 150;
    }

    if (settings[@"MaxWidgetHeight"]) {
        kMaxWidgetHeight = [settings[@"MaxWidgetHeight"] floatValue];
    } else {
        kMaxWidgetHeight = 150;
    }

    if (settings[@"WidgetBundleIdentifiers"]) {
        kWidgetBundleIdentifiers = [NSSet setWithArray:settings[@"WidgetBundleIdentifiers"]];
    } else {
        kWidgetBundleIdentifiers = [NSSet setWithArray:@[
            @"com.growing.topwidgetsplus.Widget", // Top Widgets
            @"dk.simonbs.Scriptable.ScriptableWidget", // Scriptable
            @"wiki.qaq.trapp.LaunchPad", // 巨魔录音机
        ]];
    }

    if (kIsEnabledForSystemWidgets) {
        NSArray<NSString *> *kSystemWidgetBundleIdentifiers = @[
            @"com.apple.mobiletimer.WorldClockWidget", // 时钟
            @"com.apple.mobilecal.CalendarWidgetExtension", // 日历
            @"com.apple.mobilemail.MailWidgetExtension", // 邮件
            @"com.apple.ScreenTimeWidgetApplication.ScreenTimeWidgetExtension", // 使用时间
            @"com.apple.reminders.WidgetExtension", // 提醒事项
            @"com.apple.weather.widget", // 天气
            @"com.apple.Fitness.FitnessWidget", // 健身
            @"com.apple.Passbook.PassbookWidgets", // 钱包
            @"com.apple.Health.Sleep.SleepWidgetExtension", // 睡眠
            @"com.apple.tips.TipsSwift", // 提示
            @"com.apple.Music.MusicWidgets", // 音乐
            @"com.apple.gamecenter.widgets.extension", // Game Center
            @"com.apple.tv.TVWidgetExtension", // TV
            @"com.apple.news.widget", // Apple News
        ];
        kWidgetBundleIdentifiers = [kWidgetBundleIdentifiers setByAddingObjectsFromArray:kSystemWidgetBundleIdentifiers];
    }

    HBLogDebug(@"ReloadPrefs: isEnabled=%d, isEnabledForSystemWidgets=%d, isEnabledForMaterialView=%d, "
               @"forceDarkMode=%d, maxWidgetWidth=%.1f, maxWidgetHeight=%.1f, widgetBundleIdentifiers=%@",
               kIsEnabled, kIsEnabledForSystemWidgets, kIsEnabledForMaterialView, kForceDarkMode, kMaxWidgetWidth,
               kMaxWidgetHeight, kWidgetBundleIdentifiers);
}

@interface CHSWidget : NSObject
@property (nonatomic, copy, readonly) NSString *extensionBundleIdentifier;
@end

@interface CHUISWidgetScene : UIWindowScene
@property (nonatomic, copy, readonly) CHSWidget *widget;
@end

@interface CHUISAvocadoWindowScene : UIWindowScene
@property (nonatomic, copy, readonly) CHSWidget *widget; 
@end

@interface UIWindow (RWB)
@property (nonatomic, strong) NSNumber *rwb_shouldHideBackground;
@end

@interface RBLayer : CALayer
@end

@interface RBDisplayList : NSObject
- (id)xmlDescription;
@end

@interface SBHWidgetViewController : UIViewController
@end

@interface CHUISWidgetHostViewController : UIViewController
@property (nonatomic, copy) CHSWidget *widget; 
@end

@interface SBHWidgetStackViewController : UIViewController
@end

@interface WGWidgetListItemViewController : UIViewController
@end

@interface SBIcon : NSObject
@end

@interface SBIconView : NSObject
@property (nonatomic, strong) SBIcon *icon;
@end

@interface CHUISAvocadoHostViewController : UIViewController
@property (nonatomic, copy) CHSWidget *widget; 
@end

%group RWBSpringBoard

%hook CHUISAvocadoHostViewController

/* iOS 15 */
- (void)_updateBackgroundMaterialAndColor {
    CHSWidget *widget = self.widget;
    if ([widget isKindOfClass:%c(CHSWidget)] &&
        widget.extensionBundleIdentifier &&
        [kWidgetBundleIdentifiers containsObject:widget.extensionBundleIdentifier])
    {
        return;
    }
    %orig;
}

/* iOS 15 */
- (id)screenshotManager {
    CHSWidget *widget = self.widget;
    if ([widget isKindOfClass:%c(CHSWidget)] &&
        widget.extensionBundleIdentifier &&
        [kWidgetBundleIdentifiers containsObject:widget.extensionBundleIdentifier])
    {
        return nil;
    }
    return %orig;
}

%end

%hook SBHWidgetViewController

- (void)viewWillAppear:(BOOL)arg1 {
    %orig;
    UIView *firstChild = nil;
    firstChild = self.view.subviews.firstObject;
    if ([firstChild isKindOfClass:%c(UIVisualEffectView)]) {
        [firstChild setAlpha:0];
    }
}

%end

%hook CHUISWidgetHostViewController

- (unsigned long long)colorScheme {
    if (kForceDarkMode) {
        return 2;
    }
    return %orig;
}

- (void)_updateBackgroundMaterialAndColor {
    CHSWidget *widget = self.widget;
    if ([widget isKindOfClass:%c(CHSWidget)] &&
        widget.extensionBundleIdentifier &&
        [kWidgetBundleIdentifiers containsObject:widget.extensionBundleIdentifier])
    {
        return;
    }
    %orig;
}

- (void)_updatePersistedSnapshotContent {
    CHSWidget *widget = self.widget;
    if ([widget isKindOfClass:%c(CHSWidget)] &&
        widget.extensionBundleIdentifier &&
        [kWidgetBundleIdentifiers containsObject:widget.extensionBundleIdentifier])
    {
        return;
    }
    %orig;
}

- (void)_updatePersistedSnapshotContentIfNecessary {
    CHSWidget *widget = self.widget;
    if ([widget isKindOfClass:%c(CHSWidget)] &&
        widget.extensionBundleIdentifier &&
        [kWidgetBundleIdentifiers containsObject:widget.extensionBundleIdentifier])
    {
        return;
    }
    %orig;
}

/* iOS 16.0 to 16.2 */
- (id)_snapshotImageFromURL:(id)arg1 {
    CHSWidget *widget = self.widget;
    if ([widget isKindOfClass:%c(CHSWidget)] &&
        widget.extensionBundleIdentifier &&
        [kWidgetBundleIdentifiers containsObject:widget.extensionBundleIdentifier])
    {
        return nil;
    }
    return %orig;
}

%end

%hook SBIconView

- (double)iconLabelAlpha {
    if (self.icon && [self.icon isKindOfClass:%c(SBWidgetIcon)]) {
        return 0;
    }
    return %orig;
}

- (double)effectiveIconLabelAlpha {
    if (self.icon && [self.icon isKindOfClass:%c(SBWidgetIcon)]) {
        return 0;
    }
    return %orig;
}

%end

%hook SBHWidgetStackViewController

- (void)viewWillAppear:(BOOL)arg1 {
    %orig;
    if (kIsEnabledForMaterialView) {
        UIView *firstChild = nil;
        firstChild = self.view.subviews.firstObject;
        firstChild = firstChild.subviews.firstObject;
        if ([firstChild isKindOfClass:%c(MTMaterialView)]) {
            [firstChild setAlpha:0];
        }
    }
}

%end

%hook WGWidgetListItemViewController

- (void)viewWillAppear:(BOOL)arg1 {
    %orig;
    if (kIsEnabledForMaterialView) {
        UIView *firstChild = self.view.subviews.firstObject;
        if ([firstChild isKindOfClass:%c(MTMaterialView)]) {
            [firstChild setAlpha:0];
        }
    }
}

%end

%end

%group RWB

%hook UIWindow

%property (nonatomic, strong) NSNumber *rwb_shouldHideBackground;

- (UIWindow *)initWithWindowScene:(UIWindowScene *)scene {
    if ([scene isKindOfClass:%c(CHUISAvocadoWindowScene)]) {
        CHUISAvocadoWindowScene *avocadoScene = (CHUISAvocadoWindowScene *)scene;
        HBLogDebug(@"initWithWindowScene: %@", avocadoScene.widget.extensionBundleIdentifier);
        if (avocadoScene.widget.extensionBundleIdentifier && [kWidgetBundleIdentifiers containsObject:avocadoScene.widget.extensionBundleIdentifier]) {
            self.rwb_shouldHideBackground = @YES;
        }
    }
    else if ([scene isKindOfClass:%c(CHUISWidgetScene)]) {
        CHUISWidgetScene *widgetScene = (CHUISWidgetScene *)scene;
        HBLogDebug(@"initWithWindowScene: %@", widgetScene.widget.extensionBundleIdentifier);
        if (widgetScene.widget.extensionBundleIdentifier && [kWidgetBundleIdentifiers containsObject:widgetScene.widget.extensionBundleIdentifier]) {
            self.rwb_shouldHideBackground = @YES;
        }
    }
    UIWindow *window = %orig;
    if (window) {
        [window setOverrideUserInterfaceStyle:UIUserInterfaceStyleDark];
    }
    return window;
}

%end

%hook CHUISWidgetScene

- (unsigned long long)colorScheme {
    if (kForceDarkMode) {
        return 2;
    }
    return %orig;
}

%end

%hook CHSMutableScreenshotPresentationAttributes

- (long long)colorScheme {
    if (kForceDarkMode) {
        return 2;
    }
    return %orig;
}

%end

%hook CHSScreenshotPresentationAttributes

- (long long)colorScheme {
    if (kForceDarkMode) {
        return 2;
    }
    return %orig;
}

%end

%hook UIView

- (void)layoutSubviews {
    %orig;

    if (![NSStringFromClass([self class]) containsString:@"UIHostingView"]) {
        [self setBackgroundColor:UIColor.clearColor];
    }
}

%end

%hook RBLayer

- (void)display {
    UIView *view = (UIView *)self.delegate;
    BOOL isTargetLayer = [view isKindOfClass:[UIView class]] &&
                         view.window.rwb_shouldHideBackground.boolValue;

    // snapshot 刷新/离屏渲染时 view.window 可能暂时为 nil，窗口标记会丢失，
    // 该次渲染就会漏裁背景（表现为背景闪现约一秒，下次刷新才消失）。
    // 专用 WidgetRenderer 进程一次只服务一个小组件，用进程身份兜底。
    if (!isTargetLayer && gIsDedicatedWidgetRenderer && [view isKindOfClass:[UIView class]]) {
        isTargetLayer = YES;
    }

    if (!isTargetLayer) {
        %orig;
        return;
    }

    NSMutableDictionary *threadDict = [NSThread currentThread].threadDictionary;

    // display 可能嵌套：内层结束时若清空计数器，外层后续大矩形的跳过序号
    // 会被重置而错位，背景随之被绘制。用深度计数保证只有最外层才清理。
    NSInteger depth = [threadDict[@"rwb_displayDepth"] integerValue];
    threadDict[@"rwb_displayDepth"] = @(depth + 1);
    if (depth == 0) {
        threadDict[@"rwb_didSkipFirstN"] = @(0);
        threadDict[@"rwb_didSkipFirst"] = nil;
    }

    threadDict[@"rwb_shouldHideBackground"] = @YES;
    if (@available(iOS 17, *)) {
        if (self.opaque)
            self.opaque = NO;
    }

    %orig;

    threadDict[@"rwb_shouldHideBackground"] = nil;
    NSInteger newDepth = [threadDict[@"rwb_displayDepth"] integerValue];
    if (newDepth <= 1) {
        threadDict[@"rwb_displayDepth"] = nil;
        if (@available(iOS 17, *)) {
            threadDict[@"rwb_didSkipFirstN"] = nil;
        } else {
            threadDict[@"rwb_didSkipFirst"] = nil;
        }
    } else {
        threadDict[@"rwb_displayDepth"] = @(newDepth - 1);
    }
}

%end

%end

%group RWB_15

%hook RBShape

- (void)setRect:(CGRect)arg1 {
    if ([NSThread currentThread].threadDictionary[@"rwb_shouldHideBackground"]) {
        if (arg1.size.width > kMaxWidgetWidth && arg1.size.height > kMaxWidgetHeight) {
            %orig(CGRectZero);
            return;
        }
    }
    %orig;
}

%end

%hook UISCurrentUserInterfaceStyleValue

- (long long)userInterfaceStyle {
    if (kForceDarkMode) {
        return 2;
    }
    return %orig;
}

%end

%end

%group RWB_16

%hook RBShape

- (void)setRect:(CGRect)arg1 {
    NSMutableDictionary *threadDict = [NSThread currentThread].threadDictionary;
    if (threadDict[@"rwb_shouldHideBackground"]) {
        if (arg1.size.width > kMaxWidgetWidth && arg1.size.height > kMaxWidgetHeight) {
            if ([threadDict[@"rwb_didSkipFirst"] boolValue]) {
                %orig(CGRectZero);
                return;
            }
            threadDict[@"rwb_didSkipFirst"] = @YES;
        }
    }
    %orig;
}

%end

%end

%group RWB_17

%hook RBShape

- (void)setRect:(CGRect)arg1 {
    NSMutableDictionary *threadDict = [NSThread currentThread].threadDictionary;
    if (threadDict[@"rwb_shouldHideBackground"]) {
        if (arg1.size.width > kMaxWidgetWidth && arg1.size.height > kMaxWidgetHeight) {
            // 原实现的裁剪条件为「序号 == 1 或 序号 > 1」，序号为 2 的大矩形被漏过。
            // 一旦背景落在该矩形上就会闪现，直到下一次 snapshot 刷新才恢复。
            // 改为从第 2 个起一律裁剪，与 iOS 16 的语义保持一致。
            NSInteger index = [threadDict[@"rwb_didSkipFirstN"] integerValue];
            threadDict[@"rwb_didSkipFirstN"] = @(index + 1);
            if (index >= 1) {
                %orig(CGRectZero);
                return;
            }
        }
    }
    %orig;
}

%end

%end

%ctor {
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    gIsWidgetRenderer = [bundleIdentifier hasPrefix:@"com.apple.chrono.WidgetRenderer-"];
    gIsDedicatedWidgetRenderer = gIsWidgetRenderer &&
        ![bundleIdentifier isEqualToString:@"com.apple.chrono.WidgetRenderer-Default"] &&
        ![bundleIdentifier isEqualToString:@"com.apple.chrono.WidgetRenderer-CarPlay"];

    ReloadPrefs();
    if (!kIsEnabled) {
        return;
    }

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(), 
        NULL, 
        (CFNotificationCallback)ReloadPrefs, 
        CFSTR("com.82flex.removewidgetbgprefs/saved"), 
        NULL, 
        CFNotificationSuspensionBehaviorCoalesce
    );

    if ([bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        HBLogDebug(@"Initialized in SpringBoard");
        %init(RWBSpringBoard);
    }
    else if ([bundleIdentifier isEqualToString:@"com.apple.chronod"] || gIsWidgetRenderer) {
        HBLogDebug(@"Initialized in chronod (or WidgetRenderer)");
        %init(RWB);
        if (@available(iOS 17, *)) {
            %init(RWB_17);
        } else if (@available(iOS 16, *)) {
            %init(RWB_16);
        } else {
            %init(RWB_15);
        }
    }
}