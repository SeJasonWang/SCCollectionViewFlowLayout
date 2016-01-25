//
//  SCCollectionViewFlowLayout.m
//  SCCollectionViewFlowLayout
//
//  Created by sichenwang on 16/1/22.
//  Copyright © 2016年 sichenwang. All rights reserved.
//

#import "SCCollectionViewFlowLayout.h"

static const CGSize kSCDefaultItemSize               = {50.0, 50.0};
static const CGFloat kSCDefaultLineSpacing           = 0.0;
static const CGFloat kSCDefaultInteritemSpacing      = 0.0;
static const UIEdgeInsets kSCDefaultSectionInset     = {0.0, 0.0, 0.0, 0.0};
static const CGFloat kSCDefaultHeaderReferenceHeight = 0.0;
static const CGFloat kSCDefaultFooterReferenceHeight = 0.0;
static const UIEdgeInsets kSCDefaultHeaderInset      = {0.0, 0.0, 0.0, 0.0};
static const UIEdgeInsets kSCDefaultFooterInset      = {0.0, 0.0, 0.0, 0.0};

NSString *const SCCollectionElementKindSectionHeader = @"SCCollectionElementKindSectionHeader";
NSString *const SCCollectionElementKindSectionFooter = @"SCCollectionElementKindSectionFooter";

@interface SCCollectionViewFlowLayout()

@property (nonatomic, weak) id<SCCollectionViewDelegateFlowLayout> delegate;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, strong) NSMutableArray *attributesArray;

@end

@implementation SCCollectionViewFlowLayout

#pragma mark - Override Methods
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(self.collectionView.bounds)) {
        return YES;
    } else {
        return NO;
    }
}

- (void)prepareLayout {
    [super prepareLayout];
    
    NSInteger numOfSections = [self.collectionView numberOfSections];
    if (numOfSections) {
        self.delegate = (id<SCCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
        self.y = 0.0;
        self.attributesArray = [NSMutableArray array];
        for (NSUInteger section = 0; section < numOfSections; section++) {
            [self layoutHeadersInSection:section];
            [self layoutItemsInSection:section];
            [self layoutFootersInSection:section];
        }
    }
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake([UIScreen mainScreen].bounds.size.width, self.y);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (UICollectionViewLayoutAttributes *attributes in self.attributesArray) {
        if (CGRectIntersectsRect(rect, attributes.frame)) {
            [mutableArray addObject:attributes];
        }
    }
    return [mutableArray copy];
}

#pragma mark - Private Methods

- (void)layoutHeadersInSection:(NSInteger)section {
    CGFloat h = [self referenceHeightForHeaderInSection:section];
    if (h) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:SCCollectionElementKindSectionHeader withIndexPath:indexPath];
        UIEdgeInsets inset = [self insetForHeaderInSection:section];
        CGFloat x = inset.left;
        CGFloat y = self.y + inset.top;
        CGFloat w = [UIScreen mainScreen].bounds.size.width - inset.left - inset.right;
        attributes.frame = CGRectMake(x, y, w, h);
        attributes.zIndex = 10;
        self.y = y + h + inset.bottom;
        [self.attributesArray addObject:attributes];
    }
}

