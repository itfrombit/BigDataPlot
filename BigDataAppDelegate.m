//
//  BigDataAppDelegate.m
//  BigData
//
//  Created by Jeff on 2/1/11.
//  Copyright 2011 Jeff Buck. All rights reserved.
//

#import "BigDataAppDelegate.h"

@implementation BigDataAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[window setMinSize:NSMakeSize(200.0, 200.0)];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
