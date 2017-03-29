//
//  JTSocket.m
//  Socket测试
//
//  Created by YS-160408B on 17/3/28.
//  Copyright © 2017年 shunke. All rights reserved.
//

#import "JTSocket.h"
#import <netdb.h>
#import "JTMessage.h"

@interface JTSocket ()<NSStreamDelegate>
{
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
    
    NSString *_host;
    NSNumber *_port;
    int _socketFileDescriptor;
    struct sockaddr_in _socketParameters;
}

@end

@implementation JTSocket

- (instancetype)initWithHost:(NSString *)host port:(NSNumber *)port {
    if (self = [super init]) {
        // 创建 socket
        int socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
        if (socketFileDescriptor == -1) {
            NSLog(@"creating socket descriptor is fail");
            return nil;
        }
        
        _host = host;
        _port = port;
        _socketFileDescriptor = socketFileDescriptor;
    }
    return self;
}

- (BOOL)connect {
    
    // 获取 IP 地址
    struct hostent * remoteHostEnt = gethostbyname([_host UTF8String]);
    if (remoteHostEnt == NULL) {
        close(_socketFileDescriptor);
        NSLog(@"gethostbyname fail");
        return NO;
    }
    
    
    struct in_addr * remoteInAddr = (struct in_addr *)remoteHostEnt->h_addr_list[0];
    // 设置 socket 参数
    struct sockaddr_in socketParameters;
    socketParameters.sin_family = AF_INET; //AF_INET对应ipv4（32位） 、AF_INET6对应ipv6
    socketParameters.sin_addr = *remoteInAddr;
    socketParameters.sin_port = htons([_port intValue]);
    
    _socketParameters = socketParameters;
    
    // 连接 socket
    int ret = connect(_socketFileDescriptor, (struct sockaddr *) &_socketParameters, sizeof(_socketParameters));
    if (ret == -1) {
        close(_socketFileDescriptor);
        NSLog(@"connect fail");
        return NO;
    }
    
    CFReadStreamRef readStream;
    
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)_host, [_port intValue], &readStream, &writeStream);
    
    //把C语言的输入输出流转化成OC对象
    
    _inputStream = (__bridge NSInputStream *)(readStream);
    
    _outputStream = (__bridge NSOutputStream *)(writeStream);
    
    //设置代理
    
    _inputStream.delegate = self;
    
    _outputStream.delegate = self;
    
    //把输入输入流添加到主运行循环
    
    //不添加主运行循环 代理有可能不工作
    
    [_inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    //打开输入输出流
    
    [_inputStream open];
    
    [_outputStream open];
    
    return YES;
}

- (BOOL)sendMessage:(NSString *)message {
    
    if (_outputStream == nil) {
        NSLog(@"not connect...");
        return NO;
    }
    
    if (message.length == 0) {
        return NO;
    }
    
    //把Str转成NSData10
    NSData *data =[message dataUsingEncoding:NSUTF8StringEncoding];
    
    //发送数据
    NSInteger writen = [_outputStream write:data.bytes maxLength:data.length];
    
    if (writen) {
        return YES;
    }
    return NO;
}

- (void)close {
    //关闭输入输出流
    
    [_inputStream close];
    
    [_outputStream close];
    
    //从主运行循环移除
    
    [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    _inputStream = nil;
    _outputStream = nil;
}

#pragma mark - streamDelegate
-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    
    JTMessage *message = nil;
    
    switch(eventCode) {
        case NSStreamEventOpenCompleted:
            //打开连接成功
            break;
            
        case NSStreamEventHasBytesAvailable:
            //有数据可读
            message = [self getMessageFromStream:aStream];
            break;
            
        case NSStreamEventHasSpaceAvailable:
            //可以发送消息
            break;
            
        case NSStreamEventErrorOccurred:
            //连接出现错误
            break;
            
        case NSStreamEventEndEncountered:
            //连接结束
            //关闭输入输出流
            [self close];
            break;
        default:
            break;
    }
    
    JTSocketEvent event = [self socketEventWithStreamEvent:eventCode];
    if ([self.delegate respondsToSelector:@selector(socket:handleEvent:)]) {
        [self.delegate socket:message handleEvent:event];
    }
    
}

-(JTMessage *)getMessageFromStream:(NSStream *)stream {
    
    //建立一个缓冲区 可以放1024个字节
    
    uint8_t buf[1024];
    
    //返回实际装的字节数
    
    NSInteger len = [_inputStream read:buf maxLength:sizeof(buf)];
    
    if (len <= 0) {
        return nil;
    }
    //把字节数组转化成字符串
    
    NSData *data = [NSData dataWithBytes:buf length:len];
    
    //从服务器接收到的数据
    
    NSString *recStr =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    JTMessage *message = [[JTMessage alloc] init];
    message.content = recStr;
    
    return message;
}

- (JTSocketEvent)socketEventWithStreamEvent:(NSStreamEvent)streamEvent {
    JTSocketEvent event = JTSocketEventNone;
    switch (streamEvent) {
        case NSStreamEventNone:
            event = JTSocketEventNone;
            break;
        case NSStreamEventOpenCompleted:
            event = JTSocketEventOpenCompleted;
            break;
        case NSStreamEventHasBytesAvailable:
            event = JTSocketEventHasBytesAvailable;
            break;
        case NSStreamEventHasSpaceAvailable:
            event = JTSocketEventHasSpaceAvailable;
            break;
        case NSStreamEventErrorOccurred:
            event = JTSocketEventErrorOccurred;
            break;
        case NSStreamEventEndEncountered:
            event = JTSocketEventEndEncountered;
            break;
        default:
            break;
    }
    return event;
}


@end
