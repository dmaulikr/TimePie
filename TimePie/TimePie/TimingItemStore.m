//
//  TimingItemStore.m
//  TimePie
//
//  Created by Max Lu on 4/30/14.
//  Copyright (c) 2014 TimePieOrg. All rights reserved.
//

#import "TimingItemStore.h"
#import "TimingItem1.h"
#import "BasicUIColor+UIPosition.h"
#import "ColorThemes.h"
#import "Tag.h"
#import "DateHelper.h"
#import "TimingItemEntity.h"
#import "Daily.h"
#import "DailyMark.h"

@implementation TimingItemStore


@synthesize managedObjectContext;
@synthesize managedObjectModel;
@synthesize persistentStoreCoordinator;


- (id)init
{
    self= [super init];
    if(self){
        if(!allItems){
            allItems = [[NSMutableArray alloc] init];
        }
        
    }
    return self;
}




- (NSArray *)allItems
{
    if(!allItems){
        allItems = [[NSMutableArray alloc] init];
    }
    return allItems;
}




//create item methods automatically insert the item into   allItem
//The color number of an item is picked based on the number of objects in   allItem
//Later we can use ColorTheme to manage the colors to avoid the duplicated colors.
- (TimingItem *)createItem{
    TimingItem *i = [TimingItem randomItem];
    i.itemColor = [[ColorThemes colorThemes] getAColor];
    
    [allItems addObject:i];
    NSLog(@"create item!");
    return i;
}

- (TimingItem *)createItem:(TimingItem*)item
{
    TimingItem *i = [TimingItem randomItem];
    i.itemColor = item.itemColor;
    i.lastCheck = item.lastCheck;
    i.itemName = item.itemName;
    item.time +=1;
    i.time = item.time;
    i.timing= item.timing;
    i.tracking = item.tracking;
    [allItems insertObject:i atIndex:[allItems count]];
    NSLog(@"create item!");
    
    return i;
}


//Class method, reture a single TimingItemStore object.
+ (TimingItemStore*) timingItemStore
{
    static TimingItemStore * timingItemStore = nil;
    if(!timingItemStore){
        timingItemStore = [[super allocWithZone:nil] init];
    }
    return timingItemStore;
}


+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [self timingItemStore];
}

//remove the item from allItem
//**this method DO NOT remove item from coredata
- (void)removeItem:(TimingItem *)i
{
    [allItems removeObjectIdenticalTo:i];
    [self deleteItem:i];
    [[ColorThemes colorThemes] initTaken:allItems];
}



- (void)moveItemAtIndex:(int)from toIndex:(int)to
{
    if(from==to){
        return;
    }
    TimingItem *i = [allItems objectAtIndex:from];
    [allItems removeObjectAtIndex:from];
    [allItems insertObject:i atIndex:to];
}


- (id)getItemAtIndex:(int)index
{
    if(!allItems||[allItems count]==0){
        return nil;
    }
    TimingItem *item= [allItems objectAtIndex:index];
    if(item){
        return item;
    }else{
        return nil;
    }
}




// Save items array to core data
- (BOOL)saveData
{
    BOOL result = NO;
    NSLog(@"savedata");
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
//    [self deletaAllItem];
//    NSLog(@"Save!");
    for(TimingItem * item in allItems){
        TimingItemEntity *i = [self getItemEntityByItem:item];
        [i setValue:item.itemName forKey:@"item_name"];
        [i setValue:[NSNumber numberWithInt:item.itemID] forKey:@"item_id"];
        [i setValue:[NSNumber numberWithDouble:item.time] forKey:@"time"];
        [i setValue:item.dateCreated forKey:@"date_created"];
        [i setValue:item.lastCheck forKey:@"last_check"];
        [i setValue:[NSNumber numberWithInt:item.itemColor] forKey:@"color_number"];
        [i setValue:[NSNumber numberWithBool:item.timing] forKeyPath:@"timing"];
        [i setValue:[NSNumber numberWithBool:item.tracking] forKey:@"tracking"];
        [context updatedObjects];
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            result = NO;
        }
    }
    return result;
}





