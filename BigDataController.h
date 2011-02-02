//
//  BigDataController.h
//  BigData
//
//  Created by Jeff on 2/2/11.
//  Copyright 2011 Jeff Buck. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BigDataController : NSObject <CPPlotDataSource, NSWindowDelegate>
{
	IBOutlet CPLayerHostingView*	_hostingView;
	float							_previousWidth;

	NSString*						_filename;
	
	CPXYGraph*						_graph;
	BigDataModel*					_model;
}

@end
