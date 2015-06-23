//
// Created by Ilya Kucheruavyu on 5/19/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>

@interface IndicatorView : UIView

@end

@interface UIView(Indicator)

-(void)showLoading;
-(void)hideLoading;

@end