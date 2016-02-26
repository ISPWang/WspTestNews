//
//  WSPHomeViewController.m
//  WSPNews
//
//  Created by auto on 16/1/6.
//  Copyright © 2016年 auto. All rights reserved.
//

#import "WSPHomeViewController.h"
#import "WSPHomeRequest.h"
#import "WSPTableViewController.h"
#import "WSPTitleShowLabel.h"

@interface WSPHomeViewController () <UIScrollViewDelegate>//<YTKRequestDelegate>
/**
 *  标题栏
 */
@property (weak, nonatomic) IBOutlet UIScrollView *smallScrollView;
/**
 *  容器栏
 */
@property (weak, nonatomic) IBOutlet UIScrollView *bigScrollView;

@property (nonatomic, strong) NSArray *titleArrayList;

@property (nonatomic, strong) NSArray *arrayLists;

@property (nonatomic,assign) CGFloat beginOffsetX;

@end

@implementation WSPHomeViewController

- (NSArray *)arrayLists {
    if (_arrayLists == nil) { /**< 栏目的plist数 */
        _arrayLists = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"NewsUrl.plist" ofType:nil]];
    }
    return _arrayLists;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [self testRequest];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.smallScrollView.showsHorizontalScrollIndicator = NO;
    self.smallScrollView.showsVerticalScrollIndicator = NO;
    self.smallScrollView.scrollsToTop = NO;
    self.bigScrollView.scrollsToTop = NO;
    self.bigScrollView.delegate = self;
    
    [self addController];
    [self addLable];
    
    CGFloat contentX = self.childViewControllers.count * [UIScreen mainScreen].bounds.size.width;
    self.bigScrollView.contentSize = CGSizeMake(contentX, 0);
    self.bigScrollView.pagingEnabled = YES;
    
    
    // 添加默认控制器
    UIViewController *vc = [self.childViewControllers firstObject];
    vc.view.frame = self.bigScrollView.bounds;
    [self.bigScrollView addSubview:vc.view];
    WSPTitleShowLabel *lable = [self.smallScrollView.subviews firstObject];
    lable.scale = 1.0;
    self.bigScrollView.showsHorizontalScrollIndicator = NO;
    
    
}



/** 添加子控制器 */
- (void)addController
{
    for (int i=0 ; i<self.arrayLists.count ;i++){
        WSPTableViewController *vc1 = [[UIStoryboard storyboardWithName:@"WSPNews" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
        vc1.title = self.arrayLists[i][@"title"];
        vc1.urlString = self.arrayLists[i][@"urlString"];
        [self addChildViewController:vc1];
    }
}
/** 添加标题栏 */
- (void)addLable {
    for (int i = 0; i < self.arrayLists.count; i++) {
        CGFloat lblW = 70;
        CGFloat lblH = 40;
        CGFloat lblY = 0;
        CGFloat lblX = i * lblW;
        WSPTitleShowLabel *lbl1 = [[WSPTitleShowLabel alloc]init];
        UIViewController *vc = self.childViewControllers[i];
        lbl1.text =vc.title;
        lbl1.frame = CGRectMake(lblX, lblY, lblW, lblH);
        lbl1.font = [UIFont fontWithName:@"HYQiHei" size:19];
        [self.smallScrollView addSubview:lbl1];
        lbl1.tag = i;
        lbl1.userInteractionEnabled = YES;
        
        [lbl1 addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(lblClick:)]];
    }
    self.smallScrollView.contentSize = CGSizeMake(70 * self.arrayLists.count, 0);
    
}
/** 标题栏label的点击事件 */
- (void)lblClick:(UITapGestureRecognizer *)recognizer {
    WSPTitleShowLabel *titlelable = (WSPTitleShowLabel *)recognizer.view;
    
    CGFloat offsetX = titlelable.tag * self.bigScrollView.frame.size.width;
    
    CGFloat offsetY = self.bigScrollView.contentOffset.y;
    CGPoint offset = CGPointMake(offsetX, offsetY);
    
    [self.bigScrollView setContentOffset:offset animated:YES];
    
    
}
#pragma mark - ******************** scrollView代理方法

/** 滚动结束后调用（代码导致） */
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    // 获得索引
    NSUInteger index = scrollView.contentOffset.x / self.bigScrollView.frame.size.width;
    
    // 滚动标题栏
    WSPTitleShowLabel *titleLable = (WSPTitleShowLabel *)self.smallScrollView.subviews[index];
    
    CGFloat offsetx = titleLable.center.x - self.smallScrollView.frame.size.width * 0.5;
    
    CGFloat offsetMax = self.smallScrollView.contentSize.width - self.smallScrollView.frame.size.width;
    if (offsetx < 0) {
        offsetx = 0;
    }else if (offsetx > offsetMax){
        offsetx = offsetMax;
    }
    
    CGPoint offset = CGPointMake(offsetx, self.smallScrollView.contentOffset.y);
    [self.smallScrollView setContentOffset:offset animated:YES];
    // 添加控制器
    WSPTableViewController *newsVc = self.childViewControllers[index];
    newsVc.index = index;
    self.hidesBottomBarWhenPushed = YES;
    [self.smallScrollView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx != index) {
            WSPTitleShowLabel *temlabel = self.smallScrollView.subviews[idx];
            temlabel.scale = 0.0;
        }
    }];
    
    if (newsVc.view.superview) return;
    
    newsVc.view.frame = scrollView.bounds;
    [self.bigScrollView addSubview:newsVc.view];
}

