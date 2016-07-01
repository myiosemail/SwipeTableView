//
//  STViewController.m
//  SwipeTableView
//
//  Created by Roy lee on 16/4/1.
//  Copyright © 2016年 Roy lee. All rights reserved.
//

#import "STViewController.h"
#import "SwipeTableView.h"
#import "CustomTableView.h"
#import "CustomCollectionView.h"
#import "CustomSegmentControl.h"
#import "UIView+STFrame.h"
#import "STImageController.h"
#import "STTransitions.h"

NSString const * kShouldReuseableViewIdentifier = @"setIsJustOneKindOfClassView";
NSString const * kHybridItemViewsIdentifier = @"doNothing";
NSString const * kDisabledSwipeHeaderBarScrollIdentifier = @"setSwipeHeaderBarScrollDisabled";
NSString const * kHiddenNavigationBarIdentifier = @"shouldHidenNavigationBar";

@interface STViewController ()<SwipeTableViewDataSource,SwipeTableViewDelegate,UIGestureRecognizerDelegate,UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) SwipeTableView * swipeTableView;
@property (nonatomic, assign) BOOL isJustOneKindOfClassView;
@property (nonatomic, assign) BOOL shouldHiddenNavigationBar;
@property (nonatomic, assign) BOOL swipeBarScrollDisabled;
@property (nonatomic, strong) STHeaderView * tableViewHeader;
@property (nonatomic, strong) CustomSegmentControl * segmentBar;
@property (nonatomic, strong) CustomTableView * tableView;
@property (nonatomic, strong) CustomCollectionView * collectionView;

@property (nonatomic, strong) NSMutableDictionary * itemDic;

@end

@implementation STViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _itemDic = [@{} mutableCopy];
    
    self.swipeTableView = [[SwipeTableView alloc]initWithFrame:self.view.bounds];
    _swipeTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _swipeTableView.delegate = self;
    _swipeTableView.dataSource = self;
    _swipeTableView.shouldAdjustContentSize = !_isJustOneKindOfClassView;
    _swipeTableView.swipeHeaderView = _swipeBarScrollDisabled?nil:self.tableViewHeader;
    _swipeTableView.swipeHeaderBar = self.segmentBar;
    _swipeTableView.swipeHeaderBarScrollDisabled = _swipeBarScrollDisabled;
    if (_shouldHiddenNavigationBar) {
        _swipeTableView.swipeHeaderTopInset = 0;
    }
    [self.view addSubview:_swipeTableView];
    
    // nav bar
    UIBarButtonItem * rightBarItem = [[UIBarButtonItem alloc]initWithTitle:@"- Header" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableHeader:)];
    UIBarButtonItem * leftBarItem = [[UIBarButtonItem alloc]initWithTitle:@"- Bar" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableBar:)];
    self.navigationItem.leftBarButtonItem = _swipeBarScrollDisabled?nil:leftBarItem;
    self.navigationItem.rightBarButtonItem = _swipeBarScrollDisabled?nil:rightBarItem;
    
    // back
    UIButton * back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.frame = CGRectMake(10, 0, 40, 40);
    back.top = _shouldHiddenNavigationBar?25:74;
    back.backgroundColor = RGBColorAlpha(10, 202, 0, 0.95);
    back.layer.cornerRadius = back.height/2;
    back.layer.masksToBounds = YES;
    back.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    back.hidden = _swipeBarScrollDisabled;
    [back setTitle:@"Back" forState:UIControlStateNormal];
    [back setTitleColor:RGBColor(255, 255, 215) forState:UIControlStateNormal];
    [back addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back];
    
    [self.navigationController.navigationBar setTintColor:RGBColor(234, 39, 0)];
    
    // edge gesture
    [_swipeTableView.contentView.panGestureRecognizer requireGestureRecognizerToFail:self.screenEdgePanGestureRecognizer];
}

- (UIScreenEdgePanGestureRecognizer *)screenEdgePanGestureRecognizer {
    UIScreenEdgePanGestureRecognizer *screenEdgePanGestureRecognizer = nil;
    if (self.navigationController.view.gestureRecognizers.count > 0) {
        for (UIGestureRecognizer *recognizer in self.navigationController.view.gestureRecognizers) {
            if ([recognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]) {
                screenEdgePanGestureRecognizer = (UIScreenEdgePanGestureRecognizer *)recognizer;
                break;
            }
        }
    }
    return screenEdgePanGestureRecognizer;
}

