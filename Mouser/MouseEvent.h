//
//  NSObject+MouseEvent.h
//  Mouser
//
//  Created by Hessel van der Molen on 09/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifndef MouseEvent_h
#define MouseEvent_h

typedef NS_ENUM(NSInteger, MouseEventType) {
    MouseEventTypeNone                              = 0,
    
    MouseEventTypeClickLeft                         = 101,
    MouseEventTypeClickLeftMulti                    = 102,
    MouseEventTypeClickRight                        = 111,
    
    MouseEventTypeMove                              = 201,
    MouseEventTypeDrag                              = 202,
    MouseEventTypeScroll                            = 203,

    MouseEventTypeLongPressStarted                  = 301,
    MouseEventTypeLongPressEnded                    = 302
};

@interface MouseEvent : NSObject

- (MouseEvent *) initWithType:(MouseEventType)type andParams:(NSDictionary*)params;

@property (nonatomic, readonly) MouseEventType type;
@property (nonatomic, readonly) CGPoint pos;
@property (nonatomic, readonly) CGFloat dx;
@property (nonatomic, readonly) CGFloat dy;
@property (nonatomic, readonly) NSUInteger clicks;

@end

#endif /* MouseEvent_h */
