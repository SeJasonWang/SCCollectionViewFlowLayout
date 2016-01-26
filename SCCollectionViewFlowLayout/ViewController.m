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
        [self.collectionView reloadData];
    });;    
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 10000;
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
            return 70;
            break;
        default:
            return 20;
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
        SCCollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:SCCollectionElementKindSectionHeader withReuseIdentifier:reusableViewId forIndexPath:indexPath];
        switch (indexPath.section) {
            case 0:
                header.backgroundColor = [UIColor yellowColor];
                break;
            case 1:
                header.backgroundColor = [UIColor greenColor];
                break;
            case 2:
                header.backgroundColor = [UIColor purpleColor];
                break;
            default:
                header.backgroundColor = [UIColor lightGrayColor];
                break;
        }
        header.titleLabel.text = [NSString stringWithFormat:@"Header%zd",indexPath.section];
        return header;
    } else if ([kind isEqualToString:SCCollectionElementKindSectionFooter]) {
        SCCollectionReusableView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:SCCollectionElementKindSectionFooter withReuseIdentifier:reusableViewId forIndexPath:indexPath];
        footer.backgroundColor = [UIColor redColor];
        footer.titleLabel.text = @"Footer";
        return footer;
    } else {
        return nil;
    }
}

#pragma mark - SCCollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(40, 40);
}

@end
