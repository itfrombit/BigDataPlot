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

- (void)updatePlotSpaceForGraph:(CPTXYGraph*)graph
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
	CPTXYAxisSet* axisSet = (CPTXYAxisSet*)graph.axisSet;
	CPTXYAxis* x = axisSet.xAxis;
	x.majorIntervalLength = CPTDecimalFromDouble(0.0);
	x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0);
	x.minorTicksPerInterval = 0;
	CPTPlotRange* xAxisRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat([_model effectiveCount])];
	x.visibleRange = xAxisRange;
	x.gridLinesRange = xAxisRange;
	
	CPTXYAxis* y = axisSet.yAxis;
	y.majorIntervalLength = CPTDecimalFromDouble(0.5);
	y.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0);
	y.minorTicksPerInterval = 4;
	CPTPlotRange* yAxisRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-1.0) length:CPTDecimalFromFloat(2.0)];
	y.visibleRange = yAxisRange;
	y.gridLinesRange = yAxisRange;
	
	//graph.axisSet.axes = [NSArray arrayWithObjects:x, y, nil];
	
	CPTXYPlotSpace* plotSpace = (id)graph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = NO;
	plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat([_model effectiveCount])];
	plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-1.0) length:CPTDecimalFromFloat(2.0)];
	
	[graph reloadData];
	[graph setNeedsLayout];
	[graph setNeedsDisplay];
}

- (void)setupGraph
{
	_graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:NSRectToCGRect(_hostingView.bounds)];
	CPTTheme *theme = [CPTTheme themeNamed:kCPTSlateTheme];
    [_graph applyTheme:theme];
	_hostingView.hostedLayer = _graph;
    
    // Graph title
    _graph.title = _filename;
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor grayColor];
    textStyle.fontName = @"Helvetica-Bold";
    textStyle.fontSize = 18.0;
    _graph.titleTextStyle = textStyle;
    _graph.titleDisplacement = CGPointMake(0.0, 20.0);
    _graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
	
    // Graph padding
    _graph.paddingLeft = 20.0;
    _graph.paddingTop = 40.0;
    _graph.paddingRight = 20.0;
    _graph.paddingBottom = 20.0;
	
	// Axes
	CPTXYAxisSet* axisSet = (CPTXYAxisSet*)_graph.axisSet;
	CPTXYAxis* x = axisSet.xAxis;
	x.majorIntervalLength = CPTDecimalFromDouble(0.0);
	x.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0);
	x.minorTicksPerInterval = 0;
	CPTPlotRange* xAxisRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat([_model effectiveCount])];
	x.visibleRange = xAxisRange;
	x.gridLinesRange = xAxisRange;
	
	CPTXYAxis* y = axisSet.yAxis;
	y.majorIntervalLength = CPTDecimalFromDouble(0.5);
	y.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0);
	y.minorTicksPerInterval = 4;
	CPTPlotRange* yAxisRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-1.0) length:CPTDecimalFromFloat(2.0)];
	y.visibleRange = yAxisRange;
	y.gridLinesRange = yAxisRange;
	
	_graph.axisSet.axes = [NSArray arrayWithObjects:x, y, nil];
	
	// Scatter plot
	CPTScatterPlot* plot = [[[CPTScatterPlot alloc] init] autorelease];
	plot.dataSource = self;
	plot.delegate = self;
	
	CPTXYPlotSpace* plotSpace = (id)_graph.defaultPlotSpace;
	plotSpace.allowsUserInteraction = NO;
	plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat([_model effectiveCount])];
	plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-1.0) length:CPTDecimalFromFloat(2.0)];
	
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

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
	int count = [_model effectiveCount];
	
	NSLog(@"Point count is %d", count);

	return count;
}

-(NSNumber*)numberForPlot:(CPTPlot*)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber* num;
	
    if (fieldEnum == CPTScatterPlotFieldX)
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
    else if (fieldEnum == CPTScatterPlotFieldY)
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