- (void)layoutItemsInSection:(NSInteger)section {
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
    if (numberOfItems) {
        CGFloat lineSpacing = [self lineSpacingForSectionAtIndex:section];
        CGFloat interitemSpacing = [self interitemSpacingForSectionAtIndex:section];
        UIEdgeInsets inset = [self insetForSectionAtIndex:section];
        self.y += inset.top;
        for (NSInteger item = 0; item < numberOfItems; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            CGSize size = [self sizeForItemAtIndexPath:indexPath];
            if (item == 0) {
                attributes.size = size;
                CGRect frame = attributes.frame;
                frame.origin.x = inset.left;
                frame.origin.y = self.y;
                attributes.frame = frame;
                self.y = CGRectGetMaxY(attributes.frame);
            } else {
                UICollectionViewLayoutAttributes *prevAttributes = self.attributesArray.lastObject;
                NSInteger x = CGRectGetMaxX(prevAttributes.frame);
                if (x + interitemSpacing + size.width <= self.collectionViewContentSize.width - inset.right) {
                    attributes.size = size;
                    CGRect frame = attributes.frame;
                    frame.origin.x = x + interitemSpacing;
                    frame.origin.y = prevAttributes.frame.origin.y;
                    attributes.frame = frame;
                    if (size.height > prevAttributes.size.height) {
                        self.y = CGRectGetMaxY(attributes.frame);
                    }
                } else {
                    attributes.size = size;
                    CGRect frame = attributes.frame;
                    frame.origin.x = inset.left;
                    frame.origin.y = self.y + lineSpacing;
                    attributes.frame = frame;
                    self.y = CGRectGetMaxY(attributes.frame);
                }
            }
            [self.attributesArray addObject:attributes];
        }
        self.y += inset.bottom;
    }
}

- (void)layoutFootersInSection:(NSInteger)section {
    CGFloat h = [self referenceHeightForFooterInSection:section];
    if (h) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:SCCollectionElementKindSectionFooter withIndexPath:indexPath];
        UIEdgeInsets inset = [self insetForFooterInSection:section];
        CGFloat x = inset.left;
        CGFloat y = self.y + inset.top;
        CGFloat w = [UIScreen mainScreen].bounds.size.width - inset.left - inset.right;
        attributes.frame = CGRectMake(x, y, w, h);
        attributes.zIndex = 10;
        self.y = y + h + inset.bottom;
        [self.attributesArray addObject:attributes];
    }
}

#pragma mark - Getter

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        return [self.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
    } else if (!CGSizeEqualToSize(self.itemSize, CGSizeZero)) {
        return self.itemSize;
    } else {
        return kSCDefaultItemSize;
    }
}

- (CGFloat)lineSpacingForSectionAtIndex:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:lineSpacingForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self lineSpacingForSectionAtIndex:section];
    } else if (self.lineSpacing) {
        return self.lineSpacing;
    } else {
        return kSCDefaultLineSpacing;
    }
}

- (CGFloat)interitemSpacingForSectionAtIndex:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:interitemSpacingForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self interitemSpacingForSectionAtIndex:section];
    } else if (self.interitemSpacing) {
        return self.interitemSpacing;
    } else {
        return kSCDefaultInteritemSpacing;
    }
}

- (UIEdgeInsets)insetForSectionAtIndex:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
    } else if (!UIEdgeInsetsEqualToEdgeInsets(self.sectionInset, UIEdgeInsetsZero)) {
        return self.sectionInset;
    } else {
        return kSCDefaultSectionInset;
    }
}

- (CGFloat)referenceHeightForHeaderInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:referenceHeightForHeaderInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self referenceHeightForHeaderInSection:section];
    } else if (self.headerReferenceHeight) {
        return self.headerReferenceHeight;
    } else {
        return kSCDefaultHeaderReferenceHeight;
    }
}

- (CGFloat)referenceHeightForFooterInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:referenceHeightForFooterInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self referenceHeightForFooterInSection:section];
    } else if (self.footerReferenceHeight) {
        return self.footerReferenceHeight;
    } else {
        return kSCDefaultFooterReferenceHeight;
    }
}

- (UIEdgeInsets)insetForHeaderInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForHeaderInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self insetForHeaderInSection:section];
    } else if (!UIEdgeInsetsEqualToEdgeInsets(self.headerInset, UIEdgeInsetsZero)) {
        return self.headerInset;
    } else {
        return kSCDefaultHeaderInset;
    }
}

- (UIEdgeInsets)insetForFooterInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForFooterInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self insetForFooterInSection:section];
    } else if (!UIEdgeInsetsEqualToEdgeInsets(self.footerInset, UIEdgeInsetsZero)) {
        return self.footerInset;
    } else {
        return kSCDefaultFooterInset;
    }
}

@end
