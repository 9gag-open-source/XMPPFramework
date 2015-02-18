//
//  XMPPStreamManagementCoreDataStorageObject.h
//  9CHAT
//
//  Created by Lung on 10/2/15.
//  Copyright (c) 2015 9GAG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class XMPPStreamManagementOutgoingStanzaCoreDataStorageObject;

@interface XMPPStreamManagementCoreDataStorageObject : NSManagedObject

@property (nonatomic, retain) NSString * resumptionId;
@property (nonatomic, retain) NSNumber * timeout;
@property (nonatomic, retain) NSDate * lastDisconnect;
@property (nonatomic, retain) NSNumber * lastHandledByClient;
@property (nonatomic, retain) NSNumber * lastHandledByServer;
@property (nonatomic, retain) NSSet *pendingOutgoingStanzas;
@end

@interface XMPPStreamManagementCoreDataStorageObject (CoreDataGeneratedAccessors)

- (void)addPendingOutgoingStanzasObject:(XMPPStreamManagementOutgoingStanzaCoreDataStorageObject *)value;
- (void)removePendingOutgoingStanzasObject:(XMPPStreamManagementOutgoingStanzaCoreDataStorageObject *)value;
- (void)addPendingOutgoingStanzas:(NSSet *)values;
- (void)removePendingOutgoingStanzas:(NSSet *)values;

@end