/** 滚动结束（手势导致） */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self scrollViewDidEndScrollingAnimation:scrollView];
}

/** 正在滚动 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 取出绝对值 避免最左边往右拉时形变超过1
    CGFloat value = ABS(scrollView.contentOffset.x / scrollView.frame.size.width);
    NSUInteger leftIndex = (int)value;
    NSUInteger rightIndex = leftIndex + 1;
    CGFloat scaleRight = value - leftIndex;
    CGFloat scaleLeft = 1 - scaleRight;
    WSPTitleShowLabel *labelLeft = self.smallScrollView.subviews[leftIndex];
    labelLeft.scale = scaleLeft;
    // 考虑到最后一个板块，如果右边已经没有板块了 就不在下面赋值scale了
    if (rightIndex < self.smallScrollView.subviews.count) {
        WSPTitleShowLabel *labelRight = self.smallScrollView.subviews[rightIndex];
        labelRight.scale = scaleRight;
    }
    
}


- (void)testRequest {
    
    WSPHomeRequest *requestHome = [[WSPHomeRequest alloc] init];
    //    requestHome.requestOperation.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", nil];
    //    text/html
    //    requestHome.cityCode = @"110000";
    //    NSMutableDictionary *muDic = [NSMutableDictionary dictionary];
    //    [muDic setValue:@20004 forKey:@"brandId"];
    //    [muDic setValue:@"-1" forKey:@"carId"];
    //    [muDic setValue:@110000 forKey:@"city"];
    //    [muDic setValue:@"北京市" forKey:@"cityName"];
    //
    //    [muDic setValue:@"38.34-56.7" forKey:@"guidePrice"];
    //    [muDic setValue:@2966 forKey:@"serialId"];
    //
    //    [muDic setValue:@"奥迪Q5" forKey:@"serialName"];
    //    [muDic setValue:@"myName" forKey:@"userName"];
    //    [muDic setValue:@"18119845906" forKey:@"mobile"];
    //    requestHome.dict = muDic;
    //    carId = "-1";
    //    city = 110000;
    //    cityName = "\U5317\U4eac\U5e02";
    //    guidePrice = "38.34-56.7";
    //    mobile = 15818829876;
    //    serialId = 2966;
    //    serialName = "\U5965\U8feaQ5";
    //    userName = We;
    //    requestHome.delegate = self;
    //    [requestHome start];
    if ([requestHome cacheJson]) {
        NSString *json = [requestHome cacheJson];
        WSPLog(@"json = %@", json);
        
        // show cached data
    }
    //    NSLog(@"--++++--%@", [reg cacheJson]);
    
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //        [requestHome startWithCompletionBlockWithSuccess:^(YTKBaseRequest *request) {
    //            WSPLog(@"-chengg---%@----%@",request.responseJSONObject, request.responseString);
    //            //            request
    //        } failure:^(YTKBaseRequest *request) {
    //            WSPLog(@"----shibai");
    //        }];
    //    });
    [requestHome startWithCompletionBlockWithSuccess:^(YTKBaseRequest *request) {
        WSPLog(@"-chengg---%@----%@",request.responseJSONObject, request.responseString);
        
    } failure:^(YTKBaseRequest *request) {
        WSPLog(@"----shibai");
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
