//
//  AYNavigationViewController.m
//  AYSlidingPickerView
//
//  Created by Andrzej on 27/03/16.
//  Copyright © 2016 Ayan Yenbekbay. All rights reserved.
//

#import "AYNavigationViewController.h"

@interface AYNavigationViewController ()

@end

@implementation AYNavigationViewController

-(UIStatusBarStyle)preferredStatusBarStyle
{
    if([self.topViewController respondsToSelector:@selector(preferredStatusBarStyle)])
        return [self.topViewController preferredStatusBarStyle];
    return UIStatusBarStyleLightContent;
}

@end
