//
//  GestureHandler.h
//  Mouser
//
//  Created by Hessel van der Molen on 14/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


const NSTimeInterval time_taptimeout = 0.20; //seconds. max interval between click to register a double/triple click

typedef NS_ENUM(NSUInteger, GestureType) {
    GestureTypeUndef       = 0,
    GestureTypeTap         = 100,
    GestureTypeLongPress   = 101,
    GestureTypeDrag        = 102,
    GestureTypeScroll      = 103,
    GestureTypeMove        = 104
};

@interface GestureHandler : NSObject {
    //callee settings
    UIView *_view;
    id      _target;
    SEL     _action;
    
    //recognizers
    UISwipeGestureRecognizer        *_swipeLeftRecognizer;      //swipe left            - two fingers
    UISwipeGestureRecognizer        *_swipeRightRecognizer;     //swipe right           - two fingers
    UISwipeGestureRecognizer        *_swipeUpRecognizer;        //swipe up              - two fingers
    UISwipeGestureRecognizer        *_swipeDownRecognizer;      //swipe down            - two fingers
    UIPanGestureRecognizer          *_panRecognizer;            //moving mouse          - single finger
    UIPanGestureRecognizer          *_scrollRecognizer;         //moving mouse          - two fingers
    UILongPressGestureRecognizer    *_longPressRecognizer;      //longpress/dragging    - single finger
    UITapGestureRecognizer          *_tapRecogniser;            //tapping               - single finger

    //state trackers
    NSTimer   *_tapTimer;
    NSUInteger _tapCount;
    CGPoint    _pos;
    
    //active recogniser & its state
    GestureType              _activeRecognizer;
    UIGestureRecognizerState _recogniserState;
}

- (id) initWithView:(UIView*)view target:(id)target action:(SEL)action;

@end
