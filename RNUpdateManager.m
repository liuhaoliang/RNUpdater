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
#import "FileHash.h"

@interface RNUpdateManager()

/**
 更新bundle目录
 */
@property (nonatomic,copy) NSString* updateDir;

/**
 bundle备份目录
 */
@property (nonatomic,copy) NSString* updateBakeDir;

/**
 下载的临时文件夹
 */
@property (nonatomic,copy) NSString* tempZipPath;

/**
 解压文件的临时文件夹
 */
@property (nonatomic,copy) NSString* tempUnzipPath;

/**
 持有查询到的更新信息
 */
@property (nonatomic,copy) NSDictionary* updateResult;

/**
 存在本地plist文件的版本信息
 */
@property (nonatomic,strong) NSDictionary* versionInfo;

/**
 RCTBridge对象
 */
@property (nonatomic,strong) RCTBridge* bridge;

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

/**
 判断是否存在下载过的有效的bundle文件
 */
+ (BOOL)isValidJsBundleExist{
  NSString* target = self.sharedManager.versionInfo[@"target"];
  return [target isEqualToString:CommonUtils.appVersion];
}

/**
 本地下载的bundle文件路径
 */
+ (NSString*)updatedJsBundlePath{
  return [self.sharedManager.updateDir stringByAppendingPathComponent:@"main.jsbundle"];
}

/**
 更新文件夹路径
 */
- (NSString*)updateDir{
  if (!_updateDir) {
    _updateDir = [self dirWithPathName:@"update"];
  }
  return _updateDir;
}

/**
 备份文件夹路径
 */
- (NSString*)updateBakeDir{
  if (!_updateBakeDir) {
    _updateBakeDir = [self dirWithPathName:@"update_bake"];
  }
  return _updateBakeDir;
}

/**
 在document文件目录下创建文件夹并返回路径

 @param name 文件路径名称
 @return 创建的文件夹路径
 */
- (NSString*)dirWithPathName:(NSString*)name{
  NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)[0];
  NSString *dir = [documentDir stringByAppendingPathComponent:name];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:dir]) {
    [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
  }
  return dir;
}

/**
 存储临时下载文件的目录
 */
- (NSString *)tempZipPath {
  if (!_tempZipPath) {
    _tempZipPath = [NSString stringWithFormat:@"%@/\%@.zip",
                      NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0],
                      [NSUUID UUID].UUIDString];
  }
  return _tempZipPath;
}

/**
 临时接呀目录
 */
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


/**
 本地plist存储的路径
 */
- (NSString*)versionInfoPath {
  return [self.updateDir stringByAppendingPathComponent:@"version.plist"];
}

/**
 获取plist存储的版本信息
 */
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


/**
 检查更新文件

 @param bridge RCTBridge对象
 */
+ (void)checkWithBridge:(RCTBridge*)bridge {
  RNUpdateManager.sharedManager.bridge = bridge;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    RNUpdateManager* manager = RNUpdateManager.sharedManager;
    NSDictionary* result = CommonUtils.testData;
    manager.updateResult = result;
    BOOL isEqualNativeVersion = [result[@"target"] isEqualToString:CommonUtils.appVersion];
    if (!isEqualNativeVersion) {
      return ;
    }
    NSInteger serverVersion = [[result[@"version"] description] integerValue];
    NSInteger localVersion = manager.versionInfo[@"version"]?[[manager.versionInfo[@"version"] description] integerValue]:0;
    if (serverVersion<=localVersion) {
      return;
    }
    NSString* updateUrl = result[@"url"];
    [manager downloadWithUrl:updateUrl];
  });
}

/**
 下载更新文件

 @param url 服务器保存的下载链接
 */
- (void)downloadWithUrl:(NSString*)url {
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
  AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
  NSURL *URL = [NSURL URLWithString:url];
  NSURLRequest *request = [NSURLRequest requestWithURL:URL];
  NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
    //获取下载进度
    NSLog(@"Progress is %f", downloadProgress.fractionCompleted);
  } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
    //自定义下载路径
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


/**
 处理下载的文zip件

 @param path 下载路径
 */
- (void)settleFileWithPath:(NSString*)path {
  NSString* hashCode = [FileHash md5HashOfFileAtPath:path];
  if (![hashCode isEqualToString:self.updateResult[@"hash"]]) {
    //删除临时下载文件夹
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    return;
  }
  
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
        if (self.bridge) {
          NSURL* bundleURL = [NSURL URLWithString:self.class.updatedJsBundlePath];
          [self.bridge setValue:bundleURL forKey:@"bundleURL"];
          [self.bridge reload];
        }
      }
    }
  }
}

@end
