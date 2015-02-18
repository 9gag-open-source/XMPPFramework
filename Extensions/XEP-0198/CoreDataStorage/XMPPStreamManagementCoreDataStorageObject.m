//
//  XMPPStreamManagementCoreDataStorageObject.m
//  9CHAT
//
//  Created by Lung on 10/2/15.
//  Copyright (c) 2015 9GAG. All rights reserved.
//

#import "XMPPStreamManagementCoreDataStorageObject.h"
#import "XMPPStreamManagementOutgoingStanzaCoreDataStorageObject.h"


@implementation XMPPStreamManagementCoreDataStorageObject

@dynamic resumptionId;
@dynamic timeout;
@dynamic lastDisconnect;
@dynamic lastHandledByClient;
@dynamic lastHandledByServer;
@dynamic pendingOutgoingStanzas;

@end
