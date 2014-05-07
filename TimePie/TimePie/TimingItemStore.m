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
#import "Daily.h"
#import "Tag.h"
#import "DateHelper.h"
#import "TimingItemEntity.h"

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
    i.color = [allItems count];
    [allItems addObject:i];
    NSLog(@"create item!");
    return i;
}

- (TimingItem *)createItem:(TimingItem*)item
{
    TimingItem *i = [TimingItem randomItem];
    i.color = item.color;
    i.lastCheck = item.lastCheck;
    i.itemName = item.itemName;
    item.time +=1;
    i.time = item.time;
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
        [i setValue:[NSNumber numberWithInt:item.color] forKey:@"color_number"];
        [context updatedObjects];
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            result = NO;
        }
    }
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
- (BOOL)viewAllItem
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
    
    return YES;
}

- (BOOL)restoreData
{
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
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(date_created >= %@) AND (date_created <= %@)", startOfToday, endOfToday]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    
    NSLog(@"[restoredata]number of object returned: %d",[fetchedObjects count]);
    for (NSManagedObject *i in fetchedObjects) {
        [self restoreItem:i];
    }
    
    
    if(allItems&&[allItems count]!=0){
        [[[self allItems] objectAtIndex:0] check:YES];
        NSLog([[[self allItems] objectAtIndex:0] itemName]);
    }
    
    return YES;
}






// restore a single item from NSManagedObject
- (TimingItem* )restoreItem:(NSManagedObject *)i
{
    TimingItem * item = [self createItem];
    item.itemName =[i valueForKey:@"item_name"];
    item.time = [[i valueForKey:@"time"] doubleValue];
    item.itemID =[[i valueForKey:@"item_id"] integerValue];
    item.dateCreated = [i valueForKey:@"date_created"];
    item.lastCheck = [i valueForKey:@"last_check"];
    item.color = [[i valueForKey:@"color_number"] integerValue];
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
    [i setValue:[NSNumber numberWithInt:item.color] forKey:@"color_number"];
    
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
    [i setValue:[NSNumber numberWithInt:item.color] forKey:@"color_number"];

    
    
    
    
    
    return i;
    
}




- (Daily*)createToday
{
    NSDate *adate = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: adate];
    NSDate *localeDate = [adate  dateByAddingTimeInterval: interval];
    
    NSDate *today = [NSDate date];
    NSDate *startOfToday = [DateHelper beginningOfDay:today];
    
    startOfToday = [startOfToday dateByAddingTimeInterval:interval];
    //endOfToday = [endOfToday dateByAddingTimeInterval:interval];
    
    
    
    //insert
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    NSManagedObject *i = [NSEntityDescription
    insertNewObjectForEntityForName:@"Daily"
    inManagedObjectContext:context];
     
    [i setValue:today forKey:@"date"];
     
     
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return nil;
    }
    return (Daily*)i;
}

//////////Daily Table

- (Daily*)getToday
{
    NSDate *adate = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: adate];
    NSDate *localeDate = [adate  dateByAddingTimeInterval: interval];
    
    NSDate *today = [NSDate date];
    NSDate *startOfToday = [DateHelper beginningOfDay:today];
    NSDate *endOfToday = [DateHelper endOfDay:today];
    
    startOfToday = [startOfToday dateByAddingTimeInterval:interval];
    endOfToday = [endOfToday dateByAddingTimeInterval:interval];
    
    //NSLog([NSString stringWithFormat:@"%@",startOfToday]);
    //NSLog([NSString stringWithFormat:@"%@",endOfToday]);
    
    //insert
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;

    NSManagedObject *i = [NSEntityDescription
                          insertNewObjectForEntityForName:@"Daily"
                          inManagedObjectContext:context];
    
    [i setValue:today forKey:@"date"];
    
 
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }

    
    
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Daily" inManagedObjectContext:context];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(date >= %@) AND (date <= %@)", startOfToday, endOfToday]];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if([fetchedObjects count]==0){
        return [self createToday];
    }
    for (NSManagedObject *info in fetchedObjects) {
        NSLog([NSString stringWithFormat:@"%@", info]);
        return (Daily*)info;
    }
    
    return nil;
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
    tag = (Tag*)[fetchedObjects objectAtIndex:0];
    
    
    
    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"date_created == %@",item.dateCreated]];
    
    fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSLog(@"Name: %@", [info valueForKey:@"item_name"]);
    }
    TimingItemEntity * i = [fetchedObjects objectAtIndex:0];
    i.tag = tag;
    [tag addItemObject:i];
    
    [context updatedObjects];
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return false;
    }
    
    
    
    
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

    return true;
}

- (Tag *)createTag:(NSString*)name
{
    //insert
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    NSManagedObject *i = [NSEntityDescription
                          insertNewObjectForEntityForName:@"Tag"
                          inManagedObjectContext:context];
    
    [i setValue:name forKey:@"tag_name"];
    
    
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        return nil;
    }
    
    
    return (Tag *)i;
}


- (Tag *)getTag:(NSString*)name
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Tag" inManagedObjectContext:context];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tag_name == %@",name]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    Tag* tag= nil;
    if([fetchedObjects count]==0){
        tag = [self createTag:name];
    }else{
        NSLog(@"Have tag!!!");
        tag = [fetchedObjects objectAtIndex:0];
    }
    
    return tag;
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
    tag = (Tag*)[fetchedObjects objectAtIndex:0];
    
    for(TimingItemEntity * i  in tag.item){
        NSLog(@"item entity for tag:%@", i);
    }
    
    
    return [self getTimingItemsByTag:tag];
}



- (NSArray *)getTimingItemsByTag:(Tag *)tag
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSError *error;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"TimingItemEntity" inManagedObjectContext:context];
    
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tag == %@",tag]];
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if([fetchedObjects count]==0){
        return nil;
    }
    NSLog(@"fetchedObjects: %d", [fetchedObjects count]);

    return fetchedObjects;
}


@end
