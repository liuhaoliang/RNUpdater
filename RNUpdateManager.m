//
//  RNUpdateManager.m
//  pos
//
//  Created by 刘豪亮 on 2018/4/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "RNUpdateManager.h"
#import "SSZipArchive.h"
#import "AFURLSessionManager.h"

@interface RNUpdateManager()
@property (nonatomic,copy) NSString* updateDir;
@property (nonatomic,copy) NSString* tempZipPath;
@property (nonatomic,copy) NSString* tempUnzipPath;

@property (nonatomic,strong) NSDictionary* updateInfo;
@end

@implementation RNUpdateManager

+ (RNUpdateManager *)sharedManager{
  static RNUpdateManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[RNUpdateManager alloc] init];
  });
  return sharedInstance;
}

- (NSString*)updateDir{
  if (!_updateDir) {
    _updateDir = [self dirWithPathName:@"update"];
  }
  return _updateDir;
}

- (NSString*)dirWithPathName:(NSString*)name{
  NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)[0];
  NSString *dir = [documentDir stringByAppendingPathComponent:name];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:dir]) {
    [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
  }
  return dir;
}

- (NSString *)tempZipPath {
  if (!_tempZipPath) {
    _tempZipPath = [NSString stringWithFormat:@"%@/\%@.zip",
                      NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0],
                      [NSUUID UUID].UUIDString];
  }
  return _tempZipPath;
}

- (NSString *)tempUnzipPath {
  if (!_tempUnzipPath) {
    NSString *path = [NSString stringWithFormat:@"%@/\%@",
                      NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0],
                      [NSUUID UUID].UUIDString];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:url
                             withIntermediateDirectories:YES
                                              attributes:nil
                                                   error:&error];
    if (error) {
      _tempUnzipPath = nil;
    }else{
      _tempUnzipPath = url.path;
    }
  }
  return _tempUnzipPath;
}

- (NSDictionary*)updateInfo{
  if (!_updateInfo) {
    NSString *plistPath = [self.updateDir stringByAppendingPathComponent:@"update.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:plistPath]) {
      [fileManager createFileAtPath:plistPath contents:nil attributes:nil];
    }
    _updateInfo = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
  }
  return _updateInfo;
}

- (void)check {
  NSString* serverVersion = @"3";
  NSString* localVersion = self.updateInfo[@"localVersion"];
  if (localVersion && [localVersion integerValue]>=[serverVersion integerValue]) {
    return;
  }
  [self download];
}

- (void)download {
  NSString* url = @"http://lc-xHhJT28m.cn-n1.lcfile.com/51f9ab4bbeb55abd1f3e.zip";
  //根据url下载相关文件
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
  AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
  NSURL *URL = [NSURL URLWithString:url];
  NSURLRequest *request = [NSURLRequest requestWithURL:URL];
  NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
    //获取下载进度
    NSLog(@"Progress is %f", downloadProgress.fractionCompleted);
  } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
    return [NSURL fileURLWithPath:self.tempZipPath];
  } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
    if(error){
      NSLog(@"%@",error);
    }else{
      [self settleFileWithPath:filePath.path];
    }
  }];
  [downloadTask resume];
}

- (void)settleFileWithPath:(NSString*)path {
  BOOL success = [SSZipArchive unzipFileAtPath:path toDestination:self.tempUnzipPath];
  //删除临时下载文件夹
  [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
  if (success) {
    NSError* error = nil;
    //删除更新目录文件
    [[NSFileManager defaultManager] removeItemAtPath:self.updateDir error:&error];
    if (!error) {
      //移动解压文件到更新目录文件
      [[NSFileManager defaultManager] moveItemAtPath:self.tempUnzipPath toPath:self.updateDir error:&error];
      if (!error) {
        //创建版本信息
//        NSString* filePath  = [self getVersionPlistPath];
//        [dictionary writeToFile:filePath atomically:YES];
        ;
      }
    }
  }
}

@end
