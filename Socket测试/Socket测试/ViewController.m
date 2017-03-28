//
//  ViewController.m
//  Socket测试
//
//  Created by JT on 17/1/10.
//  Copyright © 2017年 xia. All rights reserved.
//

#import "ViewController.h"
#import <netdb.h>
#import <arpa/inet.h>
#import "SocketModelProtocol.h"
#import "ChatModel.h"

@interface ViewController ()<NSStreamDelegate, UITableViewDelegate, UITableViewDataSource>
{
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
}
@property (weak, nonatomic) IBOutlet UITextField *contentLabel;
@property (weak, nonatomic) IBOutlet UITableView *chatTableView;

@property (nonatomic, strong)NSMutableArray<SocketModelProtocol> *chatDatas;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _chatDatas = (NSMutableArray<SocketModelProtocol> *)[NSMutableArray array];
}

- (IBAction)connect:(id)sender {
    [self socket];
}

- (IBAction)close:(id)sender {
    //关闭输入输出流
    
    [_inputStream close];
    
    [_outputStream close];
    
    //从主运行循环移除
    
    [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
}

- (IBAction)send:(id)sender {
    if (self.contentLabel.text.length > 0) {
        [self sendData:self.contentLabel.text];
    }
}


- (void)socket
{
    NSString * host = @"192.168.2.78"; //可以用SocketTool创建,http://www.cocoachina.com/bbs/read.php?tid=141721
    NSNumber * port = @45532; //可以用SocketTool创建（创建的时候只要填端口号，ip会自动生成本机ip）
    // 创建 socket
    int socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
    if (-1 == socketFileDescriptor) {
        NSLog(@"创建失败");
        return;
    }
    // 获取 IP 地址
    struct hostent * remoteHostEnt = gethostbyname([host UTF8String]);
    if (NULL == remoteHostEnt) {
        close(socketFileDescriptor);
        NSLog(@"%@",@"无法解析服务器的主机名");
        return;
    }
    struct in_addr * remoteInAddr = (struct in_addr *)remoteHostEnt->h_addr_list[0];
    // 设置 socket 参数
    struct sockaddr_in socketParameters;
    socketParameters.sin_family = AF_INET; //AF_INET对应ipv4（32位） 、AF_INET6对应ipv6
    socketParameters.sin_addr = *remoteInAddr;
    socketParameters.sin_port = htons([port intValue]);
    // 连接 socket
    int ret = connect(socketFileDescriptor, (struct sockaddr *) &socketParameters, sizeof(socketParameters));
    if (ret == -1) {
        close(socketFileDescriptor);
        NSLog(@"连接失败");
        return;
    }
    NSLog(@"连接成功");
    
    CFReadStreamRef readStream;
    
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, [port intValue], &readStream, &writeStream);
    
    //把C语言的输入输出流转化成OC对象
    
    _inputStream = (__bridge NSInputStream *)(readStream);
    
    _outputStream = (__bridge NSOutputStream *)(writeStream);
    
    //设置代理
    
    _inputStream.delegate=self;
    
    _outputStream.delegate=self;
    
    //把输入输入流添加到主运行循环
    
    //不添加主运行循环 代理有可能不工作
    
    [_inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    //打开输入输出流
    
    [_inputStream open];
    
    [_outputStream open];
}

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    
    NSLog(@"%@－－－code:%lu",[NSThread currentThread],(unsigned long)eventCode);
    
    //NSStreamEventOpenCompleted = 1UL << 0,//输入输出流打开完成//NSStreamEventHasBytesAvailable = 1UL << 1,//有字节可读//NSStreamEventHasSpaceAvailable = 1UL << 2,//可以发放字节//NSStreamEventErrorOccurred = 1UL << 3,//连接出现错误//NSStreamEventEndEncountered = 1UL << 4//连接结束
    
    switch(eventCode) {
            
        case NSStreamEventOpenCompleted:
            
            NSLog(@"输入输出流打开完成");
            
            break;
            
        case NSStreamEventHasBytesAvailable:
            
            NSLog(@"有字节可读");
            
            [self readData];
            
            break;
            
        case NSStreamEventHasSpaceAvailable:
            
            NSLog(@"可以发送字节");
            break;
            
        case NSStreamEventErrorOccurred:
            
            NSLog(@"连接出现错误");
            
            break;
            
        case NSStreamEventEndEncountered:
            
            NSLog(@"连接结束");
            
            //关闭输入输出流
            
            [_inputStream close];
            
            [_outputStream close];
            
            //从主运行循环移除
            
            [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            
            [_outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            
            break;
            
        default:
            
            break;
            
    }
    
}


-(void)readData{
    
    //建立一个缓冲区 可以放1024个字节
    
    uint8_t buf[1024];
    
    //返回实际装的字节数
    
    NSInteger len = [_inputStream read:buf maxLength:sizeof(buf)];
    
    //把字节数组转化成字符串
    
    NSData *data =[NSData dataWithBytes:buf length:len];
    
    //从服务器接收到的数据
    
    NSString *recStr =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"%@",recStr);
    
    ChatModel *model = [[ChatModel alloc] init];
    model.type = SocketChatTypeServer;
    model.state = SendStateSuccess;
    model.content = recStr;
    
    [self.chatDatas addObject:model];
    NSIndexPath *insertRow = [NSIndexPath indexPathForRow:self.chatDatas.count - 1 inSection:0];
    [self.chatTableView insertRowsAtIndexPaths:@[insertRow] withRowAnimation:UITableViewRowAnimationFade];
    
}

-(BOOL)sendData:(NSString *)msgStr{
    
    if (msgStr.length == 0) {
        return NO;
    }
    
    NSLog(@"%@",msgStr);
    ChatModel *model = [[ChatModel alloc] init];
    model.type = SocketChatTypeClient;
    model.state = SendStateSending;
    model.content = msgStr;
    [self.chatDatas addObject:model];
    
    NSIndexPath *indexP = [NSIndexPath indexPathForRow:self.chatDatas.count - 1 inSection:0];
    [self.chatTableView insertRowsAtIndexPaths:@[indexP] withRowAnimation:UITableViewRowAnimationFade];
    
    //把Str转成NSData10
    NSData *data =[msgStr dataUsingEncoding:NSUTF8StringEncoding];
    
    //发送数据
    NSInteger writen = [_outputStream write:data.bytes maxLength:data.length];
    
    if (writen) {
        model.state = SendStateSuccess;
        [self.chatTableView reloadRowsAtIndexPaths:@[indexP] withRowAnimation:UITableViewRowAnimationFade];
        self.contentLabel.text = nil;
        return YES;
    }
    
    model.state = SendStateFail;
    [self.chatTableView reloadRowsAtIndexPaths:@[indexP] withRowAnimation:UITableViewRowAnimationFade];
    
    return NO;
}

#pragma mark - tableView delegate / dataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chatDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseId = @"cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    
    id<SocketModelProtocol> model = self.chatDatas[indexPath.row];
    switch (model.type) {
        case SocketChatTypeServer:
        {
            cell.textLabel.textAlignment = NSTextAlignmentRight;
            cell.textLabel.textColor = [UIColor blueColor];
            cell.textLabel.text = model.content;
        }
            break;
        case SocketChatTypeClient:
        {
            cell.textLabel.textAlignment = NSTextAlignmentLeft;
            cell.textLabel.textColor = [UIColor blackColor];
            if (model.state == SendStateSending) {
                cell.textLabel.text = [NSString stringWithFormat:@"%@ ...",model.content];
            }else if(model.state == SendStateFail) {
                cell.textLabel.textColor = [UIColor redColor];
                cell.textLabel.text = model.content;
            }else {
                cell.textLabel.text = model.content;
            }
        }
            break;
        default:
            break;
    }
    return cell;
}

#pragma mark - private func
//滚动视图到底部
- (void)scrollToBottom
{
    NSInteger numberOfRows = [self.chatTableView numberOfRowsInSection:0];
    if (numberOfRows > 0) {
        [self.chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows-1 inSection:0]
                             atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

@end
