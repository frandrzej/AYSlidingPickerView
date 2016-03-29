//
//  AYSlidingPickerView.m
//  AYSlidingPickerView
//
//  Created by Ayan Yenbekbay on 11/18/2015.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import "AYSlidingPickerView.h"

static CGFloat const kSlidingPickerViewExtraTopPadding = 8;
static CGFloat const kSlidingPickerViewBounceOffset = 10;
static CGFloat const kSlidingPickerViewVelocityThreshold = 1000;
static CGFloat const kSlidingPickerViewClosingVelocity = 1200;
static CGFloat const kSlidingPickerViewItemHeight = 30;

@implementation AYSlidingPickerViewItem

- (AYSlidingPickerViewItem *)initWithTitle:(NSString *)title handler:(void (^)(BOOL completed))handler
{
    self = [super init];
    if(!self)
        return nil;
    self.title = title;
    self.handler = handler;
    return self;
}


- (AYSlidingPickerViewItem *)initWithTitle:(NSString *)title image:(UIImage *)image handler:(void (^)(BOOL completed))handler
{
    self = [super init];
    if(!self)
        return nil;
    self.title = title;
    self.image = image;
    self.handler = handler;
    return self;
}

@end

@interface AYSlidingPickerView ()

@property (nonatomic) AYSlidingPickerViewState state;
@property (nonatomic) UIPanGestureRecognizer *mainViewPanGestureRecognizer;
@property (nonatomic) UIPanGestureRecognizer *navigationBarPanGestureRecognizer;
@property (nonatomic) UIPickerView *pickerView;
@property (nonatomic) UITapGestureRecognizer *mainViewTapGestureRecognizer;
@property (nonatomic) UITapGestureRecognizer *navigationBarTapGestureRecognizer;
@property (weak, nonatomic) UINavigationBar *activeNavigationBar;
@property (nonatomic, assign) UIStatusBarStyle preferredCurrentStatusBarStyle;

@end


@implementation AYSlidingPickerView

@synthesize preferredCurrentStatusBarStyle=_preferredCurrentStatusBarStyle;

#pragma mark Initialization

-(instancetype)init
{
    return [self initWithNumberOfVisibleItems:5];
}

- (instancetype)initWithNumberOfVisibleItems:(NSUInteger)numberOfVisibleItems
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.mainViewsStatusBarStyle = UIStatusBarStyleLightContent;
    self.pickerViewStatusBarStyle = UIStatusBarStyleDefault;
    self.preferredCurrentStatusBarStyle = UIStatusBarStyleLightContent;
    
    self.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), kSlidingPickerViewItemHeight * numberOfVisibleItems + CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) + kSlidingPickerViewBounceOffset + kSlidingPickerViewExtraTopPadding);
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    self.backgroundColor = [UIColor colorWithRed:0.93f green:0.94f blue:0.95f alpha:1];
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, kSlidingPickerViewExtraTopPadding, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - kSlidingPickerViewExtraTopPadding)];
    self.pickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.pickerView.showsSelectionIndicator = YES;
    self.pickerView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.pickerView];
    
    self.itemFont = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
    self.itemLabelColor = [UIColor darkGrayColor];
    self.itemImageColor = [UIColor darkGrayColor];
    
    self.navigationBarPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    self.navigationBarTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    self.mainViewPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    self.mainViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    
    [[UIApplication sharedApplication].delegate.window addSubview:self];
    [[UIApplication sharedApplication].delegate.window sendSubviewToBack:self];
    
    return self;
}

+ (AYSlidingPickerView *)sharedInstance
{
    static AYSlidingPickerView *sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    
    dispatch_once(&oncePredicate, ^{
        sharedInstance = [AYSlidingPickerView new];
    });
    
    return sharedInstance;
}

-(void)dealloc
{
    NSLog(@"dealloc");
}

#pragma mark Public

- (void)show {
    [self showWithCompletion:nil];
}

- (void)dismiss {
    [self dismissWithCompletion:nil];
}

- (void)showWithCompletion:(void (^)(BOOL))completion {
    [self showWithCompletion:completion force:YES];
}

- (void)dismissWithCompletion:(void (^)(BOOL))completion {
    [self dismissWithCompletion:completion force:YES];
}

- (void)addGestureRecognizersToNavigationBar:(UINavigationBar *)navigationBar {
    if (self.activeNavigationBar) {
        [self removeGestureRecognizersFromNavigationBar:self.activeNavigationBar];
    }
    self.activeNavigationBar = navigationBar;
    [navigationBar addGestureRecognizer:self.navigationBarPanGestureRecognizer];
    [navigationBar addGestureRecognizer:self.navigationBarTapGestureRecognizer];
}

