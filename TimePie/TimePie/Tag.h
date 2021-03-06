//
//  Tag.h
//  TimePie
//
//  Created by Max Lu on 5/7/14.
//  Copyright (c) 2014 TimePieOrg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TimingItemEntity, User;

@interface Tag : NSManagedObject

@property (nonatomic, retain) NSString * tag_name;
@property (nonatomic, retain) NSNumber * tracking;
@property (nonatomic, retain) NSSet *item;
@property (nonatomic, retain) User *user;
@end

@interface Tag (CoreDataGeneratedAccessors)

- (void)addItemObject:(TimingItemEntity *)value;
- (void)removeItemObject:(TimingItemEntity *)value;
- (void)addItem:(NSSet *)values;
- (void)removeItem:(NSSet *)values;

@end
