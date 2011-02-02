//
//  BigDataModel.h
//  BigData
//
//  Created by Jeff on 2/1/11.
//  Copyright 2011 Jeff Buck. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct
{
	double	min;
	double	max;
	double	rms;
	double	avg;
} DATA_SAMPLE;

@interface BigDataModel : NSObject
{
	NSString*		_filename;
	float*			_data;
	int				_rawCount;

	BOOL			_isSampling;
	int				_sampleCount;
	int				_sampleWindowSize;
	int				_sampleBufferElementCount;
	DATA_SAMPLE*	_sample;
}

- (id)initWithFilename:(NSString*)filename;
- (void)readFile;

- (int)dataCount;
- (double)dataAtIndex:(int)i;

- (BOOL)isSampling;
- (int)sampleCount;
- (void)resampleDataWithSampleCount:(int)sampleCount;
- (double)minAtSample:(int)index;
- (double)maxAtSample:(int)index;

- (int)effectiveCount;

@end