- (void)removeGestureRecognizersFromNavigationBar:(UINavigationBar *)navigationBar {
    if (self.activeNavigationBar == navigationBar) {
        self.activeNavigationBar = nil;
    }
    [navigationBar removeGestureRecognizer:self.navigationBarPanGestureRecognizer];
    [navigationBar removeGestureRecognizer:self.navigationBarTapGestureRecognizer];
}

#pragma mark Setters

- (void)setItemFont:(UIFont *)itemFont {
    _itemFont = itemFont;
    [self.pickerView reloadAllComponents];
}

- (void)setItemLabelColor:(UIColor *)itemLabelColor {
    _itemLabelColor = itemLabelColor;
    [self.pickerView reloadAllComponents];
}

- (void)setItemImageColor:(UIColor *)itemImageColor
{
    _itemImageColor = itemImageColor;
    [self.pickerView reloadAllComponents];
}

- (void)setMainView:(UIView *)mainView {
    _mainView = mainView;
    self.state = AYSlidingPickerViewClosedState;
}

- (void)setItems:(NSArray *)items {
    _items = items;
    [self.pickerView reloadAllComponents];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    //    _selectedIndex = selectedIndex; //getter handles that
    [self.pickerView selectRow:(NSInteger)selectedIndex inComponent:0 animated:NO];
}

-(NSUInteger)selectedIndex
{
    return [self.pickerView selectedRowInComponent:0];
}

- (void)setState:(AYSlidingPickerViewState)state {
    _state = state;
    if (state == AYSlidingPickerViewShownState) {
        for (UIView *subview in self.mainView.subviews) {
            subview.userInteractionEnabled = NO;
        }
        [self.mainView addGestureRecognizer:self.mainViewPanGestureRecognizer];
        [self.mainView addGestureRecognizer:self.mainViewTapGestureRecognizer];
    } else if (state == AYSlidingPickerViewClosedState) {
        for (UIView *subview in self.mainView.subviews) {
            subview.userInteractionEnabled = YES;
        }
        [self.mainView removeGestureRecognizer:self.mainViewPanGestureRecognizer];
        [self.mainView removeGestureRecognizer:self.mainViewTapGestureRecognizer];
    }
}

#pragma mark Private

-(void)setPreferredCurrentStatusBarStyle:(UIStatusBarStyle)preferredCurrentStatusBarStyle
{
    if(_preferredCurrentStatusBarStyle == preferredCurrentStatusBarStyle)
        return;
    _preferredCurrentStatusBarStyle = preferredCurrentStatusBarStyle;
    [[UIApplication sharedApplication] setStatusBarStyle:preferredCurrentStatusBarStyle animated:NO];
    if(self.preferredStatusBarStyleDidChange)
        self.preferredStatusBarStyleDidChange(preferredCurrentStatusBarStyle);
}

- (void)showWithCompletion:(void (^)(BOOL))completion force:(BOOL)force {
    if (self.isDisabled) {
        return;
    }
    NSAssert(self.mainView, @"Main view must be specified");
    NSAssert(self.items && self.items.count > 0, @"Array of items can't be empty");
    self.pickerView.hidden = NO;
    if (self.state == AYSlidingPickerViewClosedState) {
        [self animateSelectorOpeningWithCompletion:completion];
    } else if (!force) {
        [self animateSelectorClosingWithCompletion:completion];
    }
}

- (void)dismissWithCompletion:(void (^)(BOOL))completion force:(BOOL)force {
    if (self.state == AYSlidingPickerViewShownState || self.state == AYSlidingPickerViewDisplayingState) {
        [self animateSelectorClosingWithCompletion:completion];
    } else if (!force) {
        [self animateSelectorOpeningWithCompletion:completion];
    }
}

#pragma mark Gesture recognizers

