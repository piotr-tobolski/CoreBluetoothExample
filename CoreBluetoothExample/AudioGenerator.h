#import <Foundation/Foundation.h>

@interface AudioGenerator : NSObject

@property (nonatomic, readonly) BOOL isPlaying;

- (void)start;
- (void)stop;
- (void)setFrequency:(double)frequency;

@end
