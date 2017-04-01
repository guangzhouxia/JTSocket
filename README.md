# JTSocket
#### socket connect
### Socket 是在应用层和传输层之间的一个抽象层，用于进程之间的通信。（鉴于网上有很多科普，这里就大概介绍下，然后主要还是介绍怎么用代码建立起连接）

####socket在TCP/IP网络结构中的位置：

![1334044170_5136.jpg](http://upload-images.jianshu.io/upload_images/3346554-0f81660c9f0659c8.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

####可以看出 Socket是处于传输层和应用层中间的一层抽象，主要提供网络之间主机进程的通讯。而为了能使网络主机进程之间能够通讯和识别不同的进程，就需要（ip＋协议＋端口号）来标识。

####JTSocket是我根据Socket通讯建立和断开流程的一个封装，主要是帮助想了解Socket的人对Socket通讯的建立有个直观的了解。)
### Socket在客户端涉及到的操作主要有：1.创建Socket －>2.连接（connect）－>3.通讯消息（send发消息,代理接收消息）－>4.关闭（close）.
#### 使用方法：
#### 0.导入头文件
```
#import "JTSocketHeader.h"
```
#### 1.初始化
  ```Object-C
    NSString * host = @"192.168.2.78"; //可以用SocketTool创建,http://www.cocoachina.com/bbs/read.php?tid=141721
    NSNumber * port = @45532; //可以用SocketTool创建（创建的时候只要填端口号，ip会自动生成本机ip,推荐端口号大于6000）
    
    self.mySockt = [[JTSocket alloc] initWithHost:host port:port];
    if (self.mySockt == nil) {
        NSLog(@"init Socket -- fail");
    }
    self.mySockt.delegate = self;
  ```
#### 2.连接
```
[self.mySockt connect]
```
#### 3.发送消息与监听
```
//发送
[self.mySockt sendMessage:msgStr];
//监听代理
- (void)socket:(JTMessage *)message handleEvent:(JTSocketEvent)eventCode;
```
#### 4.关闭连接
```
[self.mySockt close];
```
测试：推荐使用SocketTool(http://www.cocoachina.com/bbs/read.php?tid=141721)，可以在本机模拟进行Socket通讯
![](Display/display.png)
