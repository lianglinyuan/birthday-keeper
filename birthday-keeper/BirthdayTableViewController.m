//
//  BirthdayTableViewController.m
//  birthday-keeper
//
//  Created by   chironyf on 2018/3/12.
//  Copyright © 2018年 chironyf. All rights reserved.
//

#import "BirthdayTableViewController.h"
#import "BirthdayCell.h"
#import "BirthdayCellModel.h"
#import "BirthdayInfoAddedViewController.h"
#import "GCON.h"
#import <UserNotifications/UserNotifications.h>

static NSString *const BirthdayCellIdentifier = @"BirthdayCellIdentifier";
//作为同步属性的全局变量
NSMutableArray<BirthdayCellModel *> *externBirthdayInfo;
//用来记录当前数组的count,由于可变数组的监听,每次只能观察到一个元素的改变,无法观察count的变化
static int curBirthdayInfoCount = 0;

@interface BirthdayTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *edit;
@property (nonatomic, strong) UIBarButtonItem *finished;


@end

@implementation BirthdayTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //没初始化的话，不会报错，但是没有数据显示
    
    [self addObserver:self forKeyPath:@"birthdayInfo" options:NSKeyValueObservingOptionNew context:nil];
    
    [self addObserver:self forKeyPath:@"isBirthdayTableEditing" options:NSKeyValueObservingOptionNew context:nil];
    
    self.isBirthdayTableEditing = @"FALSE";
    
    curBirthdayInfoCount = (int)[_birthdayInfo count];
    
    //第一次加载初始化中介
    _tempCellModel = [[BirthdayCellModel alloc] init];
    _curIndex = -1;
    
    [self addObserver:self forKeyPath:@"isSaved" options:NSKeyValueObservingOptionNew context:nil];

    
    self.title = @"生日管家";
    
    //第一次进入在位读取数据时, editing 为 false, 编辑按钮灰, 添加按钮亮
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"添加" style:UIBarButtonItemStylePlain target:self action:@selector(addBirthday)];
    
    self.edit = [[UIBarButtonItem alloc] initWithTitle:@"编辑" style:UIBarButtonItemStylePlain target:self action:@selector(editBirthday)];
    self.finished = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(finishEditBirthday)];
    
    self.navigationItem.leftBarButtonItem = _edit;
    if (curBirthdayInfoCount == 0) {
        self.navigationItem.leftBarButtonItem.enabled = FALSE;
    }
    
    _birthdayTableView = [[UITableView alloc] init];
    
    _birthdayTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _birthdayTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _birthdayTableView.separatorColor = [UIColor colorWithRed:themeCellLineRed green:themeCellLineGreen blue:themeCellLineBlue alpha:themeAlpha];
