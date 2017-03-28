//
//  SocketModelProtocol.h
//  Socket测试
//
//  Created by JT on 17/3/28.
//  Copyright © 2017年 xia. All rights reserved.
//

#ifndef SocketModelProtocol_h
#define SocketModelProtocol_h

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    SocketChatTypeClient,
    SocketChatTypeServer,
} SocketChatType;

typedef enum : NSUInteger {
    SendStateSending,
    SendStateSuccess,
    SendStateFail,
} SendState;

@protocol SocketModelProtocol <NSObject>

@required
- (NSString *)content;
- (SocketChatType)type;

- (void)setContent:(NSString *)content;
- (void)setType:(SocketChatType)type;

@optional
- (SendState)state;
- (void)setState:(SendState)state;

@end

#endif /* SocketModelProtocol_h */
