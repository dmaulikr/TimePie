//
//  RoutineItemViewController.h
//  TimePie
//
//  Created by 大畅 on 14-5-12.
//  Copyright (c) 2014年 TimePieOrg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RoutineItemViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITableView *routineTableView;
@property (strong, nonatomic) NSArray *routineDataArray;

@end
