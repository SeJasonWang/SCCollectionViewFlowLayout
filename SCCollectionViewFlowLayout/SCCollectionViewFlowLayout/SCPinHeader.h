//
//  SCPinHeader.h
//  Higo
//
//  Created by sichenwang on 16/4/8.
//  Copyright © 2016年 Ryan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SCPinHeader : NSObject

@property (nonatomic, strong) UICollectionViewLayoutAttributes *attributes;
@property (nonatomic, assign) CGFloat startY;
@property (nonatomic, assign) CGFloat endY;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGRect rect;

@end