- (BOOL)setNameByItem:(TimingItem*)item
               toName:(NSString*)itemName
{
    NSString* fromName = item.itemName;
    item.itemName = itemName;
//    NSLog(@"%d",[[self allItems] count]);
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"item_name == %@",fromName]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (TimingItemEntity *i in fetchedObjects){
        i.item_name = itemName;
    }
    
    BOOL result = YES;
    [context updatedObjects];
    if ([context save:&error]) {
        NSLog(@"Did it!");
    } else {
        NSLog(@"Could not do it: %@", [error localizedDescription]);
        result = NO;
    }
    
    
    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:@"Daily" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"item_name == %@", fromName]];
    
    fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (Daily *i in fetchedObjects){
        i.item_name = itemName;
    }
    
    [context updatedObjects];
    if ([context save:&error]) {
        NSLog(@"Did it!");
    } else {
        NSLog(@"Could not do it: %@", [error localizedDescription]);
        result = NO;
    }
    
    
    
    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:@"DailyMark" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"daily == %@", fromName]];
    
    fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (DailyMark *i in fetchedObjects){
        i.daily = itemName;
    }
    
    [context updatedObjects];
    if ([context save:&error]) {
        NSLog(@"Did it!");
    } else {
        NSLog(@"Could not do it: %@", [error localizedDescription]);
        result = NO;
    }
    

    [self restoreData];
    return result;
}

- (BOOL)setItemTime:(TimingItem*)item
           withTime:(double)time
{
    item.time = time;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"item_name == %@ && date_created == %@",item.itemName, item.dateCreated]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if([fetchedObjects count] == 0){
        return NO;
    }
    for (TimingItemEntity *i in fetchedObjects){
        i.time = [NSNumber numberWithDouble:time];
    }
    
    BOOL result = YES;
    [context updatedObjects];
    if ([context save:&error]) {
        NSLog(@"Did it!");
    } else {
        NSLog(@"Could not do it: %@", [error localizedDescription]);
        result = NO;
    }
    
    return result;
}



- (BOOL)setColorByItem:(TimingItem *)item
               toColor:(int)color
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"item_name == %@",item.itemName]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (TimingItemEntity *i in fetchedObjects){
        i.color_number = [NSNumber numberWithInt:color];
    }
    
    BOOL result = YES;
    [context updatedObjects];
    if ([context save:&error]) {
        NSLog(@"Did it!");
    } else {
        NSLog(@"Could not do it: %@", [error localizedDescription]);
        result = NO;
    }
    
    [self restoreData];
    return result;

}



//check if there is a same item existed
//###Deprecated####
- (BOOL)checkExisted:(TimingItem*)item
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"date_created == %@",item.dateCreated]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *i in fetchedObjects){
        return YES;
    }
    return NO;
}





//insert an item to coredata
// no longer public
- (BOOL)insertItem:(TimingItem*)item
{
    BOOL result = YES;
    
    //insert
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSManagedObject * i = [self saveItemEntity:item];

    /////
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        result = NO;
    }
    
    return result;
}




// update an item to coredata
// no longer public
- (BOOL)updateItem:(TimingItem*)item
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    BOOL result = YES;
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"date_created == %@",item.dateCreated]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *i in fetchedObjects) {
        [self updateItemEntityFromItem:item to:i];
    }
    
    [context updatedObjects];
    if ([context save:&error]) {
        NSLog(@"Did it!");
    } else {
        NSLog(@"Could not do it: %@", [error localizedDescription]);
        result = NO;
    }
    
    
    return result;
}

// delete an item from coredata
// no longer public
-(BOOL)deleteItem:(TimingItem*)item
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    BOOL result =YES;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"date_created == %@",item.dateCreated]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        [context deleteObject:info];
    }
    
    
    if ([context save:&error]) {
        NSLog(@"Did it!");
    } else {
        NSLog(@"Could not do it: %@", [error localizedDescription]);
        result = NO;
    }
    
    
    return result;
}




