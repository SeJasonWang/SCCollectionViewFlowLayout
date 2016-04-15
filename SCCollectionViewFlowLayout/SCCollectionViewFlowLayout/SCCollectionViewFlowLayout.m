//
//  SCCollectionViewFlowLayout.m
//  SCCollectionViewFlowLayout
//
//  Created by sichenwang on 16/1/22.
//  Copyright © 2016年 sichenwang. All rights reserved.
//

#import "SCCollectionViewFlowLayout.h"
#import "SCPinHeader.h"
#import "SCSectionBackgroundView.h"

static const CGSize kDefaultItemSize                    = {50, 50};
static const CGFloat kDefaultLineSpacing                = 5;
static const CGFloat kDefaultInteritemSpacing           = 5;
static const UIEdgeInsets kDefaultSectionInset          = {0, 0, 0, 0};
static const CGFloat kDefaultHeaderReferenceHeight      = 0.0;
static const CGFloat kDefaultFooterReferenceHeight      = 0.0;
static const UIEdgeInsets kDefaultHeaderInset           = {0, 0, 0, 0};
static const UIEdgeInsets kDefaultFooterInset           = {0, 0, 0, 0};
static const BOOL kDefaultPinToVisibleBounds            = NO;
static const BOOL kDefaultShouldShowBackgroundView      = NO;
static const UIEdgeInsets kDefaultBackgroundInsets      = {0, 0, 0, 0};
static const NSInteger kUnionCount = 20;

NSString *const SCCollectionElementKindSectionHeader = @"SCCollectionElementKindSectionHeader";
NSString *const SCCollectionElementKindSectionFooter = @"SCCollectionElementKindSectionFooter";
NSString *const SCCollectionElementKindSectionBackgroundView = @"SCCollectionElementKindSectionBackgroundView";

@interface SCCollectionViewFlowLayout()

@property (nonatomic, weak) id<SCCollectionViewDelegateFlowLayout> delegate;
@property (nonatomic, assign) CGFloat contentHeight;
@property (nonatomic, assign) CGFloat contentWidth;
@property (nonatomic, strong) NSMutableArray *allItems;
@property (nonatomic, strong) NSMutableArray *allShowingItems;
@property (nonatomic, strong) NSMutableArray *headers;
@property (nonatomic, strong) NSMutableArray *sectionItems;
@property (nonatomic, strong) NSMutableArray *backgroundItems;
@property (nonatomic, strong) NSMutableArray *footers;
@property (nonatomic, strong) NSMutableArray *unionRects;

// PinToVisibleBounds
@property (nonatomic, strong) NSMutableArray *pinHeaders;
@property (nonatomic, strong) NSMutableArray *showingPinHeaders;
@property (nonatomic, assign, getter=isUpdatingPinHeader) BOOL updatingPinHeader;
@property (nonatomic, assign) CGRect preRect;

@end

@implementation SCCollectionViewFlowLayout

#pragma mark - Override Methods

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    if (CGRectGetWidth(newBounds) != CGRectGetWidth(self.collectionView.bounds)) {
        return YES;
    } else if (self.pinHeaders.count) {
        self.updatingPinHeader = YES;
        [self.showingPinHeaders removeAllObjects];
        for (SCPinHeader *pinHeader in self.pinHeaders) {
            if (CGRectIntersectsRect(pinHeader.rect, newBounds)) {
                [self layoutPinHeader:pinHeader offsetY:newBounds.origin.y];
                [self.showingPinHeaders addObject:pinHeader.attributes];
            } else {
                if (self.showingPinHeaders.count) break;
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
        [self registerClass:[SCSectionBackgroundView class] forDecorationViewOfKind:SCCollectionElementKindSectionBackgroundView];
        self.contentHeight = 0.0;
        self.contentWidth = [UIScreen mainScreen].bounds.size.width;
        self.allItems = [NSMutableArray array];
        self.allShowingItems = [NSMutableArray array];
        self.headers = [NSMutableArray array];
        self.sectionItems = [NSMutableArray array];
        self.backgroundItems = [NSMutableArray array];
        self.footers = [NSMutableArray array];
        self.unionRects = [NSMutableArray array];
        self.pinHeaders = [NSMutableArray array];
        self.showingPinHeaders = [NSMutableArray array];
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
    if (self.pinHeaders.count) {
        SCPinHeader *lastPinHeader = self.pinHeaders.lastObject;
        lastPinHeader.endY = self.contentHeight - lastPinHeader.attributes.frame.size.height;
        lastPinHeader.rect = CGRectMake(0, lastPinHeader.startY, self.collectionView.frame.size.width, self.contentHeight - lastPinHeader.startY);
        if (CGRectIntersectsRect(lastPinHeader.rect, CGRectMake(0, self.collectionView.contentOffset.y, self.collectionView.frame.size.width, self.collectionView.frame.size.height))) {
            [self layoutPinHeader:lastPinHeader offsetY:self.collectionView.contentOffset.y];
            [self.showingPinHeaders addObject:lastPinHeader.attributes];
        }
    }
    return size;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *mutableArray = [NSMutableArray array];
    if (self.showingPinHeaders.count) {
        [mutableArray addObjectsFromArray:self.showingPinHeaders];
    }
    if (!CGRectEqualToRect(self.preRect, rect) || !self.isUpdatingPinHeader) {
        self.preRect = rect;
        [self.allShowingItems removeAllObjects];
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
                end = MIN((i + 1) * kUnionCount, self.allItems.count);
                break;
            }
        }
        for (i = begin; i < end; i++) {
            UICollectionViewLayoutAttributes *attributes = self.allItems[i];
            if (CGRectIntersectsRect(rect, attributes.frame)) {
                [self.allShowingItems addObject:attributes];
            }
        }
    }
    [mutableArray addObjectsFromArray:self.allShowingItems];
    self.updatingPinHeader = NO;
    return [mutableArray copy];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *array = self.sectionItems[indexPath.section];
    return array[indexPath.item];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if ([elementKind isEqualToString:SCCollectionElementKindSectionHeader]) {
        return self.headers[indexPath.section];
    } else if ([elementKind isEqualToString:SCCollectionElementKindSectionFooter]){
        return self.footers[indexPath.section];
    } else {
        return [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
    }
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
            if (self.pinHeaders.count) {
                SCPinHeader *prePinHeader = self.pinHeaders.lastObject;
                prePinHeader.endY = pinHeader.startY - prePinHeader.attributes.frame.size.height;
                prePinHeader.rect = CGRectMake(0, prePinHeader.startY, self.collectionView.frame.size.width, pinHeader.startY - prePinHeader.startY);
                if (CGRectIntersectsRect(prePinHeader.rect, CGRectMake(0, self.collectionView.contentOffset.y, self.collectionView.frame.size.width, self.collectionView.frame.size.height))) {
                    [self layoutPinHeader:prePinHeader offsetY:self.collectionView.contentOffset.y];
                    [self.showingPinHeaders addObject:prePinHeader.attributes];
                }
            }
            [self.pinHeaders addObject:pinHeader];
        } else {
            [self.allItems addObject:attributes];
        }
        [self.headers addObject:attributes];
    }
}

