//
//  TouchTracker.m
//  Mouser
//
//  Created by Hessel van der Molen on 11/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import "TouchTracker.h"

@implementation TouchTracker

//initializers
- (TouchTracker *) init
{
    self = [super init];
    [self setup];
    return self;
}
- (TouchTracker *) initWithDelegate:(id)d
{
    self = [super init];
    delegate = d;
    [self setup];
    return self;
}

- (void) setup
{
    //deletion scheduling
    delTimer = nil;
    delTimerStartTime = 0;
    scheduledForDeletion = false;
    
    //Lock for handing concurrent updates
    delLock = [[NSLock alloc] init];
    deleted = false;
    
    //longpress detection
    longPressTimer = nil;
    longPressDetected = false;
    
    //shortpress detection
    shortPressTimer = nil;
    
    //move/drag
    lastMoveUpdate = [[NSProcessInfo processInfo] systemUptime];
    dp.x = dp.y = 0;
    
    //params
    _addr       = @"";
    _pos.x = _pos.y = 0;
    _tapCount   = 0;
    _timestamp  = lastMoveUpdate;
    _phase      = UITouchPhaseEnded;
}


//process touching events
- (void)touchBegan:(UITouch *)touch
{
    if (!scheduledForDeletion && !longPressDetected) 
        [self startLongPressTimer];
    dp.x = dp.y = 0;
    
    //update information
    _addr       = [NSString stringWithFormat:@"%lu", (uintptr_t)touch];
    _pos        = [touch locationInView:nil];
    _tapCount   = touch.tapCount;
    _timestamp  = touch.timestamp;
    _phase      = touch.phase;
}

- (void)touchMoved:(UITouch *)touch
{
    [self cancelLongPressTimer];
    [self procesMovementToTouch:touch];

    //update information
    _addr       = [NSString stringWithFormat:@"%lu", (uintptr_t)touch];
    _pos        = [touch locationInView:nil];
    _tapCount   = touch.tapCount;
    _timestamp  = touch.timestamp;
    _phase      = touch.phase; 
    
}

- (void)touchEnded:(UITouch *)touch
{
    [self cancelLongPressTimer];
    MouseEvent *ev;

    //process final moves
    if (_phase == UITouchPhaseMoved)
        [self procesMovementToTouch:touch];
    
    //check longpress
    if (longPressDetected) {
        longPressDetected = false;
                
        //end of drag/long-press
        ev = [[MouseEvent alloc] initWithType:MouseEventTypeLongPressEnded andParams:[self getMouseParams]];
        [self dispatchEvent:ev];
        
        //right click
        if ((_phase == UITouchPhaseBegan) && (touch.timestamp - _timestamp < time_rightclick)) {
            ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickRight andParams:[self getMouseParams]];
            [self dispatchEvent:ev];
        }
    } 
    
    //check short press
    if (_phase == UITouchPhaseBegan) {
        //cancel timer: we received new taps
        if (shortPressTimer != nil) {
            [shortPressTimer invalidate];
            shortPressTimer = nil;
        }
            
        switch (_tapCount) {
            //single, double, triple taps
            case 1:
            case 2:
            case 3:
                shortPressTimer = [NSTimer scheduledTimerWithTimeInterval:time_clicktimeout
                                                                   target:self
                                                                 selector:@selector(tapTimeOut:)
                                                                 userInfo:nil
                                                                  repeats:NO];
                break;
            case 4:
                //no double click has been detected, hence 3 single clicks need to be send
                ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeft andParams:[self getMouseParams]];
                [self dispatchEvent:ev];
                [self dispatchEvent:ev];
                [self dispatchEvent:ev];
                [self dispatchEvent:ev];
                break;
                
            default:                    
                //multiple tabs encountered: just send single click
                ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeft andParams:[self getMouseParams]];
                [self dispatchEvent:ev];
                break;
        }
    }
    
    //update information
    _addr       = [NSString stringWithFormat:@"%lu", (uintptr_t)touch];
    _pos        = [touch locationInView:nil];
    _tapCount   = touch.tapCount;
    _timestamp  = touch.timestamp;
    _phase      = touch.phase;
    
    //set for deletion
    if (!scheduledForDeletion){
        scheduledForDeletion = true;
        [self dispatchTouchTrackerStatus:TouchTrackerStatusDeletionScheduled forTracker:_addr];
    }
    
    //set timer
    delTimerStartTime = [[NSProcessInfo processInfo] systemUptime];
    [self scheduleDeletionTimerWithTimeOut:time_delWindow];
    
}

