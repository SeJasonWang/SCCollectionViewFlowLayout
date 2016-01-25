//
//  ViewController.m
//  SCCollectionViewFlowLayout
//
//  Created by sichenwang on 16/1/22.
//  Copyright © 2016年 sichenwang. All rights reserved.
//

#import "ViewController.h"
#import "SCCollectionViewFlowLayout.h"

static NSString * const cellId = @"Cell";
static NSString * const headerId = @"Header";
static NSString * const footerId = @"Footer";

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
    self.collectionView.collectionViewLayout = layout;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:cellId];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:SCCollectionElementKindSectionHeader withReuseIdentifier:headerId];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:SCCollectionElementKindSectionFooter withReuseIdentifier:footerId];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 15;
            break;
        case 1:
            return 22;
            break;
        case 2:
            return 30;
            break;
        default:
            return 0;
            break;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    cell.contentView.backgroundColor = [UIColor orangeColor];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:SCCollectionElementKindSectionHeader]) {
        UICollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:SCCollectionElementKindSectionHeader withReuseIdentifier:headerId forIndexPath:indexPath];
        header.backgroundColor = [UIColor yellowColor];
        return header;
    } else if ([kind isEqualToString:SCCollectionElementKindSectionFooter]) {
        UICollectionReusableView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:SCCollectionElementKindSectionFooter withReuseIdentifier:footerId forIndexPath:indexPath];
        footer.backgroundColor = [UIColor redColor];
        return footer;
    } else {
        return nil;
    }
}

#pragma mark - SCCollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(40+indexPath.row, 40-indexPath.row);
}

@end
