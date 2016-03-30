//
//  NSObject+MouseEvent.m
//  Mouser
//
//  Created by Hessel van der Molen on 09/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import "MouseEvent.h"

@implementation MouseEvent : NSObject

- (MouseEvent *) initWithType:(MouseEventType)type andParams:(NSDictionary*)params;
{
    self    = [super init];
    _type   = type;
    _pos    = ([params objectForKey:@"pos"   ] != nil) ? [[params objectForKey:@"pos"   ] CGPointValue] : CGPointZero;
    _dx     = ([params objectForKey:@"dx"    ] != nil) ? [[params objectForKey:@"dx"    ] floatValue  ] : 0;
    _dy     = ([params objectForKey:@"dy"    ] != nil) ? [[params objectForKey:@"dy"    ] floatValue  ] : 0;
    _clicks = ([params objectForKey:@"clicks"] != nil) ? [[params objectForKey:@"clicks"] integerValue] : 0;
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"Event: type=%ld p=%@ d=%f/%f clk=%lu", (long)_type, NSStringFromCGPoint(_pos), _dx, _dy, (unsigned long)_clicks];
}

@end