- (BOOL)deleteAllData
{
    allItems = [[NSMutableArray alloc] init];
    
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    BOOL result =YES;
    
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        [context deleteObject:info];
    }
    
    
    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        [context deleteObject:info];
    }
    
    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        [context deleteObject:info];
    }
    
    
    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:@"Daily" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        [context deleteObject:info];
    }
    
    
    
    if ([context save:&error]) {
        NSLog(@"Did it!");
    } else {
        NSLog(@"Could not do it: %@", [error localizedDescription]);
        result = NO;
    }
    
    
    
    return result;
}




// delete all items from coredata
- (BOOL)deletaAllItem
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    //Read
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        [context deleteObject:info];
    }
    
    if ([context save:&error]) {
        NSLog(@"Did it!");
    } else {
        NSLog(@"Could not do it: %@", [error localizedDescription]);
    }
    
    
    
    return YES;
}

// view all items in coredata
- (NSUInteger)viewAllItem
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        
        NSLog(@"Name: %@", [info valueForKey:@"item_name"]);
        NSLog(@"itemID: %@", [info valueForKey:@"item_id"]);
        NSLog(@"time: %@", [info valueForKey:@"time"]);
        NSLog(@"date_created: %@", [info valueForKey:@"date_created"]);
        
    }
    
    return [fetchedObjects count];
}

- (BOOL)restoreData
{
    NSLog(@"restore data!");
    allItems = nil;
    allItems = [[NSMutableArray alloc] init];
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    
    NSDate *today = [NSDate date];
    NSDate *startOfToday = [DateHelper beginningOfDay:today];
    NSDate *endOfToday = [DateHelper endOfDay:today];
    
    NSLog([NSString stringWithFormat:@"start: %@",startOfToday]);
    NSLog([NSString stringWithFormat:@"end: %@",endOfToday]);
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"((date_created >= %@) AND (date_created <= %@)) OR timing = %@", startOfToday, endOfToday, [NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES]]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    
    NSLog(@"[restoredata]number of object returned: %d",[fetchedObjects count]);
    for (TimingItemEntity *i in fetchedObjects) {
        TimingItem* item = [self restoreItem:i];

        //NSLog(@"item!!!");
        if(item.timing == YES){// if i is a timing item
            NSLog(@"timing item!");

            BOOL flag = true;
            if ([item.dateCreated compare:startOfToday] == NSOrderedAscending) {
                flag = false;
            }
            if ([item.dateCreated compare:endOfToday] == NSOrderedDescending) {
                flag = false;
            }
            
            if(flag)   //timing item is today's item;  Do nothing;
            {
                NSLog(@"timing item is today's item, do nothing");
            }else{    //timing item is not today's item; create new item and abandon this item;
                NSLog(@"Timing item is not today's item; create a new one and reload.");
                TimingItem* newTimingItem = [self createItem:item];
                item.timing = NO;
                // update item time = 0 in new day ;
//                newTimingItem.time = 0;
                [self updateItem:item];
                [allItems removeObjectIdenticalTo:item];
                [self saveData];
                //[self restoreData];
            }
        }
        
        
    }
    
    
    
    
    
    for(int i=0;i<[allItems count];i++){
        if(((TimingItem*)[allItems objectAtIndex:i]).timing == YES){
            [self moveItemAtIndex:i toIndex:0];
        }
    }
    
    if(allItems&&[allItems count]!=0){
        [[[self allItems] objectAtIndex:0] check:YES];
        NSLog([[[self allItems] objectAtIndex:0] itemName]);
    }
    
    
    [[ColorThemes colorThemes] initTaken:allItems];
    
    
    
    
    // daily handler:
    NSArray* dailyArray =[self getAllDaily];
    for(Daily* d in dailyArray){
        NSString* item_name = d.item_name;
        
        BOOL flag = false;
        for(TimingItem* item in allItems){
            if([item.itemName isEqualToString:item_name]){
                flag = true;
                break;
            }
        }
        
        

        if(flag){
            //if daily item existed do nothing
            [self createDailyMark:d date:[DateHelper beginningOfDay:[NSDate date]]];
        }else{
            //else create new item
            if([self createDailyMark:d date:[DateHelper beginningOfDay:[NSDate date]]]){
                TimingItem* item = [[TimingItemStore timingItemStore] createItem];
                item.itemName = item_name;
                if([[TimingItemStore timingItemStore] allItems].count == 0){
                    item.timing= YES;
                }
                [[TimingItemStore timingItemStore] saveData];
                if(d.tag_name){
                    [self addTag:item TagName:d.tag_name];
                }
            }else{
                NSLog(@"mark mode do nothing");
            }
        }
    }
    
    return YES;
}



