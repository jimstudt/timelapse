#import <Foundation/Foundation.h>

#import "Options.h"
@import CoreVideo;
@import AVFoundation;

//
// Examine the Options and construct the dictionary for [AVAssetWriterInput assetWriterInputWithMediaType:outputSettings:]
//
static NSDictionary *getVideoSettings(NSSize size)
{
    NSString *const codec = [Options codec];
    if (codec == nil || [codec isEqualToString:@"h264"]) {
        NSMutableDictionary *compression = [NSMutableDictionary dictionary];
        
        if ( [Options averageBitRate]) compression[AVVideoAverageBitRateKey] = [Options averageBitRate];
        
        NSString *const profile = [Options profile];
        if ( profile != nil) {
            NSString *const level = [Options level];
            
            NSDictionary *profileMap = @{@"baseline3.0": AVVideoProfileLevelH264Baseline30,
                                         @"baseline3.1": AVVideoProfileLevelH264Baseline31,
                                         @"baseline4.1": AVVideoProfileLevelH264Baseline41,
                                         @"baseline": AVVideoProfileLevelH264BaselineAutoLevel,
                                         @"main3.0": AVVideoProfileLevelH264Main30,
                                         @"main3.1": AVVideoProfileLevelH264Main31,
                                         @"main3.2": AVVideoProfileLevelH264Main32,
                                         @"main4.1": AVVideoProfileLevelH264Main41,
                                         @"main": AVVideoProfileLevelH264MainAutoLevel,
                                         @"high4.0": AVVideoProfileLevelH264High40,
                                         @"high4.1": AVVideoProfileLevelH264High41,
                                         @"high": AVVideoProfileLevelH264HighAutoLevel,
                                         };
            NSString *profileLevel = nil;
            if ( level == nil) {
                profileLevel = profileMap[profile];
                if (profileLevel == nil) NSLog(@"Invalid profile: %@", profile);
            } else {
                NSString *profileKey = [NSString stringWithFormat:@"%@%@", profile, level];
                profileLevel = profileMap[profileKey];
                if (profileLevel == nil) NSLog(@"Invalid profile,level pair: %@, %@", profile, level);
            }
            if (profileLevel != nil) compression[AVVideoProfileLevelKey] = profileLevel;
        }
        
        return @{ AVVideoCodecKey: AVVideoCodecH264,
                  AVVideoWidthKey: @(size.width),
                  AVVideoHeightKey: @(size.height),
                  AVVideoCompressionPropertiesKey: compression,
                  };
    }
    if ( [codec isEqualToString:@"jpeg"]) {
        NSMutableDictionary *compression = [NSMutableDictionary dictionary];
        if ( [Options quality]) compression[AVVideoQualityKey] = [Options quality];
  
        return @{ AVVideoCodecKey: AVVideoCodecJPEG,
                  AVVideoWidthKey: @(size.width),
                  AVVideoHeightKey: @(size.height),
                  AVVideoCompressionPropertiesKey: compression,
                  };
    }
    if ( [codec isEqualToString:@"prores4444"]) {
        return @{ AVVideoCodecKey: AVVideoCodecAppleProRes4444,
                  AVVideoWidthKey: @(size.width),
                  AVVideoHeightKey: @(size.height),
                  };
    }
    if ( [codec isEqualToString:@"prores422"]) {
        return @{ AVVideoCodecKey: AVVideoCodecAppleProRes422,
                  AVVideoWidthKey: @(size.width),
                  AVVideoHeightKey: @(size.height),
                  };
    }
    fprintf(stderr, "Unsupported codec: '%s'. Consider h264, jpeg, prores4444, or prores422\n", [codec UTF8String]);
    exit(1);
}

//
// Examine the output file URL and return the fileType for AVAssetWriter assetWriterWithURL:fileType:error:
//
static NSString *const fileTypeForURL(NSURL *url)
{
    NSString *extension = url.path.pathExtension;
    
    if ( [extension isEqualToString:@"mp4"]) return AVFileTypeMPEG4;
    if ( [extension isEqualToString:@"m4v"]) return AVFileTypeAppleM4V;
    if ( [extension isEqualToString:@"mov"] || [extension isEqualToString:@".qt"]) return AVFileTypeQuickTimeMovie;
    return AVFileTypeMPEG4;
    
}

