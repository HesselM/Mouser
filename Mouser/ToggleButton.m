//
//  ToggleButton.m
//  Mouser
//
//  Created by Hessel van der Molen on 08/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import "ToggleButton.h"

@implementation ToggleButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)initWithCoder:(NSCoder*)coder {
    self = [super initWithCoder:coder];
    [self setupButton];
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    [self setupButton];
    return self;
}

- (void) setupButton
{
    active = false;
    [self updateButton];
    //toggle appearance when user has touched the button
    [self addTarget:self action:@selector(toggleActive) forControlEvents:UIControlEventTouchUpInside];    
}

//update button appearance based on state
- (void) updateButton 
{
    if (active) {
        [self setBackgroundColor:[[UIColor alloc] initWithRed:0.3 green:0.3 blue:0.3 alpha:1.0]]; 
        [self setTitle:activeTitle forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        [self setBackgroundColor:[[UIColor alloc] initWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]];
        [self setTitle:inActiveTitle forState:UIControlStateNormal];
        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];        
    }  
    [self setNeedsDisplay];
}

//set title & update button
- (void) setActiveTitle:(NSString *)title
{
    activeTitle = title;
    [self updateButton];
}

- (void) setInActiveTitle:(NSString *)title
{
    inActiveTitle = title;
    [self updateButton];
}

//toggle state
// - when user tapped the button
// - when requested programmatically
- (void) toggleActive;
{
    active = !active;
    NSLog(@"active:%d", active);
    [self updateButton];
}

//retrieve current state of button
- (BOOL) isActive
{
    return active;
}

@end
