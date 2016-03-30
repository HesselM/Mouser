//
//  Client.h
//  Mouser
//
//  Created by Hessel van der Molen on 06/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#ifndef Client_h
#define Client_h

#import <Foundation/Foundation.h>

typedef enum {
    DISCONNECTED,
    NOTREADY,
    CONNECTED
} connStatus_t;


@interface Client : NSObject <NSStreamDelegate> {
    //connection settings
    NSString    *hostAddress;
    NSUInteger   hostPort; 
    
    //streams
    NSInputStream  *inputStream;
    NSOutputStream *outputStream;
}

@property (readonly, nonatomic) NSInteger connectionStatus;

- (void) setAddress: (NSString *) addr withPort: (NSUInteger) port;

- (void) openConnection;
- (void) closeConnection;

- (void) sendString:(NSString *) string;

@end

#endif /* Client_h */
