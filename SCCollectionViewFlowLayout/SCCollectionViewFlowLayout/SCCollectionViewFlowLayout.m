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
static const BOOL kDefaultPinToVisibleBounds       = NO;
static const NSInteger kUnionCount = 20;

NSString *const SCCollectionElementKindSectionHeader = @"SCCollectionElementKindSectionHeader";
NSString *const SCCollectionElementKindSectionFooter = @"SCCollectionElementKindSectionFooter";

@interface SCPinHeader : NSObject

@property (nonatomic, strong) UICollectionViewLayoutAttributes *attributes;
@property (nonatomic, assign) CGFloat startY;
@property (nonatomic, assign) CGFloat endY;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGRect rect;

@end

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

@interface SCCollectionViewFlowLayout()

@property (nonatomic, weak) id<SCCollectionViewDelegateFlowLayout> delegate;
@property (nonatomic, assign) CGFloat contentHeight;
@property (nonatomic, assign) CGFloat contentWidth;
@property (nonatomic, strong) NSMutableArray *attributesArray;
@property (nonatomic, strong) NSMutableArray *unionRects;

// PinToVisibleBounds
@property (nonatomic, strong) NSMutableArray *pinHeaderArray;
@property (nonatomic, strong) NSMutableArray *showingPinHeaderArray;
@property (nonatomic, strong) NSMutableArray *showingAttributesArray;
@property (nonatomic, assign, getter=isUpdatingPinHeader) BOOL updatingPinHeader;
@property (nonatomic, assign) CGRect preRect;

@end

@implementation SCCollectionViewFlowLayout

#pragma mark - Override Methods

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(self.collectionView.bounds)) {
        return YES;
    } else if (self.pinHeaderArray.count) {
        self.updatingPinHeader = YES;
        [self.showingPinHeaderArray removeAllObjects];
        for (SCPinHeader *pinHeader in self.pinHeaderArray) {
            if (CGRectIntersectsRect(pinHeader.rect, newBounds)) {
                [self layoutPinHeader:pinHeader offsetY:newBounds.origin.y];
                [self.showingPinHeaderArray addObject:pinHeader.attributes];
            } else {
                if (self.showingPinHeaderArray.count) break;
            }
        }
        return YES;
    } else {
        return NO;
    }
}

- (void)prepareLayout {
    [super prepareLayout];
    
    NSInteger numOfSections = [self.collectionView numberOfSections];
    if (numOfSections && !self.isUpdatingPinHeader) {
        self.delegate = (id<SCCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
        self.contentHeight = 0.0;
        self.contentWidth = [UIScreen mainScreen].bounds.size.width;
        self.attributesArray = [NSMutableArray array];
        self.unionRects = [NSMutableArray array];
        self.pinHeaderArray = [NSMutableArray array];
        self.showingPinHeaderArray = [NSMutableArray array];
        self.showingAttributesArray = [NSMutableArray array];
        for (NSUInteger section = 0; section < numOfSections; section++) {
            [self layoutHeadersInSection:section];
            [self layoutItemsInSection:section];
            [self layoutFootersInSection:section];
        }
        [self uniteRects];
    }
}

- (CGSize)collectionViewContentSize {
    CGSize size = CGSizeMake(self.contentWidth, self.contentHeight);
    if (self.pinHeaderArray.count) {
        SCPinHeader *lastPinHeader = self.pinHeaderArray.lastObject;
        lastPinHeader.endY = self.contentHeight - lastPinHeader.attributes.frame.size.height;
        lastPinHeader.rect = CGRectMake(0, lastPinHeader.startY, self.collectionView.frame.size.width, self.contentHeight - lastPinHeader.startY);
        if (CGRectIntersectsRect(lastPinHeader.rect, CGRectMake(0, self.collectionView.contentOffset.y, self.collectionView.frame.size.width, self.collectionView.frame.size.height))) {
            [self layoutPinHeader:lastPinHeader offsetY:self.collectionView.contentOffset.y];
            [self.showingPinHeaderArray addObject:lastPinHeader.attributes];
        }
    }
    return size;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *mutableArray = [NSMutableArray array];
    if (self.showingPinHeaderArray.count) {
        [mutableArray addObjectsFromArray:self.showingPinHeaderArray];
    }
    if (!CGRectEqualToRect(self.preRect, rect) || !self.isUpdatingPinHeader) {
        self.preRect = rect;
        [self.showingAttributesArray removeAllObjects];
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
                [self.showingAttributesArray addObject:attributes];
            }
        }
    }
    [mutableArray addObjectsFromArray:self.showingAttributesArray];
    self.updatingPinHeader = NO;
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
        CGFloat y = self.contentHeight + inset.top;
        CGFloat w = self.contentWidth - inset.left - inset.right;
        attributes.frame = CGRectMake(x, y, w, h);
        attributes.zIndex = 10;
        self.contentHeight = y + h + inset.bottom;
        
        if ([self pinToHeaderVisibleBoundsInSection:section]) {
            attributes.zIndex = 20;
            SCPinHeader *pinHeader = [[SCPinHeader alloc] init];
            pinHeader.attributes = attributes;
            pinHeader.startY = y;
            if (self.pinHeaderArray.count) {
                SCPinHeader *prePinHeader = self.pinHeaderArray.lastObject;
                prePinHeader.endY = pinHeader.startY - prePinHeader.attributes.frame.size.height;
                prePinHeader.rect = CGRectMake(0, prePinHeader.startY, self.collectionView.frame.size.width, pinHeader.startY - prePinHeader.startY);
                if (CGRectIntersectsRect(prePinHeader.rect, CGRectMake(0, self.collectionView.contentOffset.y, self.collectionView.frame.size.width, self.collectionView.frame.size.height))) {
                    [self layoutPinHeader:prePinHeader offsetY:self.collectionView.contentOffset.y];
                    [self.showingPinHeaderArray addObject:prePinHeader.attributes];
                }
            }
            [self.pinHeaderArray addObject:pinHeader];
        } else {
            [self.attributesArray addObject:attributes];
        }
    }
}

