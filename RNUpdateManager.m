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
#import "CommonUtils.h"

@interface RNUpdateManager()
@property (nonatomic,copy) NSString* updateDir;
@property (nonatomic,copy) NSString* tempZipPath;
@property (nonatomic,copy) NSString* tempUnzipPath;
@property (nonatomic,copy) NSDictionary* updateResult;
@property (nonatomic,strong) NSDictionary* versionInfo;
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

+ (BOOL)isValidJsBundleExist{
  NSString* target = self.sharedManager.versionInfo[@"target"];
  return [target isEqualToString:CommonUtils.appVersion];
}

+ (NSString*)updatedJsBundlePath{
  return [self.sharedManager.updateDir stringByAppendingPathComponent:@"main.jsbundle"];
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

- (NSString*)versionInfoPath {
  return [self.updateDir stringByAppendingPathComponent:@"version.plist"];
}

- (NSDictionary*)versionInfo{
  if (!_versionInfo) {
    NSString *plistPath = self.versionInfoPath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:plistPath]) {
      [fileManager createFileAtPath:plistPath contents:nil attributes:nil];
    }
    _versionInfo = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
  }
  return _versionInfo;
}

+ (void)check {
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    RNUpdateManager* this = RNUpdateManager.sharedManager;
    NSDictionary* result = CommonUtils.testData;
    this.updateResult = result;
    BOOL isEqualNativeVersion = [result[@"target"] isEqualToString:CommonUtils.appVersion];
    if (!isEqualNativeVersion) {
      return ;
    }
    NSInteger serverVersion = [[result[@"version"] description] integerValue];
    NSInteger localVersion = this.versionInfo[@"version"]?[[this.versionInfo[@"version"] description] integerValue]:0;
    if (serverVersion<=localVersion) {
      return;
    }
    NSString* updateUrl = result[@"updateUrl"];
    [this downloadWithUrl:updateUrl];
  });
}

- (void)downloadWithUrl:(NSString*)url {
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
        [self.updateResult writeToFile:self.versionInfoPath atomically:YES];
      }
    }
  }
}

@end