// if succeed return YES;
// if existed return NO;
- (BOOL)createDailyMark:(Daily*)daily
                   date:(NSDate*)date
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    
    DailyMark * dailyMark;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"DailyMark" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"daily == %@ AND date == %@",daily.item_name, date]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if([fetchedObjects count]==0){
        //If not existed, create one
        dailyMark = (DailyMark*)[NSEntityDescription insertNewObjectForEntityForName:@"DailyMark"
                                                  inManagedObjectContext:context];
        dailyMark.daily = daily.item_name;
        dailyMark.date = date;
    }else{
        //If existed, return
        return NO;
    }
    
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return false;
    }
    
    return YES;
}






- (NSArray*)getTimingItemsByDate:(NSDate *)date
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSDate *startOfToday = [DateHelper beginningOfDay:date];
    NSDate *endOfToday = [DateHelper endOfDay:date];
    
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(date_created >= %@) AND (date_created <= %@)", startOfToday, endOfToday]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    NSLog(@"[restoredata]number of object returned: %d",[fetchedObjects count]);
    for(NSManagedObject* i in fetchedObjects){
        NSLog(@"item:%@", i);
    }
    return fetchedObjects;
}





- (NSArray*)getAllTags
{
    NSLog(@"get all tags");
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Tag" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if([fetchedObjects count]==0){
        return nil;
    }
    for(id i in fetchedObjects){
        NSLog(@"TAGS ARE%@",i);
    }
    return fetchedObjects;
}



- (Tag* )getTagByItem:(NSString*)itemName
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"item_name == %@", itemName]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if([fetchedObjects count] == 0){
        return nil;
    }else{
        return ((TimingItemEntity*)[fetchedObjects objectAtIndex:0]).tag;
    }
    return nil;
}



// restore a single item from NSManagedObject
- (TimingItem* )restoreItem:(NSManagedObject *)i
{
    TimingItem * item = [TimingItem randomItem];
    item.itemName =[i valueForKey:@"item_name"];
    item.time = [[i valueForKey:@"time"] doubleValue];
    item.itemID =[[i valueForKey:@"item_id"] integerValue];
    item.dateCreated = [i valueForKey:@"date_created"];
    item.lastCheck = [i valueForKey:@"last_check"];
    item.itemColor = [[i valueForKey:@"color_number"] integerValue];
    item.timing = [[i valueForKey:@"timing"] boolValue];
    item.tracking = [[i valueForKey:@"tracking"] boolValue];
    [allItems addObject:item];
    return item;
}

- (NSManagedObject *)updateItemEntityFromItem:(TimingItem*)item
                             to:(NSManagedObject*)i
{
    
    [i setValue:item.itemName forKey:@"item_name"];
    [i setValue:[NSNumber numberWithInt:item.itemID] forKey:@"item_id"];
    [i setValue:[NSNumber numberWithDouble:item.time] forKey:@"time"];
    [i setValue:item.dateCreated forKey:@"date_created"];
    [i setValue:item.lastCheck forKey:@"last_check"];
    [i setValue:[NSNumber numberWithInt:item.itemColor] forKey:@"color_number"];
    [i setValue:[NSNumber numberWithBool:item.timing] forKey:@"timing"];
    [i setValue:[NSNumber numberWithBool:item.tracking] forKey:@"tracking"];
    return i;
}



//get a single item entity from TimingTime Class
//no longer used
- (NSManagedObject *)saveItemEntity:(TimingItem *)item
{
    //insert
    NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObject *i = [NSEntityDescription
                          insertNewObjectForEntityForName:@"TimingItemEntity"
                          inManagedObjectContext:context];
    
    [i setValue:item.itemName forKey:@"item_name"];
    [i setValue:[NSNumber numberWithInt:item.itemID] forKey:@"item_id"];
    [i setValue:[NSNumber numberWithDouble:item.time] forKey:@"time"];
    [i setValue:item.dateCreated forKey:@"date_created"];
    [i setValue:item.lastCheck forKey:@"last_check"];
    [i setValue:[NSNumber numberWithInt:item.itemColor] forKey:@"color_number"];
    [i setValue:[NSNumber numberWithBool:item.timing] forKey:@"timing"];
    [i setValue:[NSNumber numberWithBool:item.tracking] forKey:@"tracking"];
    
    return i;
}



