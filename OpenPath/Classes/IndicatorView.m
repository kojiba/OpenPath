//
// Created by Ilya Kucheruavyu on 5/19/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "IndicatorView.h"


@implementation IndicatorView {

}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithFrame:
                CGRectMake((frame.size.width / 2) - 10,
                           (frame.size.height / 2) - 10,
                           20, 20)];
        [self addSubview:view];
        [self setBackgroundColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.6]];
        [self setUserInteractionEnabled:NO];
        [view startAnimating];
    }
    return self;
}


@end

@implementation UIView(Indicator)

static IndicatorView* currentIndicator = nil;

-(void)showLoading {
    [UIView animateWithDuration:0.2 animations:^{
        IndicatorView *view = [[IndicatorView alloc] initWithFrame:self.frame];
        view.tag = 777;
        currentIndicator = view;
        [self addSubview:view];
    }];

}

- (void)hideLoading {
    if(currentIndicator != nil) {
        [UIView animateWithDuration:0.2 animations:^{
            [currentIndicator removeFromSuperview];
        }];
    }
}


@end