//
// Given an array of paths, walk all of the directories and sort all the files into an array of NSURLs
// Skip hidden files and omit directories.
//
static NSArray *walkAndSort( NSArray *roots)
{
    NSMutableArray *urls = [NSMutableArray array];

    for (id root in roots) {
        NSString *rootStr = root;
        NSURL *durl = [NSURL fileURLWithPath:rootStr];
        NSDirectoryEnumerator *denum = [[NSFileManager defaultManager] enumeratorAtURL:durl
                                                            includingPropertiesForKeys:NULL
                                                                               options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                          errorHandler:NULL];
        NSURL *url = nil;
        while( url = [denum nextObject]) {
            NSError *error;
            NSNumber *isDirectory = nil;
            if (! [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error]) {
                // handle error
                NSLog(@"error testing %@ for being a directory", url);
            } else if (! [isDirectory boolValue]) {
                [urls addObject:url];
            }

        }
    }
    [urls sortUsingComparator:^(id a, id b){ return [[a absoluteString] compare:[b absoluteString]]; }];

    return urls;
}

//
// Convert an NSImage into a CVPixelBufferRef
//
// From http://stackoverflow.com/questions/17481254/how-to-convert-nsdata-object-with-jpeg-data-into-cvpixelbufferref-in-os-x
//
static CVPixelBufferRef newPixelBufferFromNSImage(NSImage* image)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    NSDictionary* pixelBufferProperties = @{(id)kCVPixelBufferCGImageCompatibilityKey:@YES, (id)kCVPixelBufferCGBitmapContextCompatibilityKey:@YES};
    CVPixelBufferRef pixelBuffer = NULL;
    CVPixelBufferCreate(kCFAllocatorDefault, [image size].width, [image size].height, k32ARGBPixelFormat, (__bridge CFDictionaryRef)pixelBufferProperties, &pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    CGContextRef context = CGBitmapContextCreate(baseAddress, [image size].width, [image size].height, 8, bytesPerRow, colorSpace, kCGImageAlphaNoneSkipFirst);
    NSGraphicsContext* imageContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:imageContext];
    [image drawAtPoint:NSMakePoint(0.0, 0.0) fromRect:NSMakeRect(0, 0, [image size].width, [image size].height) operation:NSCompositeCopy fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CFRelease(context);
    CGColorSpaceRelease(colorSpace);
    return pixelBuffer;
}