- (BOOL)addTag:(NSString *)name
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    
    Tag * tag ;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Tag" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tag_name == %@",name]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if([fetchedObjects count]==0){
        //If not existed, create one
        tag = (Tag*)[NSEntityDescription insertNewObjectForEntityForName:@"Tag"
                                                  inManagedObjectContext:context];
        [tag setValue:name forKey:@"tag_name"];
    }else{
        //If existed, return
        return YES;
    }
    
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return false;
    }

    return NO;
}

- (BOOL)setTagByItem:(TimingItem*)item
             withTag:(NSString*)tagName
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    Tag * tag ;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Tag" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tag_name == %@",tagName]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"Name: %@", [info valueForKey:@"tag_name"]);
    }
    if([fetchedObjects count]==0){
        //if not existed, create one;
        tag = (Tag*)[NSEntityDescription insertNewObjectForEntityForName:@"Tag"
                                                  inManagedObjectContext:context];
        [tag setValue:tagName forKey:@"tag_name"];
    }else{
        // if existed
        tag = (Tag*)[fetchedObjects objectAtIndex:0];
    }
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return false;
    }
    
    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"item_name == %@",item.itemName]];
    
    fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    
    if([fetchedObjects count]==0){
        [self saveItemEntity:item];
        [self addTag:item TagName:tagName];
    }else{
        for (TimingItemEntity *i in fetchedObjects) {
            NSLog(@"Name: %@", [i valueForKey:@"item_name"]);
            i.tag = tag;
        }
    }
    
    BOOL result = YES;
    [context updatedObjects];
    if ([context save:&error]) {
        NSLog(@"Did it!");
    } else {
        NSLog(@"Could not do it: %@", [error localizedDescription]);
        result = NO;
    }
    return result;
}


- (BOOL)addTag:(TimingItem *)item
       TagName:(NSString *)name
{
    
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    Tag * tag ;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Tag" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tag_name == %@",name]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"Name: %@", [info valueForKey:@"tag_name"]);
    }
    if([fetchedObjects count]==0){
        tag = (Tag*)[NSEntityDescription insertNewObjectForEntityForName:@"Tag"
                              inManagedObjectContext:context];
        
        [tag setValue:name forKey:@"tag_name"];
    }else{
        tag = (Tag*)[fetchedObjects objectAtIndex:0];
    }
    
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return false;
    }
    
    
    
    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"date_created == %@",item.dateCreated]];
    
    fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"Name: %@", [info valueForKey:@"item_name"]);
    }
    TimingItemEntity * i;
    if([fetchedObjects count]==0){
        i = (TimingItemEntity*)[self saveItemEntity:item];
    }else{
        i= [fetchedObjects objectAtIndex:0];
    }
    

    i.tag = tag;
    [tag addItemObject:i];
    
    [context updatedObjects];
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return false;
    }
    
    
    
    /*
    ///check if it works
    
    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tag_name == %@",name]];
    
    fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    tag = [fetchedObjects objectAtIndex:0];
    for(TimingItemEntity * i  in tag.item){
        NSLog(@"item entity for tag:%@", i);
    }

    */
    return true;
}



- (NSManagedObject *)getItemEntityByItem: (TimingItem*)item
{
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"date_created == %@",item.dateCreated]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if([fetchedObjects count]==0){
        NSManagedObject *i = [NSEntityDescription
                              insertNewObjectForEntityForName:@"TimingItemEntity"
                              inManagedObjectContext:context];
        return i;
    }

    for(NSManagedObject * i in fetchedObjects){
        NSLog(@"got item!%@",i);
        return i;
    }
    
    
    return nil;
}



