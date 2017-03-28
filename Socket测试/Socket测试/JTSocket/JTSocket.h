//
//  JTSocket.h
//  Socket测试
//
//  Created by YS-160408B on 17/3/28.
//  Copyright © 2017年 shunke. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, JTSocketEvent) {
    JTSocketEventNone = 0,
    JTSocketEventOpenCompleted = 1UL << 0,
    JTSocketEventHasBytesAvailable = 1UL << 1,
    JTSocketEventHasSpaceAvailable = 1UL << 2,
    JTSocketEventErrorOccurred = 1UL << 3,
    JTSocketEventEndEncountered = 1UL << 4
};

@class JTMessage;
@protocol JTSocketDelegate <NSObject>

-(void)socket:(JTMessage *)message handleEvent:(JTSocketEvent)eventCode;

@end

@interface JTSocket : NSObject

@property (nonatomic, weak)id<JTSocketDelegate> delegate;

- (instancetype)initWithHost:(NSString *)host port:(NSNumber *)port;

- (BOOL)connect;
- (void)close;

- (BOOL)sendMessage:(NSString *)message;

@end
