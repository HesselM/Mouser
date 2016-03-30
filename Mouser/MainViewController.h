//
//  MainViewController.h
//  Mouser
//
//  Created by Hessel van der Molen on 06/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Client.h"
//#import "TouchHandler.h"
#import "ToggleButton.h"
#import "GestureHandler.h"

@interface MainViewController : UIViewController <UIKeyInput> {
    Client *client;
    GestureHandler *gestureHandler;
    CGPoint pos;
    
    /*
    pref_conn_ipaddress
    pref_conn_updatefreq
    pref_scroll_xsens
    pref_scroll_ysens
    pref_scroll_reverse
    pref_track_speed
    pref_show_settings
    */
    
    NSString   *_ipaddress;
    
    float       _updateInterval;
    NSTimeInterval lastUpdate;
    CGPoint        bufferPos;
    
    float       _scrollx;
    float       _scrolly;
    NSUInteger  _scrollreverse;
    float       _trackspeed;
    
    BOOL        _showsettings;
    UILabel    *_lblsettings;
}

@property (nonatomic, strong) IBOutlet UIButton *btnToggleKeyboard;
@property (nonatomic, strong) IBOutlet UIButton *btnConnect;
@property (nonatomic, strong) IBOutlet UIButton *btnSettings;
@property (nonatomic, strong) IBOutlet UIView *vwMouse;

- (void) loadSettings;

@end