- (NSArray *)getTimingItemsByTagName:(NSString *)tagName
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    Tag * tag ;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Tag" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tag_name == %@",tagName]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"Name: %@", [info valueForKey:@"tag_name"]);
    }
    
    if([fetchedObjects count]==0){
        tag = (Tag*)[NSEntityDescription insertNewObjectForEntityForName:@"Tag"
                                                  inManagedObjectContext:context];
        [tag setValue:tagName forKey:@"tag_name"];
    }else{
        tag = (Tag*)[fetchedObjects objectAtIndex:0];
    }
    
    
    for(TimingItemEntity * i  in tag.item){
        NSLog(@"item entity for tag:%@", i);
    }
    
    if(tag==nil){
        return nil;
    }
    
    return [tag.item allObjects];
}

/**** PersonalCenter Usage
 **/
- (NSNumber *)getDailyTimeByTagName:(NSString*)tagName
                               date:(NSDate*)date
{
    NSArray * items = [self getDailyTimingsItemByTagName:tagName date:date];
    double total = 0;
    for(TimingItemEntity * item in items){
        total+= [item.time doubleValue];
    }
    NSLog(@"total time:%f", total);
    return [NSNumber numberWithDouble:total];
}


- (NSMutableArray *)getDailyTimingsItemByTagName:(NSString*)tagName
                                    date:(NSDate *)date
{
    NSArray * items = [self getTimingItemsByTagName:tagName];
    NSLog(@"%@",items);
    NSDate * startDate = [DateHelper beginningOfDay:date];
    NSDate * endDate = [DateHelper endOfDay:date];
    NSLog(@"current date:%@",date);
    NSLog(@"start date:%@",startDate);
    NSLog(@"end date:%@",endDate);
    NSMutableArray* results = [[NSMutableArray alloc] init];
    for(TimingItemEntity * item in items){
        BOOL flag = true;
        if ([item.date_created compare:startDate] == NSOrderedAscending) {
            flag = false;
        }
        if ([item.date_created compare:endDate] == NSOrderedDescending) {
            flag = false;
        }
        if(flag){
            [results addObject:item];
        }
        
    }
    NSLog(@"results count:%d",[results count]);
    return results;
}



- (NSNumber*)getDailyTimeByItemName:(NSString*)itemName date:(NSDate*)date
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"item_name == %@",itemName]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"Name: %@", [info valueForKey:@"item_name"]);
    }
    
    NSDate * startDate = [DateHelper beginningOfDay:date];
    NSDate * endDate = [DateHelper endOfDay:date];
    
    double timesum=0;
    for(TimingItemEntity * item in fetchedObjects){
        BOOL flag = true;
        if ([item.date_created compare:startDate] == NSOrderedAscending) {
            flag = false;
        }
        if ([item.date_created compare:endDate] == NSOrderedDescending) {
            flag = false;
        }
        if(flag){
            timesum = timesum + [item.time doubleValue];
        }
        
    }

    
    return [NSNumber numberWithDouble:timesum];
}

- (TimingItemEntity *)getDailyTimingItemByItemName:(NSString*)itemName date:(NSDate *)date
{
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;


    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"item_name == %@",itemName]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"Name: %@", [info valueForKey:@"item_name"]);
    }
    
    NSDate * startDate = [DateHelper beginningOfDay:date];
    NSDate * endDate = [DateHelper endOfDay:date];
    
    
    for(TimingItemEntity * item in fetchedObjects){
        BOOL flag = true;
        if ([item.date_created compare:startDate] == NSOrderedAscending) {
            flag = false;
        }
        if ([item.date_created compare:endDate] == NSOrderedDescending) {
            flag = false;
        }
        if(flag){
            return item;
        }
        
    }

    
    return nil;
}



- (BOOL)markTracking:(NSString *)tagName Tracked:(NSNumber*)isTracking
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    Tag * tag ;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Tag" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tag_name == %@",tagName]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"Name: %@", [info valueForKey:@"tag_name"]);
    }
    if([fetchedObjects count]==0){
        tag = (Tag*)[NSEntityDescription insertNewObjectForEntityForName:@"Tag"
                                                  inManagedObjectContext:context];
        [tag setValue:tagName forKey:@"tag_name"];
    }else{
        tag = (Tag*)[fetchedObjects objectAtIndex:0];
    }
    
    tag.tracking = isTracking;
    [context updatedObjects];
    
    
    
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return false;
    }
    
    return true;
}







