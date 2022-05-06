//
//  DLog.m
//

#import "DLog.h"

@implementation DLog

+ (void)logFile:(char *)sourceFile lineNumber:(int)lineNumber format:(NSString *)format, ...;
{
    va_list ap;
    va_start(ap, format);
    NSString *file = [NSString stringWithUTF8String:sourceFile];
    NSString *print = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);
    NSLog(@"%s:%d %@", [[file lastPathComponent] UTF8String], lineNumber, print);
    [print release];
}

@end