//
//  XMPPStreamManagementCoreDataStorage.m
//  9CHAT
//
//  Created by Lung on 2/1/15.
//  Copyright (c) 2015 9GAG. All rights reserved.
//

#import "XMPPStreamManagementCoreDataStorage.h"
#import "XMPPStreamManagementCoreDataStorageObject.h"
#import "XMPPStreamManagementStanzas.h"
#import "XMPPStreamManagementOutgoingStanzaCoreDataStorageObject.h"
#import "XMPP.h"
#import "XMPPCoreDataStorageProtected.h"
#import "XMPPLogging.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

// Log levels: off, error, warn, info, verbose
// Log flags: trace
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // VERBOSE; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

@implementation XMPPStreamManagementCoreDataStorage
{
    int32_t isConfigured;
    
//    NSString *resumptionId;
//    uint32_t timeout;
//    
//    NSDate *lastDisconnect;
//    uint32_t lastHandledByClient;
//    uint32_t lastHandledByServer;
//    NSArray *pendingOutgoingStanzas;
}

static XMPPStreamManagementCoreDataStorage *sharedInstance;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[XMPPStreamManagementCoreDataStorage alloc] initWithDatabaseFilename:nil storeOptions:nil];
    });
    
    return sharedInstance;
}


- (void)commonInit
{
    XMPPLogTrace();
    [super commonInit];
    
}

- (void)dealloc
{
    
}


- (BOOL)configureWithParent:(XMPPStreamManagement *)parent queue:(dispatch_queue_t)queue
{
    // This implementation only supports a single xmppStream.
    // You must create multiple instances for multiple xmppStreams.
    
    return OSAtomicCompareAndSwap32(0, 1, &isConfigured);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Utilities
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (XMPPStreamManagementCoreDataStorageObject *)storageObjectForStream:(XMPPStream *)stream
{
//    NSAssert(dispatch_get_specific(storageQueueTag), @"Invoked on incorrect queue");
    
    XMPPLogTrace2(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPStreamManagementCoreDataStorageObject"
                                              inManagedObjectContext:[self managedObjectContext]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"1 == 1"];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit:1];
    
    NSArray *results = [[self managedObjectContext] executeFetchRequest:fetchRequest error:nil];
    
    XMPPStreamManagementCoreDataStorageObject *resource = [results lastObject];
    
    XMPPLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, resource);
    return resource;
}

- (XMPPStreamManagementOutgoingStanzaCoreDataStorageObject *)outgoingStanzaObjectForStream:(XMPPStream *)stream from:(XMPPStreamManagementOutgoingStanza *)fromOutgoingStanza
{
    //    NSAssert(dispatch_get_specific(storageQueueTag), @"Invoked on incorrect queue");
    
    XMPPLogTrace2(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    XMPPStreamManagementOutgoingStanzaCoreDataStorageObject *resource = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPStreamManagementOutgoingStanzaCoreDataStorageObject"
                                                                                                      inManagedObjectContext:[self managedObjectContext]];
    
    resource.stanzaId = fromOutgoingStanza.stanzaId;
    resource.awaitingStanzaId = @(fromOutgoingStanza.awaitingStanzaId);
    
    return resource;
}

/**
 * Invoked after we receive <enabled/> from the server.
 *
 * @param resumptionId
 *   The ID required to resume the session, given to us by the server.
 *
 * @param timeout
 *   The timeout in seconds.
 *   After a disconnect, the server will maintain our state for this long.
 *   If we attempt to resume the session after this timeout it likely won't work.
 *
 * @param lastDisconnect
 *   Used to reset the lastDisconnect value.
 *   This value is often updated during the session, to ensure it closely resemble the date the server will use.
 *   That is, if the client application is killed (or crashes) we want a relatively accurate lastDisconnect date.
 *
 * @param stream
 *   The associated xmppStream (standard parameter for storage classes)
 *
 * This method should also nil out the following values (if needed) associated with the account:
 * - lastHandledByClient
 * - lastHandledByServer
 * - pendingOutgoingStanzas
 **/
- (void)setResumptionId:(NSString *)inResumptionId
                timeout:(uint32_t)inTimeout
         lastDisconnect:(NSDate *)inLastDisconnect
              forStream:(XMPPStream *)stream
{
//    NSLog(@"inResumptionId %@", inResumptionId);
    
    [self executeBlock:^{
        
        XMPPStreamManagementCoreDataStorageObject *object = [self storageObjectForStream:stream];
        if (object)
        {
            
        }
        else
        {
            object = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPStreamManagementCoreDataStorageObject"
                                                   inManagedObjectContext:[self managedObjectContext]];
        }
        
        object.resumptionId = inResumptionId;
        object.timeout = @(inTimeout);
        object.lastDisconnect = inLastDisconnect;
        
        object.lastHandledByClient = @(0);
        object.lastHandledByServer = @(0);
        
        [object removePendingOutgoingStanzas:object.pendingOutgoingStanzas];
        
    }];
    
}

/**
 * This method is invoked ** often ** during stream operation.
 * It is not invoked when the xmppStream is disconnected.
 *
 * Important: See the note [in XMPPStreamManagement.h]: "Optimizing storage demands during active stream usage"
 *
 * @param date
 *   Updates the previous lastDisconnect value.
 *
 * @param lastHandledByClient
 *   The most recent 'h' value we can safely send to the server.
 *
 * @param stream
 *   The associated xmppStream (standard parameter for storage classes)
 **/
- (void)setLastDisconnect:(NSDate *)inLastDisconnect
      lastHandledByClient:(uint32_t)inLastHandledByClient
                forStream:(XMPPStream *)stream
{
    [self executeBlock:^{
        
        XMPPStreamManagementCoreDataStorageObject *object = [self storageObjectForStream:stream];
        if (object)
        {
            
        }
        else
        {
            object = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPStreamManagementCoreDataStorageObject"
                                                   inManagedObjectContext:[self managedObjectContext]];
        }
        
        object.lastDisconnect = inLastDisconnect;
        object.lastHandledByClient = @(inLastHandledByClient);
        
    }];
    
}

/**
 * This method is invoked ** often ** during stream operation.
 * It is not invoked when the xmppStream is disconnected.
 *
 * Important: See the note [in XMPPStreamManagement.h]: "Optimizing storage demands during active stream usage"
 *
 * @param date
 *   Updates the previous lastDisconnect value.
 *
 * @param lastHandledByServer
 *   The most recent 'h' value we've received from the server.
 *
 * @param pendingOutgoingStanzas
 *   An array of XMPPStreamManagementOutgoingStanza objects.
 *   The storage layer is in charge of properly persisting this array, including:
 *   - the array count
 *   - the stanzaId of each element, including those that are nil
 *
 * @param stream
 *   The associated xmppStream (standard parameter for storage classes)
 **/
- (void)setLastDisconnect:(NSDate *)inLastDisconnect
      lastHandledByServer:(uint32_t)inLastHandledByServer
   pendingOutgoingStanzas:(NSArray *)inPendingOutgoingStanzas
                forStream:(XMPPStream *)stream
{
    [self executeBlock:^{
        
        XMPPStreamManagementCoreDataStorageObject *object = [self storageObjectForStream:stream];
        if (object)
        {
            
        }
        else
        {
            object = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPStreamManagementCoreDataStorageObject"
                                                   inManagedObjectContext:[self managedObjectContext]];
        }
        
        object.lastDisconnect = inLastDisconnect;
        object.lastHandledByServer = @(inLastHandledByServer);
        
        [object removePendingOutgoingStanzas:object.pendingOutgoingStanzas];
        for(XMPPStreamManagementOutgoingStanza *outgoingStanza in inPendingOutgoingStanzas){
            XMPPStreamManagementOutgoingStanzaCoreDataStorageObject *outgoingStanzaCoreDataStorageObject = [self outgoingStanzaObjectForStream:stream from:outgoingStanza];
            [object addPendingOutgoingStanzasObject:outgoingStanzaCoreDataStorageObject];
        }
        
    }];
}

/**
 * This method is invoked immediately after an accidental disconnect.
 * And may be invoked post-disconnect if the state changes, such as for the following edge cases:
 *
 * - due to continued processing of stanzas received pre-disconnect,
 *   that are just now being marked as handled by the delegate(s)
 * - due to a delayed response from the delegate(s),
 *   such that we didn't receive the stanzaId for an outgoing stanza until after the disconnect occurred.
 *
 * This method is not invoked if stream management is started on a connected xmppStream.
 *
 * @param date
 *   This value will be the actual disconnect date.
 *
 * @param lastHandledByClient
 *   The most recent 'h' value we can safely send to the server.
 *
 * @param lastHandledByServer
 *   The most recent 'h' value we've received from the server.
 *
 * @param pendingOutgoingStanzas
 *   An array of XMPPStreamManagementOutgoingStanza objects.
 *   The storage layer is in charge of properly persisting this array, including:
 *   - the array count
 *   - the stanzaId of each element, including those that are nil
 *
 * @param stream
 *   The associated xmppStream (standard parameter for storage classes)
 **/
- (void)setLastDisconnect:(NSDate *)inLastDisconnect
      lastHandledByClient:(uint32_t)inLastHandledByClient
      lastHandledByServer:(uint32_t)inLastHandledByServer
   pendingOutgoingStanzas:(NSArray *)inPendingOutgoingStanzas
                forStream:(XMPPStream *)stream
{
    [self executeBlock:^{
        
        XMPPStreamManagementCoreDataStorageObject *object = [self storageObjectForStream:stream];
        if (object)
        {
            
        }
        else
        {
            object = [NSEntityDescription insertNewObjectForEntityForName:@"XMPPStreamManagementCoreDataStorageObject"
                                                   inManagedObjectContext:[self managedObjectContext]];
        }
        
        object.lastDisconnect = inLastDisconnect;
        object.lastHandledByClient = @(inLastHandledByClient);
        object.lastHandledByServer = @(inLastHandledByServer);
        
        [object removePendingOutgoingStanzas:object.pendingOutgoingStanzas];
        for(XMPPStreamManagementOutgoingStanza *outgoingStanza in inPendingOutgoingStanzas){
            XMPPStreamManagementOutgoingStanzaCoreDataStorageObject *outgoingStanzaCoreDataStorageObject = [self outgoingStanzaObjectForStream:stream from:outgoingStanza];
            [object addPendingOutgoingStanzasObject:outgoingStanzaCoreDataStorageObject];
        }
        
    }];
    
}

/**
 * Invoked when the extension needs values from a previous session.
 * This method is used to get values needed in order to determine if it can resume a previous stream.
 **/
- (void)getResumptionId:(NSString **)resumptionIdPtr
                timeout:(uint32_t *)timeoutPtr
         lastDisconnect:(NSDate **)lastDisconnectPtr
              forStream:(XMPPStream *)stream
{
    __block NSString *resumptionId = nil;
    __block uint32_t timeout = 0;
    __block NSDate *lastDisconnect = nil;
    
    [self executeBlock:^{
        
        XMPPStreamManagementCoreDataStorageObject *object = [self storageObjectForStream:stream];
        if (object)
        {
            resumptionId = object.resumptionId;
            timeout = [object.timeout unsignedIntegerValue];
            lastDisconnect = object.lastDisconnect;
        }
        else
        {
            resumptionId = nil;
            timeout = 0;
            lastDisconnect = nil;
        }
        
    }];
    
    NSLog(@"resumptionId %@", resumptionId);
    NSLog(@"timeout %d", timeout);
    NSLog(@"lastDisconnect %@", lastDisconnect);
    
    if (resumptionIdPtr)   *resumptionIdPtr   = resumptionId;
    if (timeoutPtr)        *timeoutPtr        = timeout;
    if (lastDisconnectPtr) *lastDisconnectPtr = lastDisconnect;
}

/**
 * Invoked when the extension needs values from a previous session.
 * This method is used to get values needed in order to resume a previous stream.
 **/
- (void)getLastHandledByClient:(uint32_t *)lastHandledByClientPtr
           lastHandledByServer:(uint32_t *)lastHandledByServerPtr
        pendingOutgoingStanzas:(NSArray **)pendingOutgoingStanzasPtr
                     forStream:(XMPPStream *)stream;
{
    __block uint32_t lastHandledByClient = 0;
    __block uint32_t lastHandledByServer = 0;
    __block NSMutableArray *pendingOutgoingStanzas = nil;
    
    [self executeBlock:^{
        
        XMPPStreamManagementCoreDataStorageObject *object = [self storageObjectForStream:stream];
        if (object)
        {
            lastHandledByClient = [object.lastHandledByClient unsignedIntegerValue];
            lastHandledByServer = [object.lastHandledByServer unsignedIntegerValue];
            
            if(object.pendingOutgoingStanzas && [object.pendingOutgoingStanzas count] > 0){
                pendingOutgoingStanzas = [NSMutableArray array];
                for (XMPPStreamManagementOutgoingStanzaCoreDataStorageObject *outgoingStanzaCoreDataStorageObject in object.pendingOutgoingStanzas) {
                    XMPPStreamManagementOutgoingStanza *outgoingStanza = [[XMPPStreamManagementOutgoingStanza alloc] init];
                    outgoingStanza.awaitingStanzaId = [outgoingStanzaCoreDataStorageObject.awaitingStanzaId boolValue];
                    outgoingStanza.stanzaId = outgoingStanzaCoreDataStorageObject.stanzaId;
                    [pendingOutgoingStanzas addObject:outgoingStanza];
                }
            }
        }
        else
        {
            lastHandledByClient = 0;
            lastHandledByServer = 0;
            pendingOutgoingStanzas = nil;
        }
        
    }];
    
    if (lastHandledByClientPtr)    *lastHandledByClientPtr    = lastHandledByClient;
    if (lastHandledByServerPtr)    *lastHandledByServerPtr    = lastHandledByServer;
    if (pendingOutgoingStanzasPtr) *pendingOutgoingStanzasPtr = pendingOutgoingStanzas;
}

/**
 * Instructs the storage layer to remove all values stored for the given stream.
 * This occurs after the extension detects a "cleanly closed stream",
 * in which case the stream cannot be resumed next time.
 **/
- (void)removeAllForStream:(XMPPStream *)stream
{
    [self executeBlock:^{
        
        XMPPStreamManagementCoreDataStorageObject *object = [self storageObjectForStream:stream];
        if (object)
        {
            [[self managedObjectContext] deleteObject:object];
        }
        else
        {
            
        }
        
    }];
    
}

@end
