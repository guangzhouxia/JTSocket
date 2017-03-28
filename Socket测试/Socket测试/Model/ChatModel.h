//
//  ChatModel.h
//  Socket测试
//
//  Created by JT on 17/3/28.
//  Copyright © 2017年 xia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketModelProtocol.h"

@interface ChatModel : NSObject<SocketModelProtocol>

@property (nonatomic, assign)SocketChatType type;
@property (nonatomic, copy)NSString *content;

@property (nonatomic, assign)SendState state;


@end
