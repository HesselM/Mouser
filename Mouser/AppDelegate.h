//
//  AppDelegate.h
//  Mouser
//
//  Created by Hessel van der Molen on 06/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MainViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) MainViewController *viewController;

@end

