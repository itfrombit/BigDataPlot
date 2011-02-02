//
//  BigDataModel.m
//  BigData
//
//  Created by Jeff on 2/1/11.
//  Copyright 2011 Jeff Buck. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/ExtendedAudioFile.h>

//#import <CoreAudio/CoreAudio.h>
//#import <CoreAudio/CoreAudioTypes.h>
#import "CAStreamBasicDescription.h"

#import "BigDataModel.h"

const Float64 kAudioSampleRate = 44100.0;


#define _ThrowExceptionIfErr(name, err) if (err != noErr) { NSException* e = [NSException exceptionWithName:name reason:name userInfo:nil]; @throw e; }


@implementation BigDataModel

- (id)initWithFilename:(NSString*)filename
{
	self = [super init];
	
	if (self == nil)
		return nil;
	
	_filename = [filename copy];
	
	_data = NULL;
	_rawCount = 0;
	
	_isSampling = NO;
	_sampleCount = 0;
	_sampleWindowSize = 0;
	_sampleBufferElementCount = 0;
	_sample = NULL;
	
	return self;
}

- (NSString*)description
{
	double min;
	double max;

	for (int i = 0; i < _rawCount; i++)
	{
		if (i == 0)
		{
			min = _data[i];
			max = _data[i];
		}
		else
		{
			if (_data[i] < min)
				min = _data[i];
			
			if (_data[i] > max)
				max = _data[i];
		}
	}

	return [NSString stringWithFormat:@"Count: %d   Min = %lf   Max = %lf",
			_rawCount,
			min,
			max];
}

- (int)dataCount
{
	return _rawCount;
}

- (int)sampleCount
{
	return _sampleCount;
}

- (int)sampleWindowSize
{
	return _sampleWindowSize;
}

- (double)dataAtIndex:(int)i
{
	return _data[i];
}

- (double)minAtSample:(int)index
{
	return _sample[index].min;
}

- (double)maxAtSample:(int)index
{
	return _sample[index].max;
}

- (BOOL)isSampling
{
	return _isSampling;
}

- (int)effectiveCount;
{
	int count; 

	if (_isSampling)
	{
		count = _sampleCount;
	}
	else
	{
		count = _rawCount;
	}
	
	return count;
}

- (void)resampleDataWithSampleCount:(int)sampleCount
{
	int datapointsPerSample = _rawCount / sampleCount; // truncate on purpose
	if (datapointsPerSample <= 2)
	{
		// Don't bother. Just return the individual values;
		_isSampling = NO;
	}
	else
	{
		_isSampling = YES;
		_sampleCount = sampleCount;
		_sampleWindowSize = datapointsPerSample; // stride
		
		// We don't free this every time, we just grow it when needed.
		if (_sampleBufferElementCount < _sampleCount)
		{
			if (_sample)
			{
				free(_sample);
			}
			
			_sample = (DATA_SAMPLE*)malloc(_sampleCount * sizeof(DATA_SAMPLE));
			_sampleBufferElementCount = _sampleCount;
		}

		for (int i = 0; i < _sampleCount; i++)
		{
			int index = i * _sampleWindowSize;
			_sample[i].min = _data[index];
			_sample[i].max = _data[index];

			int sampleIndexLimit = (i + 1) * _sampleWindowSize;
			while ((index < sampleIndexLimit) && (index < _rawCount))
			{
				if (_data[index] < _sample[i].min)
				{
					_sample[i].min = _data[index];
				}
				
				if (_data[index] > _sample[i].max)
				{
					_sample[i].max = _data[index];
				}
				
				++index;
			}
		}
	}
}

- (void)readFile
{
	ExtAudioFileRef audioRef = nil;
	
	@try
	{
		OSStatus err = noErr;
		
		NSURL* url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"SampleAudio.L" ofType:@"wav"]];

		err = ExtAudioFileOpenURL((CFURLRef)url, &audioRef);
		
		UInt32 size;
		SInt64 frames;
		
		CAStreamBasicDescription format;
		size = sizeof(format);
		
		err = ExtAudioFileGetProperty(audioRef, kExtAudioFileProperty_FileDataFormat, &size, &format);
		_ThrowExceptionIfErr(@"kExtAudioFileProperty_FileDataFormat", err);
		
		size = sizeof(SInt64);
		err = ExtAudioFileGetProperty(audioRef, kExtAudioFileProperty_FileLengthFrames, &size, &frames);
		
		// If you need to alloc a buffer, you'll need to alloc filelength*channels*rateRatio bytes
		//double rateRatio = kGraphSampleRate / clientFormat.mSampleRate;
		
		// read as 44.1kHz 1Ch audio in  this example
		format.mSampleRate = kAudioSampleRate;
		format.SetCanonical(1, true);
		
		size = sizeof(format);
		err = ExtAudioFileSetProperty(audioRef, kExtAudioFileProperty_ClientDataFormat, size, &format);
		_ThrowExceptionIfErr(@"kExtAudioFileProperty_ClientDataFormat", err);
		
		UInt32 numPackets = frames; // read the whole file
		UInt32 samples = numPackets; // 1 channels (samples) per frame
		_rawCount = samples;
		
		_data = (float*)malloc(samples * sizeof(float));
		
		AudioBufferList bufferList;
		bufferList.mNumberBuffers = 1;
		bufferList.mBuffers[0].mNumberChannels = 1; // Always 2 channels in this example
		bufferList.mBuffers[0].mData = _data; // data is a pointer (float*) so our sample buffer
		bufferList.mBuffers[0].mDataByteSize = samples * sizeof(Float32);
		
		UInt32 loadedPackets = numPackets;
		err = ExtAudioFileRead(audioRef, &loadedPackets, &bufferList);
		_ThrowExceptionIfErr(@"ExtAudioFileRead", err);
		
		ExtAudioFileDispose(audioRef);
		
		NSLog(@"Model: %@", [self description]);
	}
	@catch(NSException* exception)
	{
		if (_data) free(_data);
		_data = nil;
		
		if(audioRef)
			ExtAudioFileDispose(audioRef);
		
		NSLog(@"loadSegment: Caught %@: %@", [exception name], [exception reason]);
	}
}

- (void)dealloc
{
	[_filename release];
	if (_data) free(_data);
	if (_sample) free(_sample);
	
	[super dealloc];
}

@end
