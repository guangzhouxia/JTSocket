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
#import "JTSocketHeader.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, JTSocketDelegate>
@property (weak, nonatomic) IBOutlet UITextField *contentField;
@property (weak, nonatomic) IBOutlet UITableView *chatTableView;

@property (nonatomic, strong)NSMutableArray<SocketModelProtocol> *chatDatas;

@property (nonatomic, strong)JTSocket *mySockt;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _chatDatas = (NSMutableArray<SocketModelProtocol> *)[NSMutableArray array];
    
    [self socket];
}

- (void)socket
{
    NSString * host = @"192.168.2.78"; //可以用SocketTool创建,http://www.cocoachina.com/bbs/read.php?tid=141721
    NSNumber * port = @45532; //可以用SocketTool创建（创建的时候只要填端口号，ip会自动生成本机ip,推荐端口号大于6000）
    
    self.mySockt = [[JTSocket alloc] initWithHost:host port:port];
    if (self.mySockt == nil) {
        NSLog(@"init Socket -- fail");
    }
    self.mySockt.delegate = self;
}

- (IBAction)connect:(id)sender {
    BOOL connect = [self.mySockt connect];
    if (connect == NO) {
        NSLog(@"connect fail");
    }
}

- (IBAction)close:(id)sender {
    //关闭
    [self.mySockt close];
}

- (IBAction)send:(id)sender {
    if (self.contentField.text.length == 0) {
        NSLog(@"message is not nil");
        return;
    }
    
    if(self.mySockt == nil) {
        NSLog(@"mySocket is nil");
        return;
    }
    
    NSString *msgStr = self.contentField.text;
    
    ChatModel *model = [[ChatModel alloc] init];
    model.type = SocketChatTypeClient;
    model.state = SendStateSending;
    model.content = msgStr;
    [self.chatDatas addObject:model];
    
    NSIndexPath *indexP = [NSIndexPath indexPathForRow:self.chatDatas.count - 1 inSection:0];
    [self.chatTableView insertRowsAtIndexPaths:@[indexP] withRowAnimation:UITableViewRowAnimationFade];
    [self scrollToBottom];
    
    //发送数据
    BOOL sendState = [self.mySockt sendMessage:msgStr];
    
    if (sendState) {
        model.state = SendStateSuccess;
        [self.chatTableView reloadRowsAtIndexPaths:@[indexP] withRowAnimation:UITableViewRowAnimationFade];
        self.contentField.text = nil;
        return;
    }
    
    model.state = SendStateFail;
    [self.chatTableView reloadRowsAtIndexPaths:@[indexP] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - JTSocketDelegate
- (void)socket:(JTMessage *)message handleEvent:(JTSocketEvent)eventCode {
    switch(eventCode) {
            
        case JTSocketEventOpenCompleted:
            
            NSLog(@"Socket连接打开完成");
            
            break;
            
        case JTSocketEventHasBytesAvailable:
        {
            NSLog(@"接收到消息");
            //从服务器接收到的数据
            NSString *recStr = message.content;
            NSLog(@"%@",recStr);
            
            ChatModel *model = [[ChatModel alloc] init];
            model.type = SocketChatTypeServer;
            model.state = SendStateSuccess;
            model.content = recStr;
            
            [self.chatDatas addObject:model];
            NSIndexPath *insertRow = [NSIndexPath indexPathForRow:self.chatDatas.count - 1 inSection:0];
            [self.chatTableView insertRowsAtIndexPaths:@[insertRow] withRowAnimation:UITableViewRowAnimationFade];
            [self scrollToBottom];

        }
            
            break;
            
        case JTSocketEventHasSpaceAvailable:
            
            NSLog(@"可以发送消息");
            break;
            
        case JTSocketEventErrorOccurred:
            
            NSLog(@"连接出现错误");
            
            break;
            
        case JTSocketEventEndEncountered:
            
            NSLog(@"连接结束");
            [self.mySockt close];
            
            break;
            
        default:
            
            break;
            
    }
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