/**** PersonalCenter Usage
 **/



- (NSNumber *)getTotalHoursByTag:(NSString*)tagName
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Tag" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tag_name == %@",tagName]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"Name: %@", [info valueForKey:@"tag_name"]);
    }
    
    
    NSNumber * sum = [NSNumber numberWithInt:0];
    
    if([fetchedObjects count]==0){
        return [NSNumber numberWithInt:0];
    }else{
        Tag* tag = (Tag*)[fetchedObjects objectAtIndex:0];
        NSSet* items = tag.item;
        
        for(TimingItemEntity * i in items){
//            NSLog(@"%@time:%@",i.item_name, i.time);
            sum = [NSNumber numberWithFloat:[sum floatValue]+[i.time floatValue]];
        }
        NSLog(@"sum: %@",sum);
    }
    
    
    
    
    
    
    
    NSNumber * result = [NSNumber numberWithDouble:[sum floatValue]/3600];
    return result;
}

- (NSNumber *)getTotalHoursByDate:(NSDate*)date
                            byTag:(NSString*)tagName
{
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Tag" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tag_name == %@",tagName]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"Name: %@", [info valueForKey:@"tag_name"]);
    }
    
    
    NSDate* startOfDay = [DateHelper beginningOfDay:date];
    NSDate* endOfDay = [DateHelper endOfDay:date];
    
    
    NSNumber * sum = [NSNumber numberWithInt:0];
    
    if([fetchedObjects count]==0){
        return [NSNumber numberWithInt:0];
    }else{
        Tag* tag = (Tag*)[fetchedObjects objectAtIndex:0];
        NSSet* items = tag.item;
        for(TimingItemEntity * i in items){
            if([i.date_created compare:startOfDay] == NSOrderedDescending && [i.date_created compare:endOfDay] == NSOrderedAscending){
                sum = [NSNumber numberWithFloat:[sum floatValue]+[i.time floatValue]];
            }
        }
        NSLog(@"sum: %@",sum);
    }
    
    NSNumber * result = [NSNumber numberWithDouble:[sum floatValue]/3600];
    return result;
}


- (NSNumber *)getTotalHoursByStartDate:(NSDate*)date
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    
    
    NSDate *startOfToday = [DateHelper beginningOfDay:date];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"date_created >= %@", startOfToday]];
    NSSortDescriptor *sortByDate = [[NSSortDescriptor alloc] initWithKey:@"date_created" ascending:YES];
    
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortByDate]];
    [fetchRequest setFetchLimit:1];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    
    
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"date_created....: %@", [info valueForKey:@"date_created"]);
        
    }
    if([fetchedObjects count]==0){
        NSLog(@"Empty");
        return 0;
    }
    
    NSTimeInterval timeinterval =[(NSDate*)[[fetchedObjects objectAtIndex:0] valueForKey:@"date_created"] timeIntervalSinceNow];
    
    NSNumber * result = [NSNumber numberWithDouble:-timeinterval/3600];
    NSLog(@"%@",result);
    return result;
}

- (NSDate*)getStartDate
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortByDate = [[NSSortDescriptor alloc] initWithKey:@"date_created" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortByDate]];
    [fetchRequest setFetchLimit:1];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"date_created....: %@", [info valueForKey:@"date_created"]);
    }
    if([fetchedObjects count]==0){
        NSLog(@"Empty");
        return nil;
    }
    return ((TimingItemEntity*)[fetchedObjects objectAtIndex:0]).date_created;
}

- (NSNumber *)getTotalHours
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortByDate = [[NSSortDescriptor alloc] initWithKey:@"date_created" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortByDate]];
    [fetchRequest setFetchLimit:1];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    
    
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"date_created....: %@", [info valueForKey:@"date_created"]);
    }
    if([fetchedObjects count]==0){
        NSLog(@"Empty");
        return 0;
    }
    
    NSTimeInterval timeinterval =[(NSDate*)[[fetchedObjects objectAtIndex:0] valueForKey:@"date_created"] timeIntervalSinceNow];
    
    
    NSNumber * result = [NSNumber numberWithDouble:-timeinterval/3600];
    NSLog(@"%@",result);
    return result;
    
}




