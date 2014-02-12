//
//  Options.h
//  TimeLapse
//
//  Created by Jim Studt on 9/25/09.
//  Copyright 2009 Lunarware. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Options : NSObject {

}

+(void)parseArgc:(int *)argc argv:(const char *[])argv ;
+(BOOL)verbose;
+(NSString *)output;
+(int) framesPerSecond;
+(NSString *const)codec;
+(NSString *const)profile;
+(NSString *const)level;
+(NSNumber *const)quality;  // jpeg only
+(NSNumber *const)averageBitRate; // h.264 only
// i skip some h.264 keyframe options

+(BOOL)noDuplicates;

@end