int main (int argc, const char * argv[]) {
    @autoreleasepool {
        NSDate *started = [NSDate date];
        
        [Options parseArgc:&argc argv:argv];

        CMTimeValue framesPerSecond = [Options framesPerSecond];
        if ( framesPerSecond < 1 ) {
            NSLog(@"Frames per second is less than 1, error");
            exit(1);
        }
        
        // Walk the roots and come up with a list of urls to process.
        // We can't pipeline this since it gets sorted.
        NSMutableArray *roots = [NSMutableArray array];
        for ( int i = 0; i < argc; i++) {
            [roots addObject:@(argv[i])];
        }
        NSArray *urls = walkAndSort(roots);
        
        //
        // If there are no inputs, then we can't do anything.
        //
        if ( urls.count == 0) {
            NSLog(@"No input files. Will not create output.");
            exit(0);
        }
        
        // Get size from first available image
        NSSize size = NSZeroSize;
        for (NSURL *file in urls) {
            NSImage *img = [[NSImage alloc] initWithContentsOfURL:file];
            if ( img) {
                size = img.size;
                break;
            }
        }

        //
        // Abort if we have a zero size
        //
        if ( size.width == 0 || size.height == 0) {
            NSLog(@"First image had a zero dimension. Unable to choose an output size.");
            exit(1);
        }
        
        NSString *outputPath = [Options output];
        
        // Delete file if already present
        {
            NSError *rmError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:outputPath error:&rmError];
        }
        
        NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
        NSError *awError = nil;
        AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:outputURL fileType:fileTypeForURL(outputURL) error:&awError];
        if ( !writer) {
            NSLog(@"Failed to create AVAssetWriter: %@", awError);
        }
        
        AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                             outputSettings:getVideoSettings(size)];
        [writer addInput:writerInput];
        
        AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor =
        [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                                         sourcePixelBufferAttributes:nil];

        NSDate *readyToWriteMovie = [NSDate date];
        
        if ( ![ writer startWriting]) {
            NSLog(@"Failed to start writing: %@", [writer error]);
        }
        [writer startSessionAtSourceTime:kCMTimeZero];
        if ( [Options verbose]) NSLog(@"started session");

        dispatch_group_t decodingGroup = dispatch_group_create();
        dispatch_group_enter(decodingGroup);
        
        dispatch_queue_t decoderQueue = dispatch_queue_create("frameDecoder", DISPATCH_QUEUE_SERIAL);
        
        __block CMTimeValue frame = 0;
        __block NSData *previousImgData = nil;
        __block NSUInteger nextUrl = 0;
        
        //
        // This is invoked repeatedly by requestMeduaDataWhenReadyOnQueue:usingBlock: to produce frames.
        // It is to return whenever writerInput is not ready for more data. Sort of a little inside-out
        // flowcontrol.
        //
        dispatch_block_t generator = ^() {
            for (;;) {
                // If we have reached the end, then bail out.
                if ( nextUrl >= [urls count]) {
                    [writerInput markAsFinished];
                    dispatch_group_leave(decodingGroup);
                    return;
                }

                // If we have overrun the encoder, then exit. We will get called again
                // when it is ready.
                if ( ![writerInput isReadyForMoreMediaData]) return;
                
                // Get our next URL
                NSURL *file = [urls objectAtIndex:nextUrl++];
                
                @autoreleasepool {
                    NSData *data = [[NSData alloc] initWithContentsOfURL:file];
                    if ( !data) {
                        NSLog(@"bad url %@, skipped", file);
                    } else {
                        if ( !previousImgData || ![Options noDuplicates] || ![data isEqualToData:previousImgData]) {
                            previousImgData = data;
                            NSImage *img = [[NSImage alloc] initWithData:data];
                            if ( !img) {
                                NSLog(@"bad image %@, skipped", file);
                            } else {
                                CVPixelBufferRef pBuf = newPixelBufferFromNSImage(img);
                                [pixelBufferAdaptor appendPixelBuffer:pBuf
                                                 withPresentationTime:CMTimeMake(frame++,framesPerSecond)];
                                CFRelease(pBuf);
                                if ( [Options verbose] ) NSLog(@"did image %@", file);
                            }
                        } else {
                            if ( [Options verbose] ) NSLog(@"skipped %@", file);
                        }
                    }
                }
            }
        };

        // Start requesting frames
        [writerInput requestMediaDataWhenReadyOnQueue:decoderQueue usingBlock:generator];
        
        // Wait for the decoding to complete.
        dispatch_group_wait(decodingGroup, DISPATCH_TIME_FOREVER);
        
        // Use a group to tell when we are done writing output.
        dispatch_group_t outputGroup = dispatch_group_create();
        dispatch_group_enter(outputGroup);
        

        [writer finishWritingWithCompletionHandler:^() {
            if ( writer.status != AVAssetWriterStatusCompleted) {
                NSLog(@"encoding FAILED: %@", writer.error);
            }
            if ( [Options verbose] ) NSLog(@"finished writing");
            dispatch_group_leave(outputGroup);
        }];
        
        if ( [Options verbose] ) NSLog(@"waiting to finish");
        dispatch_group_wait(outputGroup, DISPATCH_TIME_FOREVER);
        if ( [Options verbose] ) NSLog(@"finished");
        
        NSDate *finished = [NSDate date];
        
        if ( [Options verbose]) {
            NSLog(@"time to write movie: %6.2f seconds.", [finished timeIntervalSinceDate:readyToWriteMovie]);
            NSLog(@"      total runtime: %6.2f seconds.", [finished timeIntervalSinceDate:started]);
        }
    }
    return 0;
}
