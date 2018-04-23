//
//  HLFileHash.h
//  HLFileHashDemo
//
//  Created by 刘豪亮 on 2016/11/27.
//  Copyright © 2016年 刘豪亮. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLFileHash : NSObject

+ (NSString *)md5HashOfFileAtPath:(NSString *)filePath;
+ (NSString *)sha1HashOfFileAtPath:(NSString *)filePath;
+ (NSString *)sha512HashOfFileAtPath:(NSString *)filePath;

@end