- (void)didPan:(UIPanGestureRecognizer *)gestureRecognizer {
    if (self.isDisabled) {
        return;
    }
    self.pickerView.hidden = NO;
    for (UIView *view in [UIApplication sharedApplication].delegate.window.subviews) {
        if (view != self) {
            __block CGPoint viewCenter = view.center;
            if (gestureRecognizer.state == UIGestureRecognizerStateBegan || gestureRecognizer.state == UIGestureRecognizerStateChanged) {
                CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view.superview];
                if (viewCenter.y >= CGRectGetMidY([UIScreen mainScreen].bounds) && viewCenter.y <= CGRectGetMidY([UIScreen mainScreen].bounds) + CGRectGetHeight(self.bounds) - kSlidingPickerViewBounceOffset) {
                    self.state = AYSlidingPickerViewDisplayingState;
                    viewCenter.y = ABS(viewCenter.y + translation.y);
                    if (viewCenter.y >= CGRectGetMidY([UIScreen mainScreen].bounds) &&
                        viewCenter.y < (CGRectGetMidY([UIScreen mainScreen].bounds) + CGRectGetHeight(self.bounds) - kSlidingPickerViewBounceOffset)) {
                        view.center = viewCenter;
                        if (ABS(CGRectGetMidY([UIScreen mainScreen].bounds) - viewCenter.y) > CGRectGetHeight([UIApplication sharedApplication].statusBarFrame)) {
                            self.preferredCurrentStatusBarStyle = self.mainViewsStatusBarStyle;
                        } else {
                            self.preferredCurrentStatusBarStyle = self.pickerViewStatusBarStyle;
                        }
                    }
                    [gestureRecognizer setTranslation:CGPointZero inView:self.mainView];
                }
            } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
                CGPoint velocity = [gestureRecognizer velocityInView:gestureRecognizer.view.superview];
                if (velocity.y > kSlidingPickerViewVelocityThreshold) {
                    [self openSelectorFromCenterWithVelocity:velocity.y completion:nil];
                } else if (velocity.y < -kSlidingPickerViewVelocityThreshold) {
                    [self closeSelectorFromCenterWithVelocity:ABS(velocity.y) completion:nil];
                } else if (viewCenter.y < CGRectGetMidY([UIScreen mainScreen].bounds) + CGRectGetHeight(self.bounds) / 2) {
                    [self closeSelectorFromCenterWithVelocity:kSlidingPickerViewClosingVelocity completion:nil];
                } else if (viewCenter.y <= (CGRectGetMidY([UIScreen mainScreen].bounds) + CGRectGetHeight(self.bounds) - kSlidingPickerViewBounceOffset)) {
                    [self openSelectorFromCenterWithVelocity:kSlidingPickerViewClosingVelocity completion:nil];
                }
            }
        }
    }
}

- (void)didTap:(UITapGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer.view isKindOfClass:[UINavigationBar class]]) {
        [self showWithCompletion:nil force:NO];
    } else {
        [self dismissWithCompletion:nil force:NO];
    }
}

#pragma mark Animations

- (void)animateSelectorOpeningWithCompletion:(void (^)(BOOL))completion {
    if (self.state != AYSlidingPickerViewShownState && self.state != AYSlidingPickerViewDisplayingState) {
        self.state = AYSlidingPickerViewDisplayingState;
        if (self.willAppearHandler) {
            self.willAppearHandler();
        }
        self.preferredCurrentStatusBarStyle = self.mainViewsStatusBarStyle;
        [UIView animateWithDuration:0.2f animations:^{
            // Pushing the controller down
            for (UIView *view in [UIApplication sharedApplication].delegate.window.subviews) {
                if (view != self) {
                    view.center = CGPointMake(view.center.x, CGRectGetMidY([UIScreen mainScreen].bounds) + CGRectGetHeight(self.bounds));
                }
            }
        } completion:^(BOOL completedFirst) {
            [UIView animateWithDuration:0.2f animations:^{
                for (UIView *view in [UIApplication sharedApplication].delegate.window.subviews) {
                    if (view != self) {
                        view.center = CGPointMake(view.center.x, view.center.y - kSlidingPickerViewBounceOffset);
                    }
                }
            } completion:^(BOOL completedSecond) {
                self.state = AYSlidingPickerViewShownState;
                if (completion) {
                    completion(completedSecond);
                }
                if (self.didAppearHandler) {
                    self.didAppearHandler();
                }
            }];
        }];
    }
}

- (void)animateSelectorClosingWithCompletion:(void (^)(BOOL))completion {
    if (self.state != AYSlidingPickerViewClosedState) {
        self.state = AYSlidingPickerViewDisplayingState;
        if (self.willDismissHandler) {
            self.willDismissHandler();
        }
        [UIView animateWithDuration:0.2f animations:^{
            // Pulling the controller up
            for (UIView *view in [UIApplication sharedApplication].delegate.window.subviews) {
                if (view != self) {
                    view.center = CGPointMake(view.center.x, view.center.y + kSlidingPickerViewBounceOffset);
                }
            }
        } completion:^(BOOL completedFirst) {
            self.preferredCurrentStatusBarStyle = self.pickerViewStatusBarStyle;
            [UIView animateWithDuration:0.2f animations:^{
                // Pushing the controller down
                for (UIView *view in [UIApplication sharedApplication].delegate.window.subviews) {
                    if (view != self) {
                        view.center = CGPointMake(view.center.x, CGRectGetMidY([UIScreen mainScreen].bounds));
                    }
                }
            } completion:^(BOOL completedSecond) {
                self.state = AYSlidingPickerViewClosedState;
                if (completion) {
                    completion(completedSecond);
                }
                if (self.didDismissHandler) {
                    self.didDismissHandler();
                }
            }];
        }];
    }
}

