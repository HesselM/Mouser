//
//  TouchHandler.m
//  Mouser
//
//  Created by Hessel van der Molen on 11/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import "TouchHandler.h"

@implementation TouchHandler

//const NSString *activeTrackerSyncKey   = @"activeTrackerSyncKey";
//const NSString *inactiveTrackerSyncKey = @"inactiveTrackerSyncKey";

- (TouchHandler *) initWithDelegate:(id)d
{
    self = [super init];
    delegate = d;
    
    activeTrackers   = [[NSMutableDictionary alloc] init];
    inactiveTrackers = [[NSMutableDictionary alloc] init];
    
    trackerDictLock   = [[NSLock alloc] init];
    return self;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch* touch in touches)
        [self processTouch:touch];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch* touch in touches)
        [self processTouch:touch];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch* touch in touches)
        [self processTouch:touch];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch* touch in touches)
        [self processTouch:touch];
}


- (void) processTouch:(UITouch *)touch {
    [trackerDictLock lock];

    NSString *addr = [NSString stringWithFormat:@"%lu", (uintptr_t)touch];
    TouchTracker *tracker;
    
    //NSLog(@"PROCESS-ActiveKeys:%@", [activeTrackers allKeys]);
    //NSLog(@"PROCESS-InactiveKeys:%@", [inactiveTrackers allKeys]);
    
    //check address in active dictionairy
    tracker = [activeTrackers objectForKey:addr];
    if (tracker != nil) {
        switch (touch.phase) {
            case UITouchPhaseBegan    : [tracker touchBegan:touch]; break;
            case UITouchPhaseMoved    : [tracker touchMoved:touch]; break;
            case UITouchPhaseEnded    : [tracker touchEnded:touch]; break;
            case UITouchPhaseCancelled: [tracker touchCancelled:touch]; break;
            default: break;
        }
        //NSLog(@"match-active:%@/%@",tracker.addr, addr);
        [trackerDictLock unlock];
        return;
    }
    
    
    //check touch in inactive dictionairy
    for (NSString* key in inactiveTrackers) {
        tracker = [inactiveTrackers objectForKey:key];
        // process new touch. Retun upon succes
        if ([tracker processNewTouch:touch]) {
            //NSLog(@"match-deleted:%@",tracker.addr);
            [inactiveTrackers removeObjectForKey:key];
            [activeTrackers setObject:tracker forKey:tracker.addr];
            [trackerDictLock unlock];
            return;
        }
    }


    
    //we did not found a new touch, so create new
    tracker = [[TouchTracker alloc] initWithDelegate:self];
    [activeTrackers setObject:tracker forKey:addr];
    switch (touch.phase) {
        case UITouchPhaseBegan:[tracker touchBegan:touch]; break;
        case UITouchPhaseMoved:[tracker touchMoved:touch]; break;
        case UITouchPhaseEnded:[tracker touchEnded:touch]; break;
        case UITouchPhaseCancelled:[tracker touchCancelled:touch]; break;
        default: [activeTrackers removeObjectForKey:addr]; break;
    }
    
    //NSLog(@"match-new:%@ (%ld)",tracker.addr, (long)tracker.phase);
    [trackerDictLock unlock];
}




- (void) touchTracker:(NSString *)addr 
        changedStatus:(TouchTrackerStatus)status
{
    [trackerDictLock lock];
    //NSLog(@"status:%lu for:%@",(unsigned long)status, addr);
    //NSLog(@"PRE-ActiveKeys:%@", [activeTrackers allKeys]);
    //NSLog(@"PRE-InactiveKeys:%@", [inactiveTrackers allKeys]);
    
    TouchTracker *tracker;
    switch (status) {
        case TouchTrackerStatusDeletionScheduled:
            //move tracked tot inactive dictionairy
            tracker = [activeTrackers objectForKey:addr];
            //if (tracker != nil) {
                [inactiveTrackers setObject:tracker forKey:addr];
                [activeTrackers removeObjectForKey:addr];
            //}
            break;
            
        case TouchTrackerStatusDeletionFinalize:
            //delete tracker from inactive dictionairy
            [inactiveTrackers removeObjectForKey:addr];
            break;
            
        case TouchTrackerStatusCancelled:
            [activeTrackers removeObjectForKey:addr];
            [inactiveTrackers removeObjectForKey:addr];
            break;
                        
        default:
            break;
    }
    
    //NSLog(@"POST-ActiveKeys:%@", [activeTrackers allKeys]);
    //NSLog(@"POST-InactiveKeys:%@", [inactiveTrackers allKeys]);
    
    [trackerDictLock unlock];
}

- (void) mouseEventDetected:(MouseEvent *)event
{
    [trackerDictLock lock];
    NSUInteger asize = [activeTrackers count];
    NSUInteger isize = [inactiveTrackers count];
    [trackerDictLock unlock];

    NSLog(@"%d/%d - %@", asize, isize, event);
}


@end