#pragma mark - Header & Bar

- (UIView *)tableViewHeader {
    if (nil == _tableViewHeader) {
        UIImage * headerImage = [UIImage imageNamed:@"onepiece_kiudai"];
        // swipe header
        self.tableViewHeader = [[STHeaderView alloc]init];
        _tableViewHeader.frame = CGRectMake(0, 0, kScreenWidth, kScreenWidth * (headerImage.size.height/headerImage.size.width));
        _tableViewHeader.backgroundColor = [UIColor whiteColor];
        
        // image view
        self.headerImageView = [[UIImageView alloc]initWithImage:headerImage];
        _headerImageView.userInteractionEnabled = YES;
        _headerImageView.frame = _tableViewHeader.bounds;
        
        // title label
        UILabel * title = [[UILabel alloc]init];
        title.textColor = RGBColor(255, 255, 255);
        title.font = [UIFont boldSystemFontOfSize:17];
        title.text = @"Tap To Full Screen";
        title.textAlignment = NSTextAlignmentCenter;
        title.size = CGSizeMake(200, 30);
        title.centerX = _headerImageView.centerX;
        title.bottom = _headerImageView.bottom - 20;
        
        // tap gesture
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapHeader:)];
        
        [_tableViewHeader addSubview:_headerImageView];
        [_tableViewHeader addSubview:title];
        [_headerImageView addGestureRecognizer:tap];
        [self shimmerHeaderTitle:title];
    }
    return _tableViewHeader;
}

- (CustomSegmentControl * )segmentBar {
    if (nil == _segmentBar) {
        self.segmentBar = [[CustomSegmentControl alloc]initWithItems:@[@"Item0",@"Item1",@"Item2",@"Item3"]];
        _segmentBar.size = CGSizeMake(kScreenWidth, 40);
        _segmentBar.font = [UIFont systemFontOfSize:15];
        _segmentBar.textColor = RGBColor(100, 100, 100);
        _segmentBar.selectedTextColor = RGBColor(0, 0, 0);
        _segmentBar.backgroundColor = RGBColor(249, 251, 198);
        _segmentBar.selectionIndicatorColor = RGBColor(249, 104, 92);
        _segmentBar.selectedSegmentIndex = _swipeTableView.currentItemIndex;
        [_segmentBar addTarget:self action:@selector(changeSwipeViewIndex:) forControlEvents:UIControlEventValueChanged];
    }
    return _segmentBar;
}

#pragma mark -

- (void)setActionIdentifier:(NSString *)actionIdentifier {
    _actionIdentifier = actionIdentifier;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:NSSelectorFromString(_actionIdentifier) withObject:nil];
#pragma clang diagnostic pop
}

- (void)setIsJustOneKindOfClassView {
    _isJustOneKindOfClassView = YES;
}

- (void)setSwipeHeaderBarScrollDisabled {
    _swipeBarScrollDisabled = YES;
}

- (void)shouldHidenNavigationBar {
    _shouldHiddenNavigationBar = YES;
}

- (void)doNothing{};

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tapHeader:(UITapGestureRecognizer *)tap {
    STImageController * imageVC = [[STImageController alloc]init];
    imageVC.transitioningDelegate = self;
    [self presentViewController:imageVC animated:YES completion:nil];
}

- (void)shimmerHeaderTitle:(UILabel *)title {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.75f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        title.transform = CGAffineTransformMakeScale(0.98, 0.98);
        title.alpha = 0.3;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.75f delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            title.alpha = 1.0;
            title.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [weakSelf shimmerHeaderTitle:title];
        }];
    }];
}

