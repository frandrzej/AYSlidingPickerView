//
//  AYViewController.m
//  AYSlidingPickerView
//
//  Created by Ayan Yenbekbay on 11/18/2015.
//  Copyright (c) 2015 Ayan Yenbekbay. All rights reserved.
//

#import "AYViewController.h"

#import <AYSlidingPickerView/AYSlidingPickerView.h>

@interface AYViewController ()

#warning Remember to remove pickerView from superView and set to nil, when no longer needed.

/*
 PickerView is added as a subView directly do UIView. This will cause a leak (not visible even to Instruments). A way to go around:
 When is set as strong - when no longer needed (e.g. dismissing view controller), set remove pickerView from superview (main window), then set it to nil. Both are necessary for pickerView to be deallocated.
 When is set as weak - compiler will warn you, but pointer won't go away, as long as pickerView is a subview of window. Need to call [pickerView removeFromSuperview]; to be deallocated
 */
@property (nonatomic, strong) AYSlidingPickerView *pickerView;

@end

@implementation AYViewController

#pragma mark Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Tap to select color";
    [self setUpPickerView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName : [UIColor whiteColor] };
    [self.pickerView addGestureRecognizersToNavigationBar:self.navigationController.navigationBar];
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark Private

- (void)setUpPickerView
{
    NSDictionary *dict = @{ @"Locked" : [UIColor colorWithRed:0.91f green:0.3f blue:0.24f alpha:1],
                            @"Unlocked" : [UIColor colorWithRed:0.590 green:0.828 blue:1.000 alpha:1.000] };
    
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:dict.count];
    
    for (NSString *key in [dict allKeys]) {
//        AYSlidingPickerViewItem *item = [[AYSlidingPickerViewItem alloc] initWithTitle:key image:[UIImage imageNamed:key] handler:^(BOOL completed) {
        AYSlidingPickerViewItem *item = [[AYSlidingPickerViewItem alloc] initWithTitle:key image:nil handler:^(BOOL completed) {
            self.view.backgroundColor = dict[key];
            self.navigationController.navigationBar.barTintColor = [self darkerColorForColor:self.view.backgroundColor];
        }];
        [items addObject:item];
    }
    
    self.pickerView = [[AYSlidingPickerView alloc] initWithNumberOfVisibleItems:3];
    self.pickerView.mainView = self.view;
    self.pickerView.items = items;
    self.pickerView.selectedIndex = 0;
    self.pickerView.tintColor = [UIColor blackColor];
    self.pickerView.closeOnSelection = YES;
    self.pickerView.itemLabelColor = [UIColor darkGrayColor];
    self.pickerView.itemImageColor = [UIColor darkGrayColor];
    self.pickerView.mainViewsStatusBarStyle = UIStatusBarStyleDefault;
    self.pickerView.pickerViewStatusBarStyle = UIStatusBarStyleLightContent;

    __weak typeof(self) weakSelf = self;
    self.pickerView.willAppearHandler = ^{
        NSLog(@"Picker is going to open!");
    };
    self.pickerView.willDismissHandler = ^{
        NSLog(@"Picker is going to close!");
    };
    self.pickerView.didAppearHandler = ^{
        NSLog(@"Picker is opened!");
    };
    self.pickerView.didDismissHandler = ^{
        NSLog(@"Picker is dismissed");
    };
    [self.pickerView setPreferredStatusBarStyleDidChange:^(UIStatusBarStyle style) {
        [weakSelf setNeedsStatusBarAppearanceUpdate];
    }];
    
    self.view.backgroundColor = dict[[dict allKeys][self.pickerView.selectedIndex]];
    self.navigationController.navigationBar.barTintColor = [self darkerColorForColor:self.view.backgroundColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self.pickerView action:@selector(show)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
}

-(void)cancel:(id)sender
{
    if(self.pickerView.state != AYSlidingPickerViewClosedState) {
        __weak typeof(self) weakSelf = self;
        [self.pickerView dismissWithCompletion:^(BOOL completed) {
            [weakSelf.pickerView removeFromSuperview];
            weakSelf.pickerView = nil;
            [weakSelf.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }];
    } else {
        [self.pickerView removeFromSuperview];
        self.pickerView = nil;
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    if(self.pickerView)
        return self.pickerView.preferredCurrentStatusBarStyle;
    return UIStatusBarStyleLightContent;
}

#pragma mark Helpers

- (UIColor *)darkerColorForColor:(UIColor *)color {
    CGFloat r, g, b, a;
    if ([color getRed:&r green:&g blue:&b alpha:&a]) {
        return [UIColor colorWithRed:MAX(r - 0.2f, 0) green:MAX(g - 0.2f, 0) blue:MAX(b - 0.2f, 0) alpha:a];
    }
    return nil;
}

@end
