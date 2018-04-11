//
//  CommonUtils.m
//  pos
//
//  Created by 刘豪亮 on 2018/4/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "CommonUtils.h"

@implementation CommonUtils

+ (NSString*)appVersion {
  NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
  NSString *app_Version = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
  return app_Version;
}

- (NSDictionary*)testData {
  NSString* path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"geojson"];
  NSData *jsonData = [NSData dataWithContentsOfFile:path];
  NSError *err;
  NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData
                                                       options:NSJSONReadingMutableContainers
                                                         error:&err];
  return err?@{}:json;
}

@end
