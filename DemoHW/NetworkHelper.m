//
//  NetworkHelper.m
//  DemoHW
//
//  Created by NguyenVuHuy on 12/14/17.
//  Copyright © 2017 Hyubyn. All rights reserved.
//

#import "NetworkHelper.h"
#import "getgateway.h"
#import <arpa/inet.h>
#include <resolv.h>

#include <dns.h>
#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<sys/socket.h>
#include<arpa/inet.h> //inet_addr , inet_ntoa , ntohs etc
#include<netinet/in.h>
#include<unistd.h>
#import "SimplePingHelper.h"

@interface NetworkHelper() {
    NSMutableArray* server_DNS;
}
@end

@implementation NetworkHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        server_DNS = [NSMutableArray new];
    }
    return self;
}

-(void) get_dns_servers
{
    res_state res = malloc(sizeof(struct __res_state));
    int result = res_ninit(res);
    if(result==0)
    {
        NSLog(@"No of DNS IP : %d",res->nscount);
        for ( int i= 0; i < res->nscount; i++)
        {
            NSString *s = [NSString stringWithUTF8String :  inet_ntoa(res->nsaddr_list[i].sin_addr)];
            NSLog(@"DNS ip : %@",s);
            [server_DNS addObject:s];
        }
    }
    
}

- (NSString *)getGatewayIP {
    NSString *ipString = nil;
    struct in_addr gatewayaddr;
    int r = getdefaultgateway(&(gatewayaddr.s_addr));
    if(r >= 0) {
        ipString = [NSString stringWithFormat: @"%s",inet_ntoa(gatewayaddr)];
        NSLog(@"default gateway : %@", ipString );
    } else {
        NSLog(@"getdefaultgateway() failed");
    }
    
    return ipString;
    
}

- (void)pingToServer {
    [SimplePingHelper ping:@"d2suzd7bkd85tf.cloudfront.net" target:self sel:@selector(pingServerResult:)];
}

- (void)pingToAddress:(NSString*) address {
    [SimplePingHelper ping:address target:self sel:@selector(pingGateWayResult:)];
}

- (void)pingServerResult:(NSNumber*)success {
    if (success.boolValue) {
        if([self.delegate respondsToSelector:@selector(didPingServer:)]) {
            [self.delegate didPingServer:success.boolValue];
        }
    } else {
        if([self.delegate respondsToSelector:@selector(didPingServer:)]) {
            [self.delegate didPingServer:NO];
        }
    }
}
- (void)pingGateWayResult:(NSNumber*)success {
    if (success.boolValue) {
        if([self.delegate respondsToSelector:@selector(didPingDefaultGateWay:)]) {
            [self.delegate didPingDefaultGateWay:success.boolValue];
        }
    } else {
        if([self.delegate respondsToSelector:@selector(didPingDefaultGateWay:)]) {
            [self.delegate didPingDefaultGateWay:NO];
        }
    }
}
@end
