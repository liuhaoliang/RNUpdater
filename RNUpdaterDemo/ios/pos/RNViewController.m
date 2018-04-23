//
//  RNViewController.m
//  RNUpdater
//
//  Created by 刘豪亮 on 2018/4/4.
//  Copyright © 2018年 RNUpdater. All rights reserved.
//

#import "RNViewController.h"
#import <React/RCTRootView.h>
#import <React/RCTBundleURLProvider.h>

@interface RNViewController ()
@property (nonatomic,copy) NSString* moduleName;
@property (nonatomic,strong) NSDictionary* initialProperties;

@end

@implementation RNViewController

- (instancetype)initWithModuleName:(NSString *)moduleName
                 initialProperties:(NSDictionary *)initialProperties{
    self = [super init];
    if (self) {
        self.moduleName = moduleName;
        self.initialProperties = initialProperties;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}
    
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}
    
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURL *jsCodeLocation;
#ifdef DEBUG
//    jsCodeLocation = [NSURL URLWithString:@"http://localhost:8081/index.bundle?platform=ios"];
    jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:nil];
#else
    jsCodeLocation = [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
    RCTBridge* bridge = [[RCTBridge alloc] initWithBundleURL:jsCodeLocation moduleProvider:nil launchOptions:nil];
    RCTRootView *rootView = [[RCTRootView alloc] initWithBridge:bridge
                                                     moduleName:self.moduleName
                                              initialProperties:self.initialProperties];
    self.view = rootView;
}
    
    
    
    

@end
