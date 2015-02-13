//
//  XMPPStreamManagementOutgoingStanzaCoreDataStorageObject.h
//  9CHAT
//
//  Created by Lung on 10/2/15.
//  Copyright (c) 2015 9GAG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class XMPPStreamManagementCoreDataStorageObject;

@interface XMPPStreamManagementOutgoingStanzaCoreDataStorageObject : NSManagedObject

@property (nonatomic, retain) NSString * stanzaId;
@property (nonatomic, retain) NSNumber * awaitingStanzaId;
@property (nonatomic, retain) XMPPStreamManagementCoreDataStorageObject *streamManagement;

@end