//    _birthdayTableView.
    

    //隐藏多余的线条
    _birthdayTableView.tableFooterView = [[UIView alloc] init];
    
    _birthdayTableView.backgroundColor = [UIColor colorWithRed:themeRed green:themeGreen blue:themeBlue alpha:themeAlpha];
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:themeRed green:themeGreen blue:themeBlue alpha:themeAlpha];
    
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:themeTextRed green:themeTextGreen blue:themeTextBlue alpha:themeAlpha];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor};

    [self.view addSubview:_birthdayTableView];
    
    [_birthdayTableView setDelegate:self];
    [_birthdayTableView setDataSource:self];
    
    NSLayoutConstraint *birthdayTableViewLeft = [NSLayoutConstraint constraintWithItem:_birthdayTableView  attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    
    NSLayoutConstraint *birthdayTableViewRight = [NSLayoutConstraint constraintWithItem:_birthdayTableView  attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0];
    
    NSLayoutConstraint *birthdayTableViewTop = [NSLayoutConstraint constraintWithItem:_birthdayTableView  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    
    NSLayoutConstraint *birthdayTableViewBottom = [NSLayoutConstraint constraintWithItem:_birthdayTableView  attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    
    [self.view addConstraints:@[birthdayTableViewLeft, birthdayTableViewRight, birthdayTableViewTop, birthdayTableViewBottom]];
    
    _birthdayTableView.estimatedRowHeight = 88;
    _birthdayTableView.rowHeight = UITableViewAutomaticDimension;
    
    
    self.birthdayTableView.editing = FALSE;

}

- (void)viewWillDisappear:(BOOL)animated {
//    externBirthdayInfo = self.birthdayInfo;
}

- (void)viewWillAppear:(BOOL)animated {
//    externBirthdayInfo = self.birthdayInfo;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"isSaved"]) {
        NSString *flag = [change objectForKey:@"new"];
        if ([flag isEqualToString:@"TRUE"] && self.curIndex == -1) {
            NSLog(@"保存了新的添加");
            curBirthdayInfoCount++;
            [[self mutableArrayValueForKeyPath:@"birthdayInfo"] insertObject:[_tempCellModel copy] atIndex:0];
            [externBirthdayInfo insertObject:[_tempCellModel copy] atIndex:0];
            
//            [self.birthdayInfo insertObject:[_tempCellModel copy] atIndex:0];
            [self.birthdayTableView reloadData];
        } else if ([flag isEqualToString:@"TRUE"] && self.curIndex != -1) {
            NSLog(@"保存了cell的编辑");
            [[self mutableArrayValueForKeyPath:@"birthdayInfo"] replaceObjectAtIndex:_curIndex withObject:[_tempCellModel copy]];
//            [self.birthdayInfo replaceObjectAtIndex:_curIndex withObject:[_tempCellModel copy]];
            [externBirthdayInfo replaceObjectAtIndex:_curIndex withObject:[_tempCellModel copy]];
            [self.birthdayTableView reloadData];
        } else if ([flag isEqualToString:@"FALSE"]) {
            //do nothing
             NSLog(@"取消");
            [self.birthdayTableView reloadData];
        } else if ([flag isEqualToString:@"DELETE"] && _curIndex != -1) {
            if (self.birthdayInfo[_curIndex].on) {
                NSLog(@"取消推送 %@, 标签 = %@",  self.birthdayInfo[_curIndex].prompt, self.birthdayInfo[_curIndex].remindTime);
            }
            curBirthdayInfoCount--;
            [[self mutableArrayValueForKeyPath:@"birthdayInfo"] removeObjectAtIndex:_curIndex];
            [externBirthdayInfo removeObjectAtIndex:_curIndex];
            
//            [self.birthdayInfo removeObjectAtIndex:_curIndex];
            [self.birthdayTableView reloadData];
        }
        NSLog(@"当前list行数 = %lu", (unsigned long)[self.birthdayInfo count]);
        for (int i = 0; i < self.birthdayInfo.count; i++) {
            NSLog(@"%@ -- extern =  %@", self.birthdayInfo[i], externBirthdayInfo[i]);
        }
    }
    
    //监听数组的变化
    if ([keyPath isEqualToString:@"birthdayInfo"]) {
        if (curBirthdayInfoCount > 0) {
            self.navigationItem.leftBarButtonItem.enabled = TRUE;
        } else {
            self.navigationItem.leftBarButtonItem = _edit;
            self.navigationItem.leftBarButtonItem.enabled = FALSE;
            //当数组没有元素的时候一定要设置
            self.birthdayTableView.editing = FALSE;
            self.isBirthdayTableEditing = @"FALSE";
            self.navigationItem.rightBarButtonItem.enabled = TRUE;
            
        }
    }
    
    
    //监听是否在编辑状态, 编辑状态下cell不可点击
    if ([keyPath isEqualToString:@"isBirthdayTableEditing"]) {
        NSString *editFlag = [change objectForKey:@"new"];
        if ([editFlag isEqualToString:@"TRUE"]) {
            self.navigationItem.rightBarButtonItem.enabled = FALSE;
        } else {
            self.navigationItem.rightBarButtonItem.enabled = TRUE;
        }

    }
    
}

//添加的时候，需要将新的信息插入
- (void)addBirthday {
    BirthdayInfoAddedViewController *b = [[BirthdayInfoAddedViewController alloc] init];
    //表示添加新的info,直接传一个空的过去
    [b addObserver:b forKeyPath:@"isAdd" options:NSKeyValueObservingOptionNew context:nil];
    
    self.curIndex = -1;
    //清空数据
    [self.tempCellModel clear];
    
    b.tempBirthdayInfo = [_tempCellModel copy];
 
    b.isAdd = @"TRUE";
    __weak BirthdayTableViewController *weakSelf = self;
    
    //在编辑vc中，返回时调用block给其赋值
    b.isSavedBlock = ^(NSString *isSaved) {
        weakSelf.isSaved = [isSaved copy];
        NSLog(@"btlvc is saved block called, isSaved = %@", weakSelf.isSaved);
    };
    
    b.returnPromptToBirthdayListBlock = ^(BirthdayCellModel *bcm) {
        weakSelf.tempCellModel = [bcm copy];
        NSLog(@"btlvc received bcm in tempCellModel");
    };

    [self.navigationController pushViewController:b animated:YES];
}




- (void)editBirthday {

    [_birthdayTableView setEditing:TRUE animated:TRUE];
    self.isBirthdayTableEditing = @"TRUE";

    //不设置为true的时候，编辑状态下无法响应cell的didselect
//    [_birthdayTableView setAllowsSelectionDuringEditing:TRUE];
    
    self.navigationItem.leftBarButtonItem = _finished;
    
}

- (void)finishEditBirthday {
    [_birthdayTableView setEditing:FALSE animated:TRUE];
    self.isBirthdayTableEditing = @"FALSE";
    
    self.navigationItem.leftBarButtonItem = _edit;
    //添加reloadData动画

}

- (void)dealloc {

    
    [self removeObserver:self forKeyPath:@"isSaved"];
    [self removeObserver:self forKeyPath:@"birthdayInfo"];
    [self removeObserver:self forKeyPath:@"isBirthdayTableEditing"];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    CGSize height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
//    
//    CGFloat h = cell.frame.size.height;
//    NSLog(@"willDisplayCell, frame height = %f, systemLayoutSizeFittingSize = %f", h, height.height);
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_birthdayInfo count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    BirthdayCell *item = [BirthdayCell initWithTableView:tableView andReuseIdentifier:BirthdayCellIdentifier];

    //设置时间
    NSDate *date = _birthdayInfo[indexPath.row].prompt;
    //保存时间
    item.date = date;
    
    NSTimeInterval sec = [date timeIntervalSinceNow];
    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
    
    //设置时间输出格式：
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MM月dd日"];
    NSString *na = [df stringFromDate:currentDate];
    
    [item.prompt setText:na];

    [item.createdTime setText:_birthdayInfo[indexPath.row].createdTime];
    [item.remindTime setText:_birthdayInfo[indexPath.row].remindTime];
    //保持数据与视图显示的数据一致
    [item.on addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    if (_birthdayInfo[indexPath.row].isOn) {
        [item.on setOn:TRUE];
        item.isSwitchOn = @"TRUE";
    } else {
        [item.on setOn:FALSE];
        item.isSwitchOn = @"FALSE";
    }
    //UIControlEventValueChanged与touchupinside的区别，后者会发生按钮值改变了，但是没有触发点击事件
    return item;
}

//用来添加或者取消推送
- (void)switchChanged:(id)sender {
    BirthdayCell *curCell = (BirthdayCell *)[[sender superview] superview];
    NSIndexPath *curIndexPath = [_birthdayTableView indexPathForCell:curCell];
    if ([curCell.isSwitchOn isEqualToString:@"TRUE"]) {
        curCell.isSwitchOn = @"FALSE";
        self.birthdayInfo[curIndexPath.row].on = FALSE;
        externBirthdayInfo[curIndexPath.row].on = FALSE;
        //取消本地推送
        [self cancelLocalNotifications:self.birthdayInfo[curIndexPath.row]];
    } else {
        curCell.isSwitchOn = @"TRUE";
        self.birthdayInfo[curIndexPath.row].on = TRUE;
        externBirthdayInfo[curIndexPath.row].on = TRUE;
        //添加本地推送
        [self addLocalNotifications:self.birthdayInfo[curIndexPath.row]];
    }
}

//添加本地推送
- (void)addLocalNotifications:(BirthdayCellModel *)bcm {
    // 初始化本地通知
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    // 通知触发时间
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
    localNotification.timeZone = [NSTimeZone systemTimeZone];
    // 触发后，弹出警告框中显示的内容
    localNotification.alertBody = bcm.remindTime;
    // 触发时的声音（这里选择的系统默认声音）
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    // 触发频率（repeatInterval是一个枚举值，可以选择每分、每小时、每天、每年等）
    localNotification.repeatInterval = NSCalendarUnitYear;
    // 需要在App icon上显示的未读通知数（设置为1时，多个通知未读，系统会自动加1，如果不需要显示未读数，这里可以设置0）
    localNotification.applicationIconBadgeNumber = 1;
    // 设置通知的id，可用于通知移除，也可以传递其他值，当通知触发时可以获取
    localNotification.userInfo = @{@"id" : bcm.remindTime};
    // 注册本地通知
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

//取消本地推送
- (void)cancelLocalNotifications:(BirthdayCellModel *)bcm {
    // 取出全部本地通知
    NSArray *notifications = [UIApplication sharedApplication].scheduledLocalNotifications;
    // 设置要移除的通知id
//    NSDate *notificationId = bcm.prompt;
    NSString *notificationId = bcm.remindTime;
    // 遍历进行移除
    for (UILocalNotification *localNotification in notifications) {
        // 将每个通知的id取出来进行对比
        NSLog(@"%@", [localNotification.userInfo objectForKey:@"id"]);
        if ([[localNotification.userInfo objectForKey:@"id"] isEqualToString:notificationId]) {
            [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    curBirthdayInfoCount--;
    [[self mutableArrayValueForKeyPath:@"birthdayInfo"] removeObjectAtIndex:indexPath.row];
    [externBirthdayInfo removeObjectAtIndex:indexPath.row];
    
    NSArray<NSIndexPath *> *d = @[indexPath];
    BirthdayCell *c = [self.birthdayTableView cellForRowAtIndexPath:indexPath];
    if ([c.isSwitchOn isEqualToString:@"TRUE"]) {
        NSArray *notifications = [UIApplication sharedApplication].scheduledLocalNotifications;
        NSString *notificationId = c.remindTime.text;
        for (UILocalNotification *localNotification in notifications) {
            if ([[localNotification.userInfo objectForKey:@"id"] isEqualToString:notificationId]) {
                [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
            }
        }
    }
    
    [self.birthdayTableView deleteRowsAtIndexPaths:d withRowAnimation:UITableViewRowAnimationLeft];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"当前选中的是第%d行", (long)indexPath.row);
    BirthdayInfoAddedViewController *b = [[BirthdayInfoAddedViewController alloc] init];
    
    self.curIndex = indexPath.row;
    //一定要注意这里，不用copy的话会直接改掉原数组中的元素
    self.tempCellModel = [_birthdayInfo[_curIndex] copy];
    b.tempBirthdayInfo = self.tempCellModel;
    //标志不是添加而是选择的cell
    [b addObserver:b forKeyPath:@"isAdd" options:NSKeyValueObservingOptionNew context:nil];
    b.isAdd = @"FALSE";
    
    __weak BirthdayTableViewController *weakSelf = self;
    b.returnPromptToBirthdayListBlock = ^(BirthdayCellModel *model) {
        weakSelf.tempCellModel = [model copy];
        NSLog(@"select cell 返回，收到数据 tempCellModel = %@;", model);
    };
    b.isSavedBlock = ^(NSString *isSaved) {
        weakSelf.isSaved = [isSaved copy];
        NSLog(@"select cell 返回，weakSelf.isSaved = %@", isSaved);
    };
    
    [self.navigationController pushViewController:b animated:TRUE];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
