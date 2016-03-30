//
//  ToggleButton.h
//  Mouser
//
//  Created by Hessel van der Molen on 08/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ToggleButton : UIButton {
    BOOL active;
    NSString *activeTitle;
    NSString *inActiveTitle;
}

- (void) setActiveTitle:(NSString *)title;
- (void) setInActiveTitle:(NSString *)title;

- (void) toggleActive;
- (BOOL) isActive;

@end
