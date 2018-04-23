//
//  RNUpdater.h
//  pos
//
//  Created by 刘豪亮 on 2018/4/11.
//  Copyright © 2018年 RNUpdater. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RNUpdater : NSObject

+ (RNUpdater *)sharedManager;

/**
 判断是否存在下载过的有效的bundle文件
 */
+ (BOOL)isValidJsBundleExist;

/**
 本地下载的bundle文件路径
 */
+ (NSString*)updatedJsBundlePath;

/**
 检查更新文件
 
 @param bridge RCTBridge对象
 */
+ (void)checkWithBridge:(id)bridge;
@end
