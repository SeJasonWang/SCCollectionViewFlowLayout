//
//  SCPinHeader.m
//  Higo
//
//  Created by sichenwang on 16/4/8.
//  Copyright © 2016年 Ryan. All rights reserved.
//

#import "SCPinHeader.h"

@implementation SCPinHeader

- (void)setY:(CGFloat)y {
    if (_y != y) {
        _y = y;
        CGRect frame = self.attributes.frame;
        frame.origin.y = y;
        self.attributes.frame = frame;
    }
}

@end
