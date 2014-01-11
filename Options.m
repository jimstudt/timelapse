//
//  Options.m
//  TimeLapse
//
//  Created by Jim Studt on 9/25/09.
//  Copyright 2009 Lunarware. All rights reserved.
//

#import "Options.h"
#import "Version.h"
#include <getopt.h>

static BOOL verbose = NO;
static NSString *outputName = @"timelapse.mov";
static BOOL noDups = NO;
static NSString *codec = nil;
static NSString *profile = nil;
static NSString *level = nil;
static NSNumber *quality = nil;
static NSNumber *averageBitRate = nil;

@implementation Options

+(BOOL)verbose { return verbose; }
+(BOOL)noDuplicates { return noDups; }
+(NSString *)output { return outputName; }
+(NSString *const)codec { return codec; }
+(NSString *const)profile {return profile; }
+(NSString *const)level { return level; }
+(NSNumber *const)quality { return quality; }  // jpeg only
+(NSNumber *const)averageBitRate {return averageBitRate; } // h.264 only

static void usage(const char *name, int error)  __attribute__((__noreturn__));
static void usage(const char *name, int error) {
    FILE *f = (error ? stderr : stdout);
    const char *slash = strrchr( name, '/');
    const char *n = (slash ? slash+1 : name);
    
    fprintf(f, "Usage: %s -o outfile [options] inputdir_or_images...\n", n);
    fprintf(f,
            "    version " TIMELAPSE_VERSION
            "  -v | --verbose               verbose output\n"
            "  -h | --help                  display usage and exit\n"
            "  -o fname | --output fname    specify output file - required\n"
            "                               end with .mp4 .m4v or .mov to select format\n"
            "  -n | --nodups                skip duplicated frames\n"
            "  -c codec | --codec name      codec name: h264 jpeg prores4444 prores422\n"
            "  -p profile | --profile name  h.264 profile: baseline main(default) high\n"
            "  -l level | --level name      h.264 level: 3.0 3.1 3.2 4.0 4.1 auto(default)"
            "  -b bitrate | --bitrate num   average bit rate in Mbps: e.g. 2.0"
            "  -q quality | --quality num   jpeg quality: e.g. 0.8");
    
    exit( error ? 1 : 0);
}

+(void)parseArgc:(int *)argc argv:(const char *[])argv
{
    static const char *optstring = "v?nho:c:p:l:b:q:";
    static const struct option longopts[] = {
        { "verbose", no_argument, 0, 'v'},
        { "help",    no_argument, 0, 'h'},
        { "output",  required_argument, 0, 'o'},
        { "codec",  required_argument, 0, 'c'},
        { "profile",  required_argument, 0, 'p'},
        { "level",  required_argument, 0, 'l'},
        { "bitrate",  required_argument, 0, 'b'},
        { "quality",  required_argument, 0, 'q'},
        { "nodup", no_argument, 0, 'n'},
        {0,0,0,0}
    };
    int ch;
    
    while( (ch = getopt_long(*argc, (char * const *)argv, optstring, longopts, NULL)) != -1) {
        switch(ch) {
            case 'v':
                verbose = YES;
                break;
            case 'o':
                outputName = @(optarg);
                break;
            case 'h':
                usage( argv[0], 0);
                break;
            case 'n':
                noDups = YES;
                break;
            case 'c':
                codec = @(optarg);
                break;
            case 'p':
                profile = @(optarg);
                break;
            case 'l':
                level = @(optarg);
                break;
            case 'q':
                quality = @([@(optarg) doubleValue]);
                break;
            case 'b':
                averageBitRate = @([@(optarg) doubleValue]*1000000.0);
                break;
            default:
                usage( argv[0], 1);
                break;
        }
    }
    for ( int i = 0; i < (*argc - optind); i++) {
        argv[i] = argv[i+optind];
    }
    *argc -= optind;
}

@end
