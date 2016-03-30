//
//  GestureHandler.m
//  Mouser
//
//  Created by Hessel van der Molen on 14/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import "GestureHandler.h"
#import "MouseEvent.h"

@implementation GestureHandler

- (id) initWithView:(UIView*)view target:(id)target action:(SEL)action
{
    self = [super init];
    _view   = view;
    _target = target;
    _action = action;
    
    /*
    _swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandler:)];
    _swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    _swipeLeftRecognizer.numberOfTouchesRequired = 2;
    [_view addGestureRecognizer:_swipeLeftRecognizer];
    
    _swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandler:)];
    _swipeRightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    _swipeRightRecognizer.numberOfTouchesRequired = 2;
    [_view addGestureRecognizer:_swipeRightRecognizer];
    
    _swipeUpRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandler:)];
    _swipeUpRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    _swipeUpRecognizer.numberOfTouchesRequired = 2;
    [_view addGestureRecognizer:_swipeUpRecognizer];
    
    _swipeDownRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeHandler:)];
    _swipeDownRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    _swipeDownRecognizer.numberOfTouchesRequired = 2;
    [_view addGestureRecognizer:_swipeDownRecognizer];
    */
    
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panHandler:)];
    _panRecognizer.minimumNumberOfTouches = 1;
    _panRecognizer.maximumNumberOfTouches = 1;
    [_view addGestureRecognizer:_panRecognizer];
    
    _scrollRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(scrollHandler:)];
    _scrollRecognizer.minimumNumberOfTouches = 2;
    _scrollRecognizer.maximumNumberOfTouches = 2;
    /*
    [_scrollRecognizer requireGestureRecognizerToFail:_swipeLeftRecognizer];
    [_scrollRecognizer requireGestureRecognizerToFail:_swipeRightRecognizer];
    [_scrollRecognizer requireGestureRecognizerToFail:_swipeUpRecognizer];
    [_scrollRecognizer requireGestureRecognizerToFail:_swipeDownRecognizer];
     */
    [_view addGestureRecognizer:_scrollRecognizer];
    
    
    _longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHandler:)];
    [_view addGestureRecognizer:_longPressRecognizer];
    
    _tapRecogniser = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
    [_view addGestureRecognizer:_tapRecogniser];
        
    
    //init state
    _tapCount = 0;
    _tapTimer = nil;
    
    return self;
}



-(void)swipeHandler:(UISwipeGestureRecognizer*)recognizer
{
    NSLog(@"swipe %ldl %@ %lu", (long)recognizer.state, NSStringFromCGPoint([recognizer locationInView:_view]), (unsigned long)[recognizer direction]);
    //TODO: quick scroll?
}

-(void)panHandler:(UIPanGestureRecognizer*)recognizer
{
    //NSLog(@"panning %ldl %@", (long)recognizer.state, NSStringFromCGPoint([recognizer locationInView:_view]));
    //get previous/current location
    CGPoint prev = _pos;
    _pos = [recognizer locationInView:_view];
    
    //create & dispatch event
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        //params
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys: 
                                [NSValue valueWithCGPoint  :            _pos], @"pos", 
                                [NSNumber numberWithFloat  : _pos.x - prev.x], @"dx" ,
                                [NSNumber numberWithFloat  : _pos.y - prev.y], @"dy" ,
                                nil];
        //event
        MouseEvent *ev = [[MouseEvent alloc] initWithType:MouseEventTypeMove andParams:params];
        [self dispatchEvent:ev];    
    }
}

