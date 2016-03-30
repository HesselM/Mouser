//
//  MainViewController.m
//  Mouser
//
//  Created by Hessel van der Molen on 06/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import "MainViewController.h"
#import "MouseEvent.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //[self.btnMouseLock addTarget:self action:@selector(lockPress) forControlEvents:UIControlEventTouchUpInside];
    //[self.btnMouseLock setActiveTitle:@"Dragging activated"];
    //[self.btnMouseLock setInActiveTitle:@"Activate dragging"];
    
    [self.btnConnect addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
    [self.btnToggleKeyboard addTarget:self action:@selector(toggleKeyboard) forControlEvents:UIControlEventTouchUpInside];
    [self.btnSettings addTarget:self action:@selector(gotoSettings) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    //Allocate handler to process mouse events
    gestureHandler = [[GestureHandler alloc] initWithView:self.vwMouse target:self action:@selector(mouseUpdate:)];

    _ipaddress       = @"192.168.1.1";
    _updateInterval  = 1/100;
    lastUpdate       = 0;
    bufferPos.x = bufferPos.y = 0;
    _scrollx         = 1.0;
    _scrolly         = 1.0;
    _scrollreverse   = 1;
    _trackspeed      = 1.0;
    _showsettings    = false;
    _lblsettings     = nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadSettings];
    //[self becomeFirstResponder];
}

- (void) loadSettings
{
    NSLog(@"appeard");
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"pref_conn_ipaddress"]) {
        _ipaddress = [[NSUserDefaults standardUserDefaults] stringForKey:@"pref_conn_ipaddress"];
    } 
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"pref_conn_updatefreq"]) {
        NSString *freq = [[NSUserDefaults standardUserDefaults] stringForKey:@"pref_conn_updatefreq"];
        NSLog(@"%@", freq);
        float freqf = [freq floatValue];
        if (freqf > 0)
            _updateInterval = 1/freqf;
    }
    
    if ([[NSUserDefaults standardUserDefaults] floatForKey:@"pref_scroll_xsens"]) {
        _scrollx = [[NSUserDefaults standardUserDefaults] floatForKey:@"pref_scroll_xsens"];
        NSLog(@"scroll:%f", _scrollx);
    }
    
    if ([[NSUserDefaults standardUserDefaults] floatForKey:@"pref_scroll_ysens"]) {
        _scrolly = [[NSUserDefaults standardUserDefaults] floatForKey:@"pref_scroll_ysens"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"pref_scroll_reverse"]) {
        _scrollreverse = -1;
    } else {
        _scrollreverse = 1;  
    }
    
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"pref_track_speed"] != nil) {
        _trackspeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"pref_track_speed"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"pref_show_settings"]) {
        _showsettings = true;
        
        if (_lblsettings == nil) {
            _lblsettings = [[UILabel alloc] init];
            _lblsettings.numberOfLines = 0;
            [self.vwMouse addSubview:_lblsettings];
        }
        
        CGRect frame = self.vwMouse.frame;
        frame.origin.y = 0;
        [_lblsettings setFrame:frame];
        
        NSString *settings = [NSString stringWithFormat:
            @"ipaddress:%@\nFrequency:%d\ntracking :%f\nhscroll  :%f\nvscroll  :%f\nreversed :%lu\n ",
            _ipaddress, (int)(1.0f/_updateInterval), _trackspeed, _scrollx, _scrolly, (unsigned long)_scrollreverse];
        [_lblsettings setText:settings];
        NSLog(@"settings: %@", settings);
    } 
    
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


/*
 * CONNECTION HANDLING
 */

- (void) connect 
{
    NSLog(@"CONNECT REQUEST");
    
    if (client.connectionStatus == CONNECTED) {
        [client closeConnection];
        client = nil;
    }
    
    client = [[Client alloc] init];
    [client setAddress:_ipaddress withPort:4376];
    [client openConnection];
    
    if (client.connectionStatus == DISCONNECTED)
        [self.btnConnect setBackgroundColor:[UIColor redColor]];
    
    if (client.connectionStatus == NOTREADY)
        [self.btnConnect setBackgroundColor:[UIColor orangeColor]];
    
    if (client.connectionStatus == CONNECTED)
        [self.btnConnect setBackgroundColor:[UIColor greenColor]];
}



