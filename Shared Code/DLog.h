//
//  DLog.h
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define DLog(s,...) [DLog logFile:__FILE__ lineNumber:__LINE__ format:(s),##__VA_ARGS__]
#else
#define DLog(s,...) do {} while (0);
#endif


@interface DLog : NSObject
{
}

+ (void)logFile:(char *)sourceFile lineNumber:(int)lineNumber format:(NSString *)format, ...;
@end