//
//  BigDataController.h
//  BigData
//
//  Created by Jeff on 2/2/11.
//  Copyright 2011 Jeff Buck. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BigDataController : NSObject <CPTPlotDataSource, NSWindowDelegate>
{
	IBOutlet CPTLayerHostingView*	_hostingView;
	float							_previousWidth;

	NSString*						_filename;
	
	CPTXYGraph*						_graph;
	BigDataModel*					_model;
}

@end
