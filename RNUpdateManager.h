//
//  RNUpdateManager.h
//  pos
//
//  Created by 刘豪亮 on 2018/4/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTRootView.h>

@interface RNUpdateManager : NSObject
+ (RNUpdateManager *)sharedManager;
+ (BOOL)isValidJsBundleExist;
+ (NSString*)updatedJsBundlePath;
+ (void)checkWithBridge:(RCTBridge*)bridge;
@end
