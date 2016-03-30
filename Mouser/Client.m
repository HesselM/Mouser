//
//  Client.m
//  Mouser
//
//  Created by Hessel van der Molen on 06/03/16.
//  Copyright © 2016 Van Der Molen Software. All rights reserved.
//

#import "Client.h"

#include <netinet/in.h>
#include <arpa/inet.h>
#include <ifaddrs.h>

@implementation Client

- (void) setAddress: (NSString *) addr withPort: (NSUInteger) port 
{
    hostAddress = addr;
    hostPort    = port;
}

- (void) openConnection;
{
    _connectionStatus = DISCONNECTED;
    
    //adress settings
    struct sockaddr_in addr;
    addr.sin_family         = AF_INET;
    addr.sin_addr.s_addr    = inet_addr([hostAddress UTF8String]);
    addr.sin_port           = htons(hostPort);
    
    //open connection
    short int sockfd        = socket( AF_INET, SOCK_STREAM, 0 );
    fcntl(sockfd, F_SETFL, O_NONBLOCK);
    connect(sockfd, (struct sockaddr*)&addr, sizeof(addr));
    
    //timeout settings
    fd_set fdset;
    FD_ZERO(&fdset);
    FD_SET(sockfd, &fdset);
    
    struct timeval timeval;
    timeval.tv_sec  = 1;        //1 second timeout
    timeval.tv_usec = 0;
    
    //check for timeout..
    if (select(sockfd + 1, NULL, &fdset, NULL, &timeval) == 1)
    {
        int so_error;
        socklen_t len = sizeof(so_error);
        
        getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &so_error, &len);
        
        if (so_error == 0)
            _connectionStatus = CONNECTED;
        else
            _connectionStatus = NOTREADY;
        
    } 
    
    close(sockfd);
    
    if (_connectionStatus == DISCONNECTED) {
        NSLog(@"Server (%@) connection failed!", hostAddress);
        
    } else if (_connectionStatus == NOTREADY) {
        NSLog(@"Server (%@) is not (yet) ready", hostAddress);
        
    } else if (_connectionStatus == CONNECTED) {
        
        //open connection
        //setup connection
        CFReadStreamRef  readStream;
        CFWriteStreamRef writeStream;
        
        CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)hostAddress, (UInt32)hostPort, &readStream, &writeStream);
        inputStream  = (__bridge_transfer NSInputStream  *) (readStream);
        outputStream = (__bridge_transfer NSOutputStream *) (writeStream);
        
        //open streams
        [inputStream  setDelegate:self];
        [outputStream setDelegate:self];
        
        [inputStream  scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        [inputStream  open];
        [outputStream open];                
    }
}

//close connection
- (void) closeConnection;
{
    NSLog(@"CONNECTION CLOSED");
    [self closeStream:inputStream];
    [self closeStream:outputStream];
}

- (void) closeStream: (NSStream *) stream;
{
    [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [stream close];
}

//SEND DATA
- (void) sendString:(NSString *)string
{
    if (![string isEqualToString:@""]) {
        //send data
        NSLog(@"CLIENT-SEND: %@", string);
        NSData *data = [[NSData alloc] initWithData:[string dataUsingEncoding:NSASCIIStringEncoding]];
        [outputStream write:[data bytes] maxLength:[data length]];
    }
}

// STREAM DELEGATE
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    //NSLog(@"stream event %lu", (unsigned long)streamEvent);
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            break;
            
        case NSStreamEventHasBytesAvailable:
            if (theStream == inputStream) {
                //retrieve incoming data
                NSString *recieved = @"";
                while ([inputStream hasBytesAvailable]) {
                    recieved = [NSString stringWithFormat:@"%@%@", recieved, [self readTextFromStream:inputStream]];
                }
                
                //process received message...
            }
            break;
            
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            break;
            
        case NSStreamEventEndEncountered:
            [self closeConnection];
            break;
            
        default:
            break;
            //NSLog(@"Unknown event");
    }
}

- (NSString*) readTextFromStream: (NSInputStream *) stream
{
    uint8_t buffer[1024];
    long len = [stream read:buffer maxLength:sizeof(buffer)];
    if (len > 0) {
        NSString *read = [[NSString alloc] initWithBytes:buffer
                                                  length:len
                                                encoding:NSASCIIStringEncoding];
        return read;
    }
    return nil;
}

@end