//
//  timeDistributeCell.m
//  TimePie
//
//  Created by 大畅 on 14-4-2.
//  Copyright (c) 2014年 TimePieOrg. All rights reserved.
//

#import "timeDistributeCell.h"
#import "BasicUIColor+UIPosition.h"
#import "tDCPieChart.h"
#import "UIView+Frame.h"

#import "TimingItemStore.h"
#import "Tag.h"

#define CHART_START_COUNT 900

@implementation timeDistributeCell

- (void)awakeFromNib
{
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self initNeededData];
        [self initScrollVessel];
        //[self initDistributeGraph];
    }
    return self;
}

- (void)initNeededData
{
    tagList = [[TimingItemStore timingItemStore] getAllTags];
    colorList = [NSMutableArray arrayWithObjects:REDNO1,BLUENO2,GREENNO3,PINKNO04,BROWNN05,YELLOWN06, PURPLEN07, P01N08, P01N09, P01N10, nil];
    lightColorList = [NSMutableArray arrayWithObjects:RedNO1_light, BLUENO2_light, GREENNO3_light, PINKNO04_light, BROWNN05_light, YELLOWN06_light, PURPLEN07_light, P01N08_light, P01N09_light, P01N10_light, nil];
    
    timeOfEachTag = [[NSMutableArray alloc] init];
    tDCPieChartList = [[NSMutableArray alloc] init];
}

- (void)initScrollVessel
{
    _vessel = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 142)];
    int vesselContentPageCount = tagList.count % 3==0 ? tagList.count/3 : tagList.count / 3 + 1;
    _vessel.contentSize = CGSizeMake(SCREEN_WIDTH * vesselContentPageCount, _vessel.frame.size.height);
    _vessel.pagingEnabled = YES;
    _vessel.showsHorizontalScrollIndicator = NO;
    [self addSubview:_vessel];
}

- (void)initDistributeGraphInView:(UIView*)view
{
    if (tagList.count > 0)
    {
        CGFloat startPos = 10;
        for (int i = 0; i < tagList.count; i++)
        {
            if ([view viewWithTag:CHART_START_COUNT + i])
                [[view viewWithTag:CHART_START_COUNT + i] removeFromSuperview];
            if (i > 5) startPos = 50;
            else if (i > 2) startPos = 30;
            else startPos = 10;
            tDCPieChart *tempChart =[[tDCPieChart alloc] initWithFrame:CGRectMake(startPos + 100 * i, 10, 100, 130)];
            tempChart.tag = CHART_START_COUNT + i;
            
            NSString* tagName =[NSString stringWithFormat:@"%@",(Tag*)[[tagList objectAtIndex:i] tag_name]];
            if([tagName isEqualToString:@"(null)"]){
                tagName = @"其他";
            }
            
            [tempChart initInfosWithColor:[colorList objectAtIndex:i] lightColor:[lightColorList objectAtIndex:i] Name:tagName Percent:[[timeOfEachTag objectAtIndex:i] floatValue] / 100 PercentString:[NSString stringWithFormat:@"%d",[[timeOfEachTag objectAtIndex:i] integerValue]]];
            [tDCPieChartList addObject:tempChart];
            [view addSubview:[tDCPieChartList objectAtIndex:i]];
        }
    }
    else NSLog(@"Create new items to view history stats");
}

- (void)generateTimeOfEachTag
{
    int calibrateResult = 0;
    for (int i = 0; i < tagList.count; i++)
    {
        NSNumber *tempResult = [NSNumber numberWithFloat:[[TimingItemStore timingItemStore] getTotalHoursByTag:[[tagList objectAtIndex:i] tag_name]].floatValue * 100 / totalTimeOfTags.floatValue];
        calibrateResult += tempResult.intValue;
        [timeOfEachTag addObject:tempResult];
    }
    if (calibrateResult < 100) {
        [timeOfEachTag replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:[[TimingItemStore timingItemStore] getTotalHoursByTag:[[tagList objectAtIndex:0] tag_name]].floatValue * 100 / totalTimeOfTags.floatValue + 1]];
    }
    [self initDistributeGraphInView:_vessel];
}

- (void)reloadTotalHours:(NSNumber *)tHours
{
    totalTime = tHours;
    [self generateTimeOfEachTag];
}

- (void)reloadTotalHoursForDistributeGraph
{
    for (int i = 0; i < tagList.count; i++)
    {
        NSNumber *tempResult = [NSNumber numberWithFloat:[[TimingItemStore timingItemStore] getTotalHoursByTag:[[tagList objectAtIndex:i] tag_name]].floatValue];
        CGFloat tempFloatValue = totalTimeOfTags.floatValue;
        totalTimeOfTags = [NSNumber numberWithFloat:tempResult.floatValue + tempFloatValue];
    }
    [self generateTimeOfEachTag];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
