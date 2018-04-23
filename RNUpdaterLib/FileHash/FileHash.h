//
//  FileHash.h
//  RNUpdater
//
//  Created by 刘豪亮 on 2017/11/27.
//  Copyright © 2017年 RNUpdater. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileHash : NSObject

+ (NSString *)md5HashOfFileAtPath:(NSString *)filePath;
+ (NSString *)sha1HashOfFileAtPath:(NSString *)filePath;
+ (NSString *)sha512HashOfFileAtPath:(NSString *)filePath;

@end
