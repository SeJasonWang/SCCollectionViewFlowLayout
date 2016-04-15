//
//  SCCollectionViewFlowLayout.h
//  SCCollectionViewFlowLayout
//
//  Created by sichenwang on 16/1/22.
//  Copyright © 2016年 sichenwang. All rights reserved.
//  从左往右布局，排不下自动换行

#import <UIKit/UIKit.h>

extern NSString *const SCCollectionElementKindSectionHeader;
extern NSString *const SCCollectionElementKindSectionFooter;

@protocol SCCollectionViewDelegateFlowLayout <UICollectionViewDelegate>
@optional

/** The size in the specified item. default is {50, 50}. */
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
/** The horizontal spacing between items in the specified section. default is 5.0. */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout lineSpacingForSectionAtIndex:(NSInteger)section;
/** The vertical spacing between items in the specified section. default is 5.0. */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout interitemSpacingForSectionAtIndex:(NSInteger)section;
/** The margins to apply to content in the specified section. default is {0, 0, 0, 0}. */
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section;
/** The height of the header view in the specified section. default is 0. */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceHeightForHeaderInSection:(NSInteger)section;
/** The height of the footer view in the specified section. default it 0. */
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceHeightForFooterInSection:(NSInteger)section;
/** The margins to apply to header view in the specified section. default is {0, 0, 0, 0}. */
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForHeaderInSection:(NSInteger)section;
/** The margins to apply to footer view in the specified section. default is {0, 0, 0, 0}. */
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForFooterInSection:(NSInteger)section;
/** Set the property to YES to show background view in the specified section. default is NO. */
- (BOOL)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout shouldShowBackgroundViewInSection:(NSInteger)section;
/** The margins to apply to background view in the specified section. default is {0, 0, 0, 0}. */
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetsForBackgroundViewInSection:(NSInteger)section;

// PinToVisibleBounds
/** Set the property to YES to get header in the specified section that pin to the top of the screen while scrolling (similar to UITableView). */
- (BOOL)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout pinToVisibleBoundsForHeaderInSection:(NSInteger)section;
/** Call the method when the header pinned status did change while scrolling. */
- (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout didChangePinHeaderStatus:(BOOL)isPinning inSection:(NSInteger)section;

@end

@interface SCCollectionViewFlowLayout : UICollectionViewLayout

/** The size to use for cells. default is {50, 50}. */
@property (nonatomic, assign) CGSize itemSize;
/** The horizontal spacing between items. default is 5.0. */
@property (nonatomic, assign) CGFloat lineSpacing;
/** The vertical spacing between items. default is 5.0. */
@property (nonatomic, assign) CGFloat interitemSpacing;
/** The margins to apply to content in sections. default is {0, 0, 0, 0}. */
@property (nonatomic, assign) UIEdgeInsets sectionInset;
/** The sizes to use for section headers. default is 0. */
@property (nonatomic, assign) CGFloat headerReferenceHeight;
/** The sizes to use for section footers. default is 0. */
@property (nonatomic, assign) CGFloat footerReferenceHeight;
/** The margins to apply to header view. default is {0, 0, 0, 0}. */
@property (nonatomic, assign) UIEdgeInsets headerInset;
/** The margins to apply to footer view. default is {0, 0, 0, 0}. */
@property (nonatomic, assign) UIEdgeInsets footerInset;
/** The if content needs background view in sections. default is NO. */
@property (nonatomic, assign) BOOL shouldShowBackground;
/** The margins to apply to background view. default is {0, 0, 0, 0}. */
@property (nonatomic, assign) UIEdgeInsets backgroundInset;

// PinToVisibleBounds
@property (nonatomic, assign) CGFloat sectionHeadersPinToVisibleBoundsInsetTop;
/** Set the property to YES to get headers that pin to the top of the screen while scrolling (similar to UITableView). */
@property (nonatomic, assign) BOOL sectionHeadersPinToVisibleBounds;

@end