- (void)openSelectorFromCenterWithVelocity:(CGFloat)velocity completion:(void (^)(BOOL))completion {
    self.state = AYSlidingPickerViewDisplayingState;
    if (self.willAppearHandler) {
        self.willAppearHandler();
    }
    self.preferredCurrentStatusBarStyle = self.mainViewsStatusBarStyle;
    CGFloat viewCenterY = CGRectGetMidY([UIScreen mainScreen].bounds) + CGRectGetHeight(self.bounds) - kSlidingPickerViewBounceOffset;
    for (UIView *view in [UIApplication sharedApplication].delegate.window.subviews) {
        if (view != self) {
            [UIView animateWithDuration:((viewCenterY - view.center.y) / velocity) animations:^{
                view.center = CGPointMake(view.center.x, viewCenterY);
            } completion:^(BOOL completed) {
                self.state = AYSlidingPickerViewShownState;
                if (completion) {
                    completion(completed);
                }
                if (self.didAppearHandler) {
                    self.didAppearHandler();
                }
            }];
        }
    }
}

- (void)closeSelectorFromCenterWithVelocity:(CGFloat)velocity completion:(void (^)(BOOL))completion {
    self.state = AYSlidingPickerViewDisplayingState;
    if (self.willDismissHandler) {
        self.willDismissHandler();
    }
    self.preferredCurrentStatusBarStyle = self.pickerViewStatusBarStyle;
    for (UIView *view in [UIApplication sharedApplication].delegate.window.subviews) {
        if (view != self) {
            [UIView animateWithDuration:((view.center.y - CGRectGetMidY([UIScreen mainScreen].bounds)) / velocity) animations:^{
                view.center = CGPointMake(view.center.x, CGRectGetMidY([UIScreen mainScreen].bounds));
            } completion:^(BOOL completed) {
                self.state = AYSlidingPickerViewClosedState;
                if (completion) {
                    completion(completed);
                }
                if (self.didDismissHandler) {
                    self.didDismissHandler();
                }
            }];
        }
    }
}

#pragma mark UIPickerViewDelegate

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return (NSInteger)self.items.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return kSlidingPickerViewItemHeight;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return CGRectGetWidth(self.bounds);
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UIImageView *imageView;
    UILabel *label;
    
    if (!view) {
        view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), kSlidingPickerViewItemHeight)];
        
        imageView = [UIImageView new];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.tintColor = self.itemImageColor;
        [view addSubview:imageView];
        
        label = [UILabel new];
        label.font = self.itemFont;
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = self.itemLabelColor;
        [view addSubview:label];
    }
    
    AYSlidingPickerViewItem *item = (AYSlidingPickerViewItem *)self.items[(NSUInteger)row];
    
    if(item.image) {
        CGFloat x = CGRectGetWidth(self.bounds)/2 - 100.0;
        CGFloat horizontalPadding = 15.0f;
        CGFloat imageViewInsets = 2.0f;
        
        label.textAlignment = NSTextAlignmentLeft;
        
        imageView.frame = CGRectMake(x + imageViewInsets, 0, kSlidingPickerViewItemHeight - imageViewInsets, kSlidingPickerViewItemHeight - imageViewInsets);
        label.frame = CGRectMake(x + kSlidingPickerViewItemHeight + horizontalPadding, 0, CGRectGetWidth(self.bounds) - kSlidingPickerViewItemHeight - horizontalPadding, kSlidingPickerViewItemHeight);
        
    } else {
        label.textAlignment = NSTextAlignmentCenter;
        label.frame = view.bounds;
    }
    
    imageView.image = item.image;
    label.text = item.title;
    
    return view;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    AYSlidingPickerViewItem *selectedItem = self.items[(NSUInteger)row];
    if (self.closeOnSelection)
        [self animateSelectorClosingWithCompletion:selectedItem.handler];
    else
        selectedItem.handler(YES);
}

@end