- (void)layoutItemsInSection:(NSInteger)section {
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
    if (numberOfItems) {
        CGFloat lineSpacing = [self lineSpacingForSectionAtIndex:section];
        CGFloat interitemSpacing = [self interitemSpacingForSectionAtIndex:section];
        UIEdgeInsets inset = [self insetForSectionAtIndex:section];
        self.contentHeight += inset.top;
        for (NSInteger item = 0; item < numberOfItems; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            CGSize size = [self sizeForItemAtIndexPath:indexPath];
            if (item == 0) {
                attributes.size = size;
                CGRect frame = attributes.frame;
                frame.origin.x = inset.left;
                frame.origin.y = self.contentHeight;
                attributes.frame = frame;
                self.contentHeight = CGRectGetMaxY(attributes.frame);
            } else {
                UICollectionViewLayoutAttributes *prevAttributes = self.attributesArray.lastObject;
                CGFloat x = CGRectGetMaxX(prevAttributes.frame);
                if (x + interitemSpacing + size.width <= self.contentWidth - inset.right) {
                    attributes.size = size;
                    CGRect frame = attributes.frame;
                    frame.origin.x = x + interitemSpacing;
                    frame.origin.y = prevAttributes.frame.origin.y;
                    attributes.frame = frame;
                    if (size.height > prevAttributes.size.height) {
                        self.contentHeight = CGRectGetMaxY(attributes.frame);
                    }
                } else {
                    attributes.size = size;
                    CGRect frame = attributes.frame;
                    frame.origin.x = inset.left;
                    frame.origin.y = self.contentHeight + lineSpacing;
                    attributes.frame = frame;
                    self.contentHeight = CGRectGetMaxY(attributes.frame);
                }
            }
            [self.attributesArray addObject:attributes];
        }
        self.contentHeight += inset.bottom;
    }
}

- (void)layoutFootersInSection:(NSInteger)section {
    CGFloat h = [self referenceHeightForFooterInSection:section];
    if (h) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:SCCollectionElementKindSectionFooter withIndexPath:indexPath];
        UIEdgeInsets inset = [self insetForFooterInSection:section];
        CGFloat x = inset.left;
        CGFloat y = self.contentHeight + inset.top;
        CGFloat w = self.contentWidth - inset.left - inset.right;
        attributes.frame = CGRectMake(x, y, w, h);
        attributes.zIndex = 10;
        self.contentHeight = y + h + inset.bottom;
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

- (void)layoutPinHeader:(SCPinHeader *)pinHeader offsetY:(CGFloat)offsetY {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:didChangePinHeaderStatus:inSection:)]) {
        if (offsetY <= pinHeader.startY || offsetY >= pinHeader.endY) {
            if (pinHeader.y > pinHeader.startY && pinHeader.y < pinHeader.endY) {
                [self.delegate collectionView:self.collectionView layout:self didChangePinHeaderStatus:NO inSection:pinHeader.attributes.indexPath.section];
            }
        } else {
            if (pinHeader.y <= pinHeader.startY || pinHeader.y >= pinHeader.endY) {
                [self.delegate collectionView:self.collectionView layout:self didChangePinHeaderStatus:YES inSection:pinHeader.attributes.indexPath.section];
            }
        }
    }
    if (offsetY <= pinHeader.startY) {
        pinHeader.y = pinHeader.startY;
    } else if (offsetY >= pinHeader.endY) {
        pinHeader.y = pinHeader.endY;
    } else {
        pinHeader.y = offsetY;
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

- (BOOL)pinToHeaderVisibleBoundsInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:pinToVisibleBoundsForHeaderInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self pinToVisibleBoundsForHeaderInSection:section];
    } else if (self.sectionHeadersPinToVisibleBounds) {
        return self.sectionHeadersPinToVisibleBounds;
    }
    return kDefaultPinToVisibleBounds;
}

@end
