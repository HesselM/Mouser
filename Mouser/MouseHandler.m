//
//  NSObject+MouseHandler.m
//  Mouser
//
//  Created by Hessel van der Molen on 07/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import "MouseHandler.h"

@implementation MouseHandler : NSObject


- (MouseHandler *) initWithDelegate:(id)d
{
    self = [super init];
    
    delegate  = d;
    prevPos.x = prevPos.y = 0;
    prevTime  = 0;
    tapTimer  = nil;
    dx        = dy        = 0;    
    lastMoveUpdate = 0;
    
    return self;
}


- (void) processTouches:(NSSet      *)touches 
              withEvent:(UIEvent    *)event 
                andType:(touchType_t )type
{
    NSUInteger touchcount = [touches count] ;
    
    if (type == BEGIN) {
        if (touchcount == 1)
            sequenceIsMultiTouch = false;
        else
            sequenceIsMultiTouch = true;
    }
    
    
    //multitouch handling
    if (sequenceIsMultiTouch) {
        
        
        
    //singletouch handling
    } else {
        //only process if we have a single touch
        if (touchcount == 1)
            [self processTouch:[[touches allObjects] objectAtIndex:0] withEvent:event andType:type];

        
    }
/*    
    if ([touches count] > 0) {
        for (UITouch *touch in touches) {
            CGPoint *point = (CGPoint *)CFDictionaryGetValue(touchBeginPoints, touch);
            if (point == NULL) {
                point = (CGPoint *)malloc(sizeof(CGPoint));
                CFDictionarySetValue(touchBeginPoints, touch, point);
            }
            *point = [touch locationInView:view.superview];
        }
    }

*/
}





- (void) processTouch:(UITouch    *)touch
            withEvent:(UIEvent    *)event
              andType:(touchType_t )type;
{      
    
    //long press detection
    if (type == BEGIN) {
        longPressTimer = [NSTimer scheduledTimerWithTimeInterval:time_longpress
                                                          target:self
                                                        selector:@selector(longPressTimeOut:)
                                                        userInfo:nil
                                                         repeats:NO];
    } else {
        //user moves or ends an event
        // Check if timer is still running: ifso, user did not perform a long press
        if (longPressTimer != nil) {
            [longPressTimer invalidate];
            longPressTimer = nil;
        }
    }
    
    
    //start + end: click
    if ((prevType == BEGIN) && (type == END) ) {

        if (longPressDetected) {
            longPressDetected = false;
            
            //end of drag/long-press
            MouseEvent *ev;
            ev = [[MouseEvent alloc] initWithType:MouseEventTypeLongPressEnded];
            [delegate mouseEventDetected:ev];
            
            //right click
            if (touch.timestamp - prevTime < time_rightclick) {
                ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickRight];
                [delegate mouseEventDetected:ev];
            }
           
        } else {
        
            NSLog(@"TapCount: %lu", (unsigned long)touch.tapCount);

            tapCount = touch.tapCount;
            
            //disable timer: we have received new value befor timeout
            if (tapTimer != nil) {
                [tapTimer invalidate];
                tapTimer = nil;
            }

            MouseEvent *ev;
            switch (tapCount) {
                //single, double, triple taps
                case 1:
                case 2:
                case 3:
                    tapTimer = [NSTimer scheduledTimerWithTimeInterval:time_clicktimeout
                                                                target:self
                                                              selector:@selector(tapTimeOut:)
                                                              userInfo:nil
                                                               repeats:NO];
                    break;
                case 4:
                    //no double click has been detected, hence 3 single clicks need to be send
                    ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeft];
                    [delegate mouseEventDetected:ev];
                    [delegate mouseEventDetected:ev];
                    [delegate mouseEventDetected:ev];
                    [delegate mouseEventDetected:ev];
                    break;

                default:                    
                    //multiple tabs encountered: just send single click
                    ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeft];
                    [delegate mouseEventDetected:ev];
                    break;
            }
        }
                
    } else {
        // moved: dragging
        if ((type == CHANGE) || (type == END)) {
            CGPoint t0 = prevPos;
            CGPoint t1 = [touch locationInView:nil];
            
            dx += (t1.x - t0.x);
            dy += (t1.y - t0.y);
            
            //limit number of movement send to the server
            if ((touch.timestamp - lastMoveUpdate > time_moveupdate) || (type == END)) {
                
                //send update
                MouseEvent *ev;
                if (longPressDetected) {
                    ev = [[MouseEvent alloc] initWithType:MouseEventTypeDrag dx:dx dy:dy];
                } else {
                    ev = [[MouseEvent alloc] initWithType:MouseEventTypeMove dx:dx dy:dy];
                }
                [delegate mouseEventDetected:ev];
                
                //update timer
                lastMoveUpdate = touch.timestamp;
                dx = dy = 0;
            }

        }
        
        //if movement has ended: longPress becomes invalid
        if ((type == END) && longPressDetected){
            longPressDetected = false;
            MouseEvent *ev;
            ev = [[MouseEvent alloc] initWithType:MouseEventTypeLongPressEnded];
            [delegate mouseEventDetected:ev];
        }
    }
        
    prevPos   = [touch locationInView:nil];
    prevTime  = touch.timestamp;
    prevType  = type;
}



//no triple tap detected in timeinterval: send "click" command
- (void) tapTimeOut:(NSTimer *)timer
{
    //reset timer
    [timer invalidate];
    timer = nil;
    
    //process status
    MouseEvent *ev;
    switch (tapCount) {
        case 1 : NSLog(@"singleclick"); ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeft]; break;
        case 2 : NSLog(@"doubleclick"); ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeftMulti clicks:2]; break;
        case 3 : NSLog(@"tripleclick"); ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeftMulti clicks:3]; break;
        default: NSLog(@"defaultclck"); ev = [[MouseEvent alloc] initWithType:MouseEventTypeClickLeft]; break;
    }
    [delegate mouseEventDetected:ev];
}

//user pressed for a long time.
- (void) longPressTimeOut:(NSTimer *)timer
{
    //reset timer
    [timer invalidate];
    timer = nil;
    
    //right click or drag!
    longPressDetected = true;
    
    //process event
    MouseEvent *ev = [[MouseEvent alloc] initWithType:MouseEventTypeLongPressStarted];
    [delegate mouseEventDetected:ev];
}


//multi touch event handlin
- (void) processMultiTouch:(NSSet      *)touches
                 withEvent:(UIEvent    *)event
                   andType:(touchType_t )type
{
    //NSLog(@"MultiTouch Event:%@", event);
    NSLog(@"Multi %d", [touches count]);
}



@end
