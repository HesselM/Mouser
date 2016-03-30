//
//  TouchTracker.h
//  Mouser
//
//  Created by Hessel van der Molen on 11/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MouseEvent.h"

#ifndef TouchTracker_h
#define TouchTracker_h

const NSUInteger maxPosDiff = 45*45; //squared value of maximum radius two touches may differ in location

const NSTimeInterval time_delWindow    = 1.00; //number seconds after 'touchEnded' that tracker will be indicate it is ready for deletion
const NSTimeInterval time_sameTouch    = 0.50; //maximum number seconds between touches to state they belong together
const NSTimeInterval time_longpress    = 0.20; //seconds. min time we need to press down for a long click
const NSTimeInterval time_rightclick   = 1.00; //seconds. max time a 'longpress' may endure before it is no longer a rightclick
const NSTimeInterval time_moveupdate   = 0.01; //seconds. min time between move-updates send to the server
const NSTimeInterval time_clicktimeout = 0.20; //seconds. max interval between click to register a double/triple click


typedef NS_ENUM(NSInteger, TouchTrackerStatus) {
    TouchTrackerStatusNone                  = 0,
    
    //deletion status after "touchEnded"
    TouchTrackerStatusDeletionScheduled     = 100,
    TouchTrackerStatusDeletionFinalize      = 101,
    
    //deletion status after "touchCancelled"
    TouchTrackerStatusCancelled             = 200,
};

@protocol TouchTrackerDelegate
@required - (void) touchTracker:(NSString*)tracker changedStatus:(TouchTrackerStatus)status;
@required - (void) mouseEventDetected:(MouseEvent *)event;
@end


@interface TouchTracker : NSObject {
    id delegate;
    
    //deletion scheduling
    NSTimer *delTimer;
    NSTimeInterval delTimerStartTime;
    BOOL scheduledForDeletion;
    
    //Lock for handing concurrent updates
    NSLock *delLock;
    BOOL deleted;
    
    //longpress detection
    NSTimer *longPressTimer;
    BOOL longPressDetected;
    
    //shortpress detection
    NSTimer *shortPressTimer;
    
    //move/drag
    NSTimeInterval  lastMoveUpdate;
    CGPoint dp;
}

//initialiser
- (TouchTracker *) init;
- (TouchTracker *) initWithDelegate:(id)delegate;

//tracker properties
@property (nonatomic, readonly) NSString       *addr;
@property (nonatomic, readonly) CGPoint         pos;
@property (nonatomic, readonly) NSUInteger      tapCount;
@property (nonatomic, readonly) NSTimeInterval  timestamp;
@property (nonatomic, readonly) UITouchPhase    phase;

//process touching events
- (void)touchBegan:(UITouch *)touch;
- (void)touchMoved:(UITouch *)touch;
- (void)touchEnded:(UITouch *)touch;
- (void)touchCancelled:(UITouch *)touch;

//if a touch has ended, but a new touch is started at the same place within a small window of time,
// we assume that the new touch is actually an consequtive touch.
// The function returns true when a match is detected
- (BOOL)processNewTouch:(UITouch *)touch;

@end

#endif /* TouchTracker_h */

