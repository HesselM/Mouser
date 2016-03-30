//
//  TouchHandler.h
//  Mouser
//
//  Created by Hessel van der Molen on 11/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TouchTracker.h"

#ifndef TouchHandler_h
#define TouchHandler_h

@protocol TouchHandlerDelegate
@end

@interface TouchHandler : NSObject <TouchTrackerDelegate>{
    id delegate;
    
    NSMutableDictionary *activeTrackers;
    NSMutableDictionary *inactiveTrackers;
    
    //dict locks
    NSLock *trackerDictLock;
}

- (TouchHandler *) initWithDelegate:(id)delegate;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;


@end

#endif /* TouchHandler_h */
