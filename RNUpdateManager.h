//
//  RNUpdateManager.h
//  pos
//
//  Created by 刘豪亮 on 2018/4/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RNUpdateManager : NSObject
+ (RNUpdateManager *)sharedManager;
- (void)check;
- (void)download;
@end