- (void)touchCancelled:(UITouch *)touch
{
    //update information
    _addr       = [NSString stringWithFormat:@"%lu", (uintptr_t)touch];
    _pos        = [touch locationInView:nil];
    _tapCount   = touch.tapCount;
    _timestamp  = touch.timestamp;
    _phase      = touch.phase;
    
    scheduledForDeletion = deleted = true;
    [self dispatchTouchTrackerStatus:TouchTrackerStatusCancelled forTracker:_addr];
}

//check if new touch is a continueation of the previous touch
- (BOOL)processNewTouch:(UITouch *)touch
{
    //do not check if we are not scheduled for deletion
    if (!scheduledForDeletion)
        return false;

    //ensure timer cannot interrupt
    // if we cannot lock: we are too late
    if (![delLock tryLock])
        return false;
    if (deleted) {
        [delLock unlock];
        return false;
    }
    
    //cancel timer
    NSTimeInterval delTimerStopTime = [[NSProcessInfo processInfo] systemUptime];
    if (delTimer != nil) {
        //NSLog(@"Killed Timer:%@", _addr);
        [delTimer invalidate];
        delTimer = nil;
    }
    
    //if touch is a consecutive touch: tapCount should be increased
    // if this is not the case: continue timer and do not update tracker
    //NSLog(@"%lu-%lu-%ld", (unsigned long)touch.tapCount, (unsigned long)_tapCount, (long)touch.phase);
    //if (touch.tapCount == _tapCount)
    //    NSLog(@"Equal tapcount");
    //if (touch.phase == UITouchPhaseEnded) 
    //    NSLog(@"final phase");
    
    if ((touch.tapCount != (_tapCount+1)) && !((touch.phase == UITouchPhaseEnded) && (touch.tapCount == _tapCount))) {
        [self rescheduleDeletionTimerWithStartTime:delTimerStartTime 
                                          stopTime:delTimerStopTime 
                                        andTimeOut:time_delWindow];
        [delLock unlock];
        return false;
    }
    //NSLog(@"tapcoun:check %@", _addr);

    //check time between touch end ending of previous touch
    // if this is too long: continue timer and do not update tracker
    if (touch.timestamp - _timestamp > time_sameTouch) {
        [self rescheduleDeletionTimerWithStartTime:delTimerStartTime 
                                          stopTime:delTimerStopTime 
                                        andTimeOut:time_delWindow];
        [delLock unlock];
        return false;
    }
    //NSLog(@"timestamp:check %@", _addr);

    //check position
    // if distance is too large: continue timer and do not update tracker
    CGPoint pos = [touch locationInView:nil];
    if ( (pow(_pos.x - pos.x, 2) + pow(_pos.y - pos.y, 2)) > maxPosDiff ) {
        [self rescheduleDeletionTimerWithStartTime:delTimerStartTime 
                                          stopTime:delTimerStopTime 
                                        andTimeOut:time_delWindow];
        [delLock unlock];
        return false;
    }
    
    //else, we found a match!

    //cancel deletion
    scheduledForDeletion = false;
    
    // update tracker
    //NSLog(@"begin:check %@", _addr);
    switch (touch.phase) {
        case UITouchPhaseBegan: [self touchBegan:touch]; break;
        case UITouchPhaseMoved: [self touchMoved:touch]; break;
        case UITouchPhaseEnded: [self touchEnded:touch]; break;
        case UITouchPhaseCancelled: [self touchCancelled:touch]; break;
        default:break;
    }
    
    [delLock unlock];
    //NSLog(@"return:check %@", _addr);
    return true;
}



/****************** DELETE HANDLER ******************/


//schedule timer
- (void) scheduleDeletionTimerWithTimeOut: (NSTimeInterval)timeout
{
    //NSLog(@"timeout:%fl %@", timeout, _addr);
    delTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                target:self
                                              selector:@selector(delTimeOut:)
                                              userInfo:nil
                                               repeats:NO];
}
- (void) rescheduleDeletionTimerWithStartTime:(NSTimeInterval)start 
                                     stopTime:(NSTimeInterval)stop 
                                   andTimeOut:(NSTimeInterval)timeout
{
    NSTimeInterval time_run  = stop - start;
    NSTimeInterval time_todo = timeout - time_run; 
    [self scheduleDeletionTimerWithTimeOut: MAX(time_todo,0.1)];
}


