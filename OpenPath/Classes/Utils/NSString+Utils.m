//
// Created by Ilya Kucheruavyu on 5/29/15.
// Copyright (c) 2015 Ilya Kucheruavyu. All rights reserved.
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

- (CGSize) textSizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size lineBreakMode:(NSLineBreakMode)lineBreakMode{
    CGSize result;

    if ([self respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        //post-iOS7.0
        NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = lineBreakMode;
        paragraphStyle.alignment = NSTextAlignmentLeft;

        NSDictionary * attributes = @{NSFontAttributeName : font,
                NSParagraphStyleAttributeName : paragraphStyle};

        result = [self boundingRectWithSize:size
                                    options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                 attributes:attributes
                                    context:nil].size;
    }
    else{
        // pre-iOS7.0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        result =[self sizeWithFont:font
                 constrainedToSize:size
                     lineBreakMode:lineBreakMode];
#pragma clang diagnostic pop
    }
    return result;
}

@end