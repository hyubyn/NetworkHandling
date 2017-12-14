//
//  NetworkHelper.h
//  DemoHW
//
//  Created by NguyenVuHuy on 12/14/17.
//  Copyright © 2017 Hyubyn. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NetworkHelperDelegate <NSObject>
- (void) didPingDefaultGateWay:(BOOL)result;
- (void) didPingServer:(BOOL)result;
@end

@interface NetworkHelper : NSObject

@property (nonatomic, weak) id <NetworkHelperDelegate> delegate;

- (void)get_dns_servers;
- (NSString *)getGatewayIP;
- (void)pingToServer;
- (void)pingToAddress:(NSString*) address;
@end
