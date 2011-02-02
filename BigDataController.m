//
//  BigDataController.m
//  BigData
//
//  Created by Jeff on 2/2/11.
//  Copyright 2011 Jeff Buck. All rights reserved.
//

#import "CorePlot/CorePlot.h"

#import "BigDataModel.h"
#import "BigDataController.h"

@implementation BigDataController

- (void)updatePlotSpaceForGraph:(CPXYGraph*)graph
{
	int newSize = _hostingView.bounds.size.width * 2;
	
	if (newSize == _previousWidth)
	{
		NSLog(@"Same size...ignore");
		return;
	}
	
	_previousWidth = newSize;
	
	[_model resampleDataWithSampleCount:_hostingView.bounds.size.width * 2];

	// Axes
	CPXYAxisSet* axisSet = (CPXYAxisSet*)graph.axisSet;
	CPXYAxis* x = axisSet.xAxis;
	x.majorIntervalLength = CPDecimalFromDouble(0.0);
	x.orthogonalCoordinateDecimal = CPDecimalFromDouble(0.0);
	x.minorTicksPerInterval = 0;
	CPPlotRange* xAxisRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(0.0) length:CPDecimalFromFloat([_model effectiveCount])];
	x.visibleRange = xAxisRange;
	x.gridLinesRange = xAxisRange;
	
	CPXYAxis* y = axisSet.yAxis;
	y.majorIntervalLength = CPDecimalFromDouble(0.5);
	y.orthogonalCoordinateDecimal = CPDecimalFromDouble(0.0);
	y.minorTicksPerInterval = 4;
	CPPlotRange* yAxisRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(-1.0) length:CPDecimalFromFloat(2.0)];
	y.visibleRange = yAxisRange;
	y.gridLinesRange = yAxisRange;
	
	//graph.axisSet.axes = [NSArray arrayWithObjects:x, y, nil];
	
	CPXYPlotSpace* plotSpace = (id)graph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = NO;
	plotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(0.0) length:CPDecimalFromFloat([_model effectiveCount])];
	plotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(-1.0) length:CPDecimalFromFloat(2.0)];
	
	[graph reloadData];
	[graph setNeedsLayout];
	[graph setNeedsDisplay];
}

- (void)setupGraph
{
	_graph = [(CPXYGraph *)[CPXYGraph alloc] initWithFrame:NSRectToCGRect(_hostingView.bounds)];
	CPTheme *theme = [CPTheme themeNamed:kCPSlateTheme];
    [_graph applyTheme:theme];
	_hostingView.hostedLayer = _graph;
    
    // Graph title
    _graph.title = _filename;
    CPMutableTextStyle *textStyle = [CPMutableTextStyle textStyle];
    textStyle.color = [CPColor grayColor];
    textStyle.fontName = @"Helvetica-Bold";
    textStyle.fontSize = 18.0;
    _graph.titleTextStyle = textStyle;
    _graph.titleDisplacement = CGPointMake(0.0, 20.0);
    _graph.titlePlotAreaFrameAnchor = CPRectAnchorTop;
	
    // Graph padding
    _graph.paddingLeft = 20.0;
    _graph.paddingTop = 40.0;
    _graph.paddingRight = 20.0;
    _graph.paddingBottom = 20.0;
	
	// Axes
	CPXYAxisSet* axisSet = (CPXYAxisSet*)_graph.axisSet;
	CPXYAxis* x = axisSet.xAxis;
	x.majorIntervalLength = CPDecimalFromDouble(0.0);
	x.orthogonalCoordinateDecimal = CPDecimalFromDouble(0.0);
	x.minorTicksPerInterval = 0;
	CPPlotRange* xAxisRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(0.0) length:CPDecimalFromFloat([_model effectiveCount])];
	x.visibleRange = xAxisRange;
	x.gridLinesRange = xAxisRange;
	
	CPXYAxis* y = axisSet.yAxis;
	y.majorIntervalLength = CPDecimalFromDouble(0.5);
	y.orthogonalCoordinateDecimal = CPDecimalFromDouble(0.0);
	y.minorTicksPerInterval = 4;
	CPPlotRange* yAxisRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(-1.0) length:CPDecimalFromFloat(2.0)];
	y.visibleRange = yAxisRange;
	y.gridLinesRange = yAxisRange;
	
	_graph.axisSet.axes = [NSArray arrayWithObjects:x, y, nil];
	
	// Scatter plot
	CPScatterPlot* plot = [[[CPScatterPlot alloc] init] autorelease];
	plot.dataSource = self;
	plot.delegate = self;
	
	CPXYPlotSpace* plotSpace = (id)_graph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = NO;
	plotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(0.0) length:CPDecimalFromFloat([_model effectiveCount])];
	plotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(-1.0) length:CPDecimalFromFloat(2.0)];
	
	[_graph addPlot:plot];
}


- (void)awakeFromNib
{
	_filename = @"SampleAudio.L.wav";
	_previousWidth = _hostingView.bounds.size.width * 2;
	
	_model = [[BigDataModel alloc] initWithFilename:_filename];
	[_model readFile];
	[_model resampleDataWithSampleCount:_previousWidth];
	
	[self setupGraph];
}


#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPPlot *)plot
{
	int count = [_model effectiveCount];
	
	NSLog(@"Point count is %d", count);

	return count;
}

-(NSNumber*)numberForPlot:(CPPlot*)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber* num;
	
    if (fieldEnum == CPScatterPlotFieldX)
	{
		if ([_model isSampling])
		{
			if (index & 1)
			{
				// Want the min and max close together on x-axis
				num = [NSNumber numberWithDouble:(float)index - 1.0 + 0.05];
			}
			else
			{
				num = [NSNumber numberWithDouble:(float)index];
			}
		}
		num = [NSNumber numberWithFloat:(float)index];
	}			
    else if (fieldEnum == CPScatterPlotFieldY)
	{
		if ([_model isSampling])
		{
			if (index & 1)
			{
				num = [NSNumber numberWithDouble:[_model minAtSample:index]];
			}
			else
			{
				num = [NSNumber numberWithDouble:[_model maxAtSample:index]];
			}
		}
		else
		{
			num = [NSNumber numberWithDouble:[_model dataAtIndex:index]];
		}
    }
	
	//NSLog(@"numberForPlot: field = %d,  index = %d,  value = %f", fieldEnum, index, [num doubleValue]);
	
    return num;
}

- (void)dealloc
{
	[_filename release];
	[_graph release];
	[_model release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark NSWindowDelegate methods

- (void)windowDidResize:(NSNotification *)notification
{
	NSLog(@"Window resized");
	[self performSelector:@selector(updatePlotSpaceForGraph:) withObject:_graph afterDelay:0.05];
}


@end
