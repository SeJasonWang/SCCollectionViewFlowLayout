//
//  SCCollectionViewFlowLayout.m
//  SCCollectionViewFlowLayout
//
//  Created by sichenwang on 16/1/22.
//  Copyright © 2016年 sichenwang. All rights reserved.
//

#import "SCCollectionViewFlowLayout.h"

static const CGSize kDefaultItemSize               = {50.0, 50.0};
static const CGFloat kDefaultLineSpacing           = 0.0;
static const CGFloat kDefaultInteritemSpacing      = 0.0;
static const UIEdgeInsets kDefaultSectionInset     = {0.0, 0.0, 0.0, 0.0};
static const CGFloat kDefaultHeaderReferenceHeight = 0.0;
static const CGFloat kDefaultFooterReferenceHeight = 0.0;
static const UIEdgeInsets kDefaultHeaderInset      = {0.0, 0.0, 0.0, 0.0};
static const UIEdgeInsets kDefaultFooterInset      = {0.0, 0.0, 0.0, 0.0};
static const NSInteger kUnionCount = 20;

NSString *const SCCollectionElementKindSectionHeader = @"SCCollectionElementKindSectionHeader";
NSString *const SCCollectionElementKindSectionFooter = @"SCCollectionElementKindSectionFooter";

@interface SCCollectionViewFlowLayout()

@property (nonatomic, weak) id<SCCollectionViewDelegateFlowLayout> delegate;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, strong) NSMutableArray *attributesArray;
@property (nonatomic, strong) NSMutableArray *unionRects;

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
        self.unionRects = [NSMutableArray array];
        for (NSUInteger section = 0; section < numOfSections; section++) {
            [self layoutHeadersInSection:section];
            [self layoutItemsInSection:section];
            [self layoutFootersInSection:section];
        }
        [self uniteRects];
    }
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake([UIScreen mainScreen].bounds.size.width, self.y);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *mutableArray = [NSMutableArray array];
    NSInteger i;
    NSInteger begin = 0, end = self.unionRects.count;
    for (i = 0; i < self.unionRects.count; i++) {
        if (CGRectIntersectsRect(rect, [self.unionRects[i] CGRectValue])) {
            begin = i * kUnionCount;
            break;
        }
    }
    for (i = self.unionRects.count - 1; i >= 0; i--) {
        if (CGRectIntersectsRect(rect, [self.unionRects[i] CGRectValue])) {
            end = MIN((i + 1) * kUnionCount, self.attributesArray.count);
            break;
        }
    }
    for (i = begin; i < end; i++) {
        UICollectionViewLayoutAttributes *attributes = self.attributesArray[i];
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

- (void)uniteRects {
    NSInteger idx = 0;
    NSInteger count = self.attributesArray.count;
    while (idx < count) {
        CGRect unionRect = ((UICollectionViewLayoutAttributes *)self.attributesArray[idx]).frame;
        NSInteger rectEndIndex = MIN(idx + kUnionCount, count);
        for (NSInteger i = idx + 1; i < rectEndIndex; i++) {
            unionRect = CGRectUnion(unionRect, ((UICollectionViewLayoutAttributes *)self.attributesArray[i]).frame);
        }
        idx = rectEndIndex;
        [self.unionRects addObject:[NSValue valueWithCGRect:unionRect]];
    }
}

#pragma mark - Getter

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]) {
        return [self.delegate collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath];
    } else if (!CGSizeEqualToSize(self.itemSize, CGSizeZero)) {
        return self.itemSize;
    } else {
        return kDefaultItemSize;
    }
}

- (CGFloat)lineSpacingForSectionAtIndex:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:lineSpacingForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self lineSpacingForSectionAtIndex:section];
    } else if (self.lineSpacing) {
        return self.lineSpacing;
    } else {
        return kDefaultLineSpacing;
    }
}

- (CGFloat)interitemSpacingForSectionAtIndex:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:interitemSpacingForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self interitemSpacingForSectionAtIndex:section];
    } else if (self.interitemSpacing) {
        return self.interitemSpacing;
    } else {
        return kDefaultInteritemSpacing;
    }
}

- (UIEdgeInsets)insetForSectionAtIndex:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
        return [self.delegate collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
    } else if (!UIEdgeInsetsEqualToEdgeInsets(self.sectionInset, UIEdgeInsetsZero)) {
        return self.sectionInset;
    } else {
        return kDefaultSectionInset;
    }
}

- (CGFloat)referenceHeightForHeaderInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:referenceHeightForHeaderInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self referenceHeightForHeaderInSection:section];
    } else if (self.headerReferenceHeight) {
        return self.headerReferenceHeight;
    } else {
        return kDefaultHeaderReferenceHeight;
    }
}

- (CGFloat)referenceHeightForFooterInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:referenceHeightForFooterInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self referenceHeightForFooterInSection:section];
    } else if (self.footerReferenceHeight) {
        return self.footerReferenceHeight;
    } else {
        return kDefaultFooterReferenceHeight;
    }
}

- (UIEdgeInsets)insetForHeaderInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForHeaderInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self insetForHeaderInSection:section];
    } else if (!UIEdgeInsetsEqualToEdgeInsets(self.headerInset, UIEdgeInsetsZero)) {
        return self.headerInset;
    } else {
        return kDefaultHeaderInset;
    }
}

- (UIEdgeInsets)insetForFooterInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetForFooterInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self insetForFooterInSection:section];
    } else if (!UIEdgeInsetsEqualToEdgeInsets(self.footerInset, UIEdgeInsetsZero)) {
        return self.footerInset;
    } else {
        return kDefaultFooterInset;
    }
}

@end