-(void)mouseUpdate:(MouseEvent*)event;
{
    //NSLog(@"%@", event);

    if (client.connectionStatus == CONNECTED) {
 
        //update user interface if we detected either start or end of dragging
        //if (![self.btnMouseLock isActive] && (event.type == MouseEventTypeLongPressStarted))
        //    [self.btnMouseLock toggleActive];
        //
        //if ([self.btnMouseLock isActive] && (event.type == MouseEventTypeLongPressEnded))
        //    [self.btnMouseLock toggleActive];
        
        //build command
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        NSString *cmd = @"";
        switch (event.type) {
            case MouseEventTypeClickLeft:
                cmd = [NSString stringWithFormat:@"mouse:click:%d;", (int)event.clicks];
                break;
            case MouseEventTypeClickLeftMulti:
                switch (event.clicks) {
                    case 2:  cmd = [NSString stringWithFormat:@"mouse:doubleclick;"]; break;
                    case 3:  cmd = [NSString stringWithFormat:@"mouse:tripleclick;"]; break;
                    default: cmd = [NSString stringWithFormat:@"mouse:click:%d;", (int)event.clicks]; break;
                }
                break;
            case MouseEventTypeClickRight:
                cmd = [NSString stringWithFormat:@"mouse:rightclick"]; 
                break;
            case MouseEventTypeMove:
                bufferPos.x += event.dx;
                bufferPos.y += event.dy;
                if (((now - lastUpdate) > _updateInterval) && !((bufferPos.x == 0) && (bufferPos.y == 0))) {
                    lastUpdate  = now;
                    cmd = [NSString stringWithFormat:@"mouse:move:%f:%f;", 
                        [self correctSpeed:bufferPos.x withCorrection:_trackspeed],
                        [self correctSpeed:bufferPos.y withCorrection:_trackspeed]]; 
                    bufferPos.x = bufferPos.y = 0;
                }
                break;
            case MouseEventTypeDrag:
                bufferPos.x += event.dx;
                bufferPos.y += event.dy;
                if (((now - lastUpdate) > _updateInterval) && !((bufferPos.x == 0) && (bufferPos.y == 0))) {
                    lastUpdate  = now;
                    cmd = [NSString stringWithFormat:@"mouse:drag:%f:%f;", 
                           [self correctSpeed:bufferPos.x withCorrection:_trackspeed],
                           [self correctSpeed:bufferPos.y withCorrection:_trackspeed]];
                    bufferPos.x = bufferPos.y = 0;
                }
                break;
            case MouseEventTypeLongPressStarted:
                cmd = [NSString stringWithFormat:@"mouse:drag:start;"];
                break;
            case MouseEventTypeLongPressEnded:
                cmd = [NSString stringWithFormat:@"mouse:drag:end;"];
                break;
            case MouseEventTypeScroll:
                bufferPos.x += event.dx;
                bufferPos.y += event.dy;
                if (((now - lastUpdate) > _updateInterval) && !((bufferPos.x == 0) && (bufferPos.y == 0))) {
                    lastUpdate  = now;
                    cmd = [NSString stringWithFormat:@"mouse:scroll:%f:%f;",
                           _scrollreverse*[self correctSpeed:bufferPos.x withCorrection:_scrollx],
                           _scrollreverse*[self correctSpeed:bufferPos.y withCorrection:_scrolly]]; 
                    bufferPos.x = bufferPos.y = 0;
                }
                break;
            case MouseEventTypeNone:
            default:
                break;
        }
        
        //if lock button is active: force movement for dragging
        //if ([self.btnMouseLock isActive])
        //    cmd = [cmd stringByReplacingOccurrencesOfString:@":move:"
        //                                         withString:@":drag:"];
        
        //send command
        [client sendString:cmd];
    }
}

- (float) correctSpeed:(float)val withCorrection:(float)correction
{
    float cor_val = pow(fabsf(val), correction);
    if (val < 0) 
        cor_val *= -1;
    return cor_val;
}


//keyboard handling
- (void)toggleKeyboard
{
    if ([self isFirstResponder])
        [self resignFirstResponder];
    else  
        [self becomeFirstResponder];
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)hasText
{
    return false; 
}


- (void)insertText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
        [self keyUpdate:@"enter"];
    else
        [self keyUpdate:text];
}

- (void)deleteBackward
{
    [self keyUpdate:@"backspace"];
}

- (void) keyUpdate: (NSString *)key
{
    NSString *cmd = [NSString stringWithFormat:@"key:down:%@", key];
    [client sendString:cmd];
}


//open settings
- (void) gotoSettings
{
    NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:appSettings];
}

@end
