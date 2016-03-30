//
//  NSObject+MouseHandler.h
//  Mouser
//
//  Created by Hessel van der Molen on 07/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MouseEvent.h"

#ifndef MouseHandler_h
#define MouseHandler_h

typedef enum touchType {
    BEGIN,
    CHANGE,
    END
} touchType_t;


@protocol MouseHandlerDelegate

//callback when the MouseHandler has detected an event 
@required - (void) mouseEventDetected: (MouseEvent *) event;

@end


const float time_longpress    = 0.20; //seconds. min time we need to press down for a long click
const float time_rightclick   = 1.00; //seconds. max time a 'longpress' may endure before it is no longer a rightclick
const float time_clicktimeout = 0.20; //seconds. max interval between click to register a double/triple click
const float time_moveupdate   = 0.01; //seconds. min time between move-updates send to the server


@interface MouseHandler : NSObject {
    //delegate for callback
    id              delegate;
    
    //multitouch sequence
    BOOL            sequenceIsMultiTouch;
    
    //Single-Touch state tracking
    touchType_t     prevType;
    CGPoint         prevPos;
    NSTimeInterval  prevTime;

    //Single-Touch timers
    NSTimer         *longPressTimer;
    NSTimer         *tapTimer;

    //Single-Toucg state caputure
    NSUInteger      tapCount;
    BOOL            longPressDetected;

    //movement
    NSTimeInterval  lastMoveUpdate;
    CGFloat         dx;
    CGFloat         dy;
}


- (MouseHandler *) initWithDelegate:(id)delegate;

- (void) processTouches:(NSSet      *)touches 
              withEvent:(UIEvent    *)event 
                andType:(touchType_t )type;

/*
- (void) processTouch:(UITouch    *)touch
            withEvent:(UIEvent    *)event
              andType:(touchType_t )type;

- (void) processMultiTouch:(NSSet      *)touches
                 withEvent:(UIEvent    *)event
                   andType:(touchType_t )type;
 */
@end

#endif /* MouseHandler_h */