//We did not receive an update, so finalize deletion
- (void) delTimeOut:(NSTimer *)timer
{
    //lock to ensure tracker cannot be updated
    [delLock lock];
    //clear timer
    [timer invalidate];
    timer = nil;
    //set deleted
    deleted = true;
    [delLock unlock];
    //comunnicate deletion
    [self dispatchTouchTrackerStatus:TouchTrackerStatusDeletionFinalize forTracker:_addr];
}



/****************** LONGPRESS HANDLER ******************/

- (void) startLongPressTimer
{
    longPressTimer = [NSTimer scheduledTimerWithTimeInterval:time_longpress
                                                      target:self
                                                    selector:@selector(longPressTimeOut:)
                                                    userInfo:nil
                                                     repeats:NO];
}

- (void) cancelLongPressTimer
{
    if (longPressTimer != nil) {
        [longPressTimer invalidate];
        longPressTimer = nil;
    }
}

- (void) longPressTimeOut:(NSTimer *)timer
{
    NSLog(@"longpress timeout");
    //reset timer
    [timer invalidate];
    timer = nil;
    
    //right click or drag!
    longPressDetected = true;
    
    //process event
    MouseEvent *ev = [[MouseEvent alloc] initWithType:MouseEventTypeLongPressStarted andParams:[self getMouseParams]];
    [self dispatchEvent:ev];
}


/****************** MOVING/DRAGGINH HANDLER ******************/


- (void) procesMovementToTouch:(UITouch *)touch 
{
    CGPoint nextpos = [touch locationInView:nil];
    
    dp.x += (_pos.x - nextpos.x);
    dp.y += (_pos.y - nextpos.y);
    
    //limit number of movement send to the server
    if ((touch.timestamp - lastMoveUpdate > time_moveupdate) || (touch.phase == UITouchPhaseEnded)) {
                
        //send update
        MouseEvent *ev;
        if (longPressDetected) {
            ev = [[MouseEvent alloc] initWithType:MouseEventTypeDrag andParams:[self getMouseParams]];
        } else {
            ev = [[MouseEvent alloc] initWithType:MouseEventTypeMove andParams:[self getMouseParams]];
        }
        [self dispatchEvent:ev];
        
        //update timer
        lastMoveUpdate = touch.timestamp;
        dp.x = dp.y = 0;
    }
}


/****************** CLICK HANDLER ******************/


//no triple tap detected in timeinterval: send "click" command
- (void) tapTimeOut:(NSTimer *)timer
{
    //reset timer
    [timer invalidate];
    timer = nil;

    //process status
    MouseEvent *ev;
    switch (_tapCount) {
        case 1 : NSLog(@"singleclick"); ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeft      andParams:[self getMouseParams]]; break;
        case 2 : NSLog(@"doubleclick"); ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeftMulti andParams:[self getMouseParams]]; break;
        case 3 : NSLog(@"tripleclick"); ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeftMulti andParams:[self getMouseParams]]; break;
        default: NSLog(@"defaultclck"); ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeft      andParams:[self getMouseParams]]; break;
    }
    [self dispatchEvent:ev];
}


/****************** EVENT HANDLING ******************/


- (void) dispatchEvent:(MouseEvent *)ev
{
    if (delegate) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [delegate mouseEventDetected:ev];
        });
    }
}

- (void) dispatchTouchTrackerStatus:(TouchTrackerStatus)status forTracker:(NSString *)addr
{
    if (delegate) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [delegate touchTracker:addr changedStatus:status];
        });
    }
}

- (NSDictionary*) getMouseParams
{
    return [[NSDictionary alloc] initWithObjectsAndKeys: 
                            [NSValue valueWithCGPoint  :     _pos], @"pos"   , 
                            [NSNumber numberWithFloat  :     dp.x], @"dx"    ,
                            [NSNumber numberWithFloat  :     dp.y], @"dy"    ,
                            [NSNumber numberWithInteger:_tapCount], @"clicks", nil];
    
}

@end
