//
//  XMPPStreamManagementCoreDataStorage.h
//  9CHAT
//
//  Created by Lung on 2/1/15.
//  Copyright (c) 2015 9GAG. All rights reserved.
//

#import "XMPPCoreDataStorage.h"
#import "XMPPStreamManagement.h"

@interface XMPPStreamManagementCoreDataStorage : XMPPCoreDataStorage <XMPPStreamManagementStorage>

+ (instancetype)sharedInstance;

@end
