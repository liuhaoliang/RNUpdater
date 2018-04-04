//
//  RNViewController.h
//  Jian24
//
//  Created by 刘豪亮 on 2017/11/27.
//  Copyright © 2017年 Jian24. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RNViewController : UIViewController
- (instancetype)initWithModuleName:(NSString *)moduleName
                 initialProperties:(NSDictionary *)initialProperties;
@end
