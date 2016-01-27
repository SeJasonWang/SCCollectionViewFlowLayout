//
//  ViewController.m
//  SCCollectionViewFlowLayout
//
//  Created by sichenwang on 16/1/22.
//  Copyright © 2016年 sichenwang. All rights reserved.
//

#import "ViewController.h"
#import "SCCollectionViewFlowLayout.h"
#import "SCCollectionReusableView.h"

static NSString * const cellId = @"Cell";
static NSString * const reusableViewId = @"ReusableView";

@interface ViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, SCCollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    SCCollectionViewFlowLayout *layout = [[SCCollectionViewFlowLayout alloc] init];
    layout.headerReferenceHeight = 44.0;
    layout.footerReferenceHeight = 44.0;
    layout.lineSpacing = 5.0;
    layout.interitemSpacing = 5.0;
    layout.sectionHeadersPinToVisibleBounds = YES;
    
    self.collectionView.collectionViewLayout = layout;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:cellId];
    [self.collectionView registerNib:[UINib nibWithNibName:@"SCCollectionReusableView" bundle:nil] forSupplementaryViewOfKind:SCCollectionElementKindSectionHeader withReuseIdentifier:reusableViewId];
    [self.collectionView registerNib:[UINib nibWithNibName:@"SCCollectionReusableView" bundle:nil] forSupplementaryViewOfKind:SCCollectionElementKindSectionFooter withReuseIdentifier:reusableViewId];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1000] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    });;
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 10000;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 30;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor orangeColor];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:SCCollectionElementKindSectionHeader]) {
        SCCollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:SCCollectionElementKindSectionHeader withReuseIdentifier:reusableViewId forIndexPath:indexPath];
        header.backgroundColor = [UIColor lightGrayColor];
        header.titleLabel.text = [NSString stringWithFormat:@"Header%zd",indexPath.section];
        return header;
    } else if ([kind isEqualToString:SCCollectionElementKindSectionFooter]) {
        SCCollectionReusableView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:SCCollectionElementKindSectionFooter withReuseIdentifier:reusableViewId forIndexPath:indexPath];
        footer.backgroundColor = [UIColor purpleColor];
        footer.titleLabel.text = [NSString stringWithFormat:@"Feader%zd",indexPath.section];
        return footer;
    } else {
        return nil;
    }
}

#pragma mark - SCCollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(80+indexPath.row, 60);
}

@end