- (void)setSwipeTableHeader:(UIBarButtonItem *)barItem {
    if (!_swipeTableView.swipeHeaderView) {
        _swipeTableView.swipeHeaderView = self.tableViewHeader;
        [_swipeTableView reloadData];
        
        UIBarButtonItem * rightBarItem = [[UIBarButtonItem alloc]initWithTitle:@"- Header" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableHeader:)];
        self.navigationItem.rightBarButtonItem = rightBarItem;
    }else {
        _swipeTableView.swipeHeaderView = nil;
        
        UIBarButtonItem * rightBarItem = [[UIBarButtonItem alloc]initWithTitle:@"+ Header" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableHeader:)];
        self.navigationItem.rightBarButtonItem = rightBarItem;
    }
}

- (void)setSwipeTableBar:(UIBarButtonItem *)barItem {
    if (!_swipeTableView.swipeHeaderBar) {
        _swipeTableView.swipeHeaderBar = self.segmentBar;
        _swipeTableView.scrollEnabled  = YES;
        
        UIBarButtonItem * leftBarItem = [[UIBarButtonItem alloc]initWithTitle:@"- Bar" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableBar:)];
        self.navigationItem.leftBarButtonItem = leftBarItem;
    }else {
        _swipeTableView.swipeHeaderBar = nil;
        _swipeTableView.scrollEnabled  = NO;
        
        UIBarButtonItem * leftBarItem = [[UIBarButtonItem alloc]initWithTitle:@"+ Bar" style:UIBarButtonItemStylePlain target:self action:@selector(setSwipeTableBar:)];
        self.navigationItem.leftBarButtonItem = leftBarItem;
    }
}

- (CustomTableView *)tableView {
    if (nil == _tableView) {
        _tableView = [[CustomTableView alloc]initWithFrame:_swipeTableView.bounds style:UITableViewStylePlain];
        _tableView.backgroundColor = RGBColor(255, 255, 225);
    }
    return _tableView;
}

- (CustomCollectionView *)collectionView {
    if (nil == _collectionView) {
        _collectionView = [[CustomCollectionView alloc]initWithFrame:_swipeTableView.bounds];
        _collectionView.backgroundColor = RGBColor(255, 255, 225);
    }
    return _collectionView;
}

- (void)changeSwipeViewIndex:(UISegmentedControl *)seg {
    [_swipeTableView scrollToItemAtIndex:seg.selectedSegmentIndex animated:NO];
}

#pragma mark - SwipeTableView M

- (NSInteger)numberOfItemsInSwipeTableView:(SwipeTableView *)swipeView {
    return 4;
}

- (UIScrollView *)swipeTableView:(SwipeTableView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIScrollView *)view {
    NSInteger numberOfRows = 12;
    if (_isJustOneKindOfClassView || _shouldHiddenNavigationBar) {
        // 重用
        if (nil == view) {
            CustomTableView * tableView = [[CustomTableView alloc]initWithFrame:swipeView.bounds style:UITableViewStylePlain];
            tableView.backgroundColor = RGBColor(255, 255, 225);
            view = tableView;
        }
        if (index == 1 || index == 3) {
            numberOfRows = 5;
        }
        [view setValue:@(numberOfRows) forKey:@"numberOfRows"];
        [view setValue:@(index) forKey:@"itemIndex"];
        
    }else {
        // 混合的itemview只有同类型的item采用重用
        if (index == 0 || index == 2) {
            // 懒加载保证同样类型的item只创建一次，以达到重用
            self.tableView.numberOfRows = numberOfRows;
            view = self.tableView;
        }else {
            self.collectionView.numberOfItems = (index == 1)?(numberOfRows + 4):numberOfRows;
            self.collectionView.isWaterFlow   = index == 1;
            view = self.collectionView;
        }
    }
    [view performSelector:@selector(reloadData)];
    return view;
}

- (void)swipeTableViewCurrentItemIndexDidChange:(SwipeTableView *)swipeView {
    _segmentBar.selectedSegmentIndex = swipeView.currentItemIndex;
}


#pragma  mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    
    return [[STTransitions alloc]initWithTransitionDuration:0.55f fromView:self.headerImageView isPresenting:YES];
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return [[STTransitions alloc]initWithTransitionDuration:0.5f fromView:self.headerImageView isPresenting:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:_shouldHiddenNavigationBar animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    __weak typeof(self) weakSelf = self;
    self.navigationController.interactivePopGestureRecognizer.delegate = weakSelf;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