- (NSNumber *)getTotalDays
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortByDate = [[NSSortDescriptor alloc] initWithKey:@"date_created" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortByDate]];
    [fetchRequest setFetchLimit:1];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    
    
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"date_created....: %@", [info valueForKey:@"date_created"]);
    }
    if([fetchedObjects count]==0){
        NSLog(@"Empty");
        return 0;
    }
    
    
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSUInteger unitFlags = NSMonthCalendarUnit | NSDayCalendarUnit |NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    
    NSDateComponents *components = [gregorian components:unitFlags
                                                fromDate:(NSDate*)[[fetchedObjects objectAtIndex:0]
                                             valueForKey:@"date_created"]
                                                  toDate:[NSDate date] options:0];
    NSInteger days = [components day];
    //test:
    NSInteger minutes = [components second];
    return [NSNumber numberWithInteger:minutes];
}

- (NSNumber*)getItemPercentage:(TimingItem*)item
{
    double sum = [self getTotalTime:item.dateCreated];
    double time = item.time;
    NSNumber* result= [NSNumber numberWithDouble:time/sum*100];
    NSLog(@"%@",result);
    return result;
}


// Dailys
- (BOOL)addDaily:(NSString*)name
             tag:(NSString*)tagName;
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    
    Daily * daily;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Daily" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"item_name == %@",name]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if([fetchedObjects count]==0){
        //If not existed, create one
        
        
        daily = (Daily*)[NSEntityDescription insertNewObjectForEntityForName:@"Daily"
                                                  inManagedObjectContext:context];
        [daily setValue:name forKey:@"item_name"];
        if(tagName){
            [daily setValue:tagName forKey:@"tag_name"];
        }
    }else{
        //If existed, return
        return YES;
    }
    
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return false;
    }
    
    
    [self createDailyMark:daily date:[DateHelper beginningOfDay:[NSDate date]]];
    return NO;
}
- (BOOL)removeDaily:(NSString*)name
{
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    BOOL result =YES;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Daily" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"item_name == %@",name]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *info in fetchedObjects) {
        [context deleteObject:info];
    }
    
    
    if ([context save:&error]) {
        NSLog(@"Did it!");
    } else {
        NSLog(@"Could not do it: %@", [error localizedDescription]);
        result = NO;
    }
    
    return result;
    
}
- (NSArray*)getAllDaily
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    NSMutableArray * results = [[NSMutableArray alloc] init];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Daily" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if([fetchedObjects count]==0){
        //If not existed, return an array with no item in it.
        return results;
    }else{
        //If existed, return array;
        for(Daily * daily in fetchedObjects){
            [results addObject:daily];
        }
        return results;
    }
    
    return results;
}
- (BOOL)updateDaily:(NSString*)fromName
             toName:(NSString*)toName
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    BOOL result = YES;
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Daily" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"item_name == %@",fromName]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (Daily *i in fetchedObjects) {
        i.item_name = toName;
    }
    
    [context updatedObjects];
    if ([context save:&error]) {
        NSLog(@"Did it!");
    } else {
        NSLog(@"Could not do it: %@", [error localizedDescription]);
        result = NO;
    }
    
    return result;
}



- (TimingItem*)TimingItemFromTimingItemEntity:(TimingItemEntity*)itemEntity
{
    TimingItem *i = [TimingItem randomItem];
    i.itemName = itemEntity.item_name;
    i.itemColor = [itemEntity.color_number intValue];
    i.dateCreated = itemEntity.date_created;
    i.time = [itemEntity.time doubleValue];
    i.lastCheck = itemEntity.last_check;
    i.timing = [itemEntity.timing boolValue];

    return i;
}



- (double)getTotalTime:(NSDate*)date
{
    NSArray* itemAry = [self getTimingItemsByDate:date];
    
    double sum = 0.0;
    for(TimingItemEntity * item in itemAry){
        sum += [item.time doubleValue];
    }
    
    return sum;
}




@end