-(void)longPressHandler:(UILongPressGestureRecognizer*)recognizer
{
    //NSLog(@"longpress %ldl %@", (long)recognizer.state, NSStringFromCGPoint([recognizer locationInView:_view]));
    //TODO: filter movement
    //TODO: - right click
    //TODO: - dragging
    
    //get previous/current location
    CGPoint                  prevPos   = _pos;
    UIGestureRecognizerState prevState = _recogniserState;
    _pos             = [recognizer locationInView:_view];
    _recogniserState = recognizer.state;
    
    //set params
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys: 
                            [NSValue valueWithCGPoint  :               _pos], @"pos", 
                            [NSNumber numberWithFloat  : _pos.x - prevPos.x], @"dx" ,
                            [NSNumber numberWithFloat  : _pos.y - prevPos.y], @"dy" ,
                            nil];
    
    //started a longpress
    if (_recogniserState == UIGestureRecognizerStateBegan) {
        MouseEvent *ev = [[MouseEvent alloc] initWithType:MouseEventTypeLongPressStarted andParams:params]; 
        [self dispatchEvent:ev];
    }
    
    //check rightclick
    if ((prevState == UIGestureRecognizerStateBegan) && (_recogniserState == UIGestureRecognizerStateEnded)) {
        MouseEvent *ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickRight andParams:params];
        [self dispatchEvent:ev];
    } else {
        //check dragging
        if ((_recogniserState == UIGestureRecognizerStateChanged) || (_recogniserState == UIGestureRecognizerStateEnded)) {
            MouseEvent *ev = [[MouseEvent alloc] initWithType:MouseEventTypeDrag andParams:params]; 
            [self dispatchEvent:ev];
        }
    }
    
    //ended a longpress
    if (_recogniserState == UIGestureRecognizerStateEnded) {
        MouseEvent *ev = [[MouseEvent alloc] initWithType:MouseEventTypeLongPressEnded andParams:params]; 
        [self dispatchEvent:ev];
    }
}

-(void)tapHandler:(UITapGestureRecognizer*)recognizer
{
    //NOTE: recognizer.state is always UIGestureRecognizerStateEnded    
    //NSLog(@"tapped %ldl %@", (long)recognizer.state, NSStringFromCGPoint([recognizer locationInView:_view]));
    //disable timer
    if (_tapTimer != nil) {
        [_tapTimer invalidate];
        _tapTimer = nil;
    }
    
    //increase tapCount
    _tapCount++;
    _pos = [recognizer locationInView:_view];
    
    //restart timer
    _tapTimer = [NSTimer scheduledTimerWithTimeInterval:time_taptimeout
                                                 target:self
                                               selector:@selector(tapTimeOut:)
                                               userInfo:nil
                                                repeats:NO];
    
    //process taps directly when we are beyond the point of double/triple click
    if (_tapCount >= 4)
        [self processTap];
}

-(void)scrollHandler:(UIPanGestureRecognizer*)recognizer
{
    //NSLog(@"scrolling %ldl %@", (long)recognizer.state, NSStringFromCGPoint([recognizer locationInView:_view]));
    
    //get previous/current location
    CGPoint prev = _pos;
    _pos = [recognizer locationInView:_view];
    
    //create & dispatch event
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        //params
        NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys: 
                                [NSValue valueWithCGPoint  :            _pos], @"pos", 
                                [NSNumber numberWithFloat  : _pos.x - prev.x], @"dx" ,
                                [NSNumber numberWithFloat  : _pos.y - prev.y], @"dy" ,
                                nil];
        //event
        MouseEvent *ev = [[MouseEvent alloc] initWithType:MouseEventTypeScroll andParams:params];
        [self dispatchEvent:ev];    
    }
}



/******* TAP HANDLING ******/

//Timer for double/triple tap detection
- (void) tapTimeOut:(NSTimer *)timer
{
    //reset timer
    [timer invalidate];
    timer = nil;
    
    //process taps only when we are still detecting double/triple clicks
    if (_tapCount < 4)
        [self processTap];
    
    //reset tapcount
    _tapCount = 0;
}

- (void) processTap
{
    //determine params
    NSUInteger    clicks = (_tapCount > 4) ? 1 : _tapCount;
    NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys: 
                            [NSValue valueWithCGPoint  :   _pos], @"pos"   , 
                            [NSNumber numberWithInteger: clicks], @"clicks", nil];
    //process status
    MouseEvent *ev = nil;
    switch (_tapCount) {
        case 1 : NSLog(@"singleclick"); ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeft      andParams:params]; break;
        case 2 : NSLog(@"doubleclick"); ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeftMulti andParams:params]; break;
        case 3 : NSLog(@"tripleclick"); ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeftMulti andParams:params]; break;
        default: NSLog(@"defaultclck"); ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeft      andParams:params]; break;
    }
    [self dispatchEvent:ev];    
}


/****************** EVENT HANDLING ******************/

- (void) dispatchEvent:(MouseEvent *)ev
{
    if ((_target != nil) && (_action != nil)) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //get address of action
            IMP imp = [_target methodForSelector:_action];
            //create function pointer from action
            void (*func)(id, SEL, MouseEvent*) = (void *)imp;
            //call function
            func(_target, _action, ev);            
        });
    }
}

@end