- (void)layoutItemsInSection:(NSInteger)section {
    NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];
    if (numberOfItems) {
        CGFloat startY = self.contentHeight;
        CGFloat lineSpacing = [self lineSpacingForSectionAtIndex:section];
        CGFloat interitemSpacing = [self interitemSpacingForSectionAtIndex:section];
        UIEdgeInsets inset = [self insetForSectionAtIndex:section];
        self.contentHeight += inset.top;
        NSMutableArray *mutableArray = [NSMutableArray array];
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
                UICollectionViewLayoutAttributes *prevAttributes = self.allItems.lastObject;
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
            [self.allItems addObject:attributes];
            [mutableArray addObject:attributes];
        }
        [self.sectionItems addObject:mutableArray];
        self.contentHeight += inset.bottom;
        CGFloat endY = self.contentHeight;
        
        if ([self needsBackgroundViewInSection:section]) {
            UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:SCCollectionElementKindSectionBackgroundView withIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
            UIEdgeInsets insets = [self insetsForBackgroundViewInSection:section];
            CGFloat x = insets.left;
            CGFloat y = startY + insets.top;
            CGFloat w = [UIScreen mainScreen].bounds.size.width - insets.left - insets.right;
            CGFloat h = endY - startY - insets.top - insets.bottom;
            attr.frame = CGRectMake(x, y, w, h);
            attr.zIndex = -1;
            [self.allItems addObject:attr];
        }
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
        [self.allItems addObject:attributes];
        [self.footers addObject:attributes];
    }
}

- (void)uniteRects {
    NSInteger idx = 0;
    NSInteger count = self.allItems.count;
    while (idx < count) {
        CGRect unionRect = ((UICollectionViewLayoutAttributes *)self.allItems[idx]).frame;
        NSInteger rectEndIndex = MIN(idx + kUnionCount, count);
        for (NSInteger i = idx + 1; i < rectEndIndex; i++) {
            unionRect = CGRectUnion(unionRect, ((UICollectionViewLayoutAttributes *)self.allItems[i]).frame);
        }
        idx = rectEndIndex;
        [self.unionRects addObject:[NSValue valueWithCGRect:unionRect]];
    }
}

- (void)layoutPinHeader:(SCPinHeader *)pinHeader offsetY:(CGFloat)offsetY {
    offsetY += self.sectionHeadersPinToVisibleBoundsInsetTop;
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

- (BOOL)needsBackgroundViewInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:shouldShowBackgroundViewInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self shouldShowBackgroundViewInSection:section];
    } else if (self.shouldShowBackground) {
        return self.shouldShowBackground;
    }
    return kDefaultShouldShowBackgroundView;
}

- (UIEdgeInsets)insetsForBackgroundViewInSection:(NSInteger)section {
    if ([self.delegate respondsToSelector:@selector(collectionView:layout:insetsForBackgroundViewInSection:)]) {
        return [self.delegate collectionView:self.collectionView layout:self insetsForBackgroundViewInSection:section];
    } else if (!UIEdgeInsetsEqualToEdgeInsets(self.backgroundInset, UIEdgeInsetsZero)) {
        return self.backgroundInset;
    }
    return kDefaultBackgroundInsets;
}

@end
