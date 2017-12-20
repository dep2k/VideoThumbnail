//
//  ViewController.m
//  OfflineDynamicThumnail
//
//  Created by Deep Arora on 12/19/17.
//  Copyright © 2017 Deep Arora. All rights reserved.
//

#import "ViewController.h"

#include <CoreMedia/CMTime.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

static void *kStatusDidChangeKVO        = &kStatusDidChangeKVO;
static void *kTimeRangesKVO             = &kTimeRangesKVO;

@interface ViewController ()

@property (nonatomic,strong )    AVPlayerItemVideoOutput * output;
@property (nonatomic,strong)     AVPlayer *player;
@property (nonatomic,strong)     AVPlayerItem *playerItem;
@property (nonatomic,assign)    bool isPlaying;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self load];
    // Do any additional setup after loading the view, typically from a nib.
}


-(void)generateThumb {
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        
        NSDictionary* settings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] };
        self.output = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:settings];
        [self.player.currentItem addOutput:self.output];
 
        CMTime vTime = CMTimeMakeWithSeconds(0.1, 90000);
        BOOL foundFrame = [self.output hasNewPixelBufferForItemTime:vTime];
        if(foundFrame || true){
       
            CIContext *temporaryContext = [CIContext contextWithOptions:nil];
            CVPixelBufferRef pixelBuffer = [self.output copyPixelBufferForItemTime:vTime itemTimeForDisplay:nil];
            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
            
            CGImageRef videoImage = [temporaryContext
                                     createCGImage:ciImage
                                     fromRect:CGRectMake(0, 0,
                                                         288,
                                                         192)];
            
            UIImage *image = [UIImage imageWithCGImage:videoImage];
            CGImageRelease(videoImage);
            NSLog(@"FrameFound");
        }else{
            NSLog(@"FrameNotFound");
        }
        

    });
   
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)load {
    
    
    NSURL * url = [[NSBundle bundleForClass:self.class] URLForResource:@"test" withExtension:@"mp4"];

    self.playerItem = [AVPlayerItem playerItemWithURL:url];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    layer.frame = self.view.frame;
    layer.backgroundColor = [UIColor redColor].CGColor;
    [self.view.layer addSublayer:layer];
    
    [self.player addObserver:self forKeyPath:@"currentItem.status"                      options:NSKeyValueObservingOptionNew context:kStatusDidChangeKVO];
    
    [self.player addObserver:self forKeyPath:@"currentItem.loadedTimeRanges"            options:NSKeyValueObservingOptionNew context:kTimeRangesKVO];
    
    
}

- (void) observeValueForKeyPath:(NSString*)inKeyPath ofObject:(id)inObject change:(NSDictionary*)inChange context:(void*)inContext
{
    if (inContext == kStatusDidChangeKVO){
        AVPlayerItemStatus status = self.player.currentItem.status;
        
        if (status == AVPlayerItemStatusReadyToPlay && self.player.status == AVPlayerStatusReadyToPlay) {
            
            if(!self.isPlaying){
                self.isPlaying = true;
                self.player.rate = 1.0;
                self.player.muted = YES;
              // [self.player play];
                //
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self generateThumb];
                });
            }
         
           //
            
        }
    } else if (inContext == kTimeRangesKVO){
        NSArray *timeRanges = (NSArray *)[inChange objectForKey:NSKeyValueChangeNewKey];
        NSLog(@"Time Ranges");
    }
    
}


//        if (!foundFrame) {
//            //
//            for (int i = 0; i < 10; i++) {
//                sleep(1);
//                vTime = [self.output itemTimeForHostTime:CACurrentMediaTime()];
//                foundFrame = [self.output hasNewPixelBufferForItemTime:vTime];
//                if (foundFrame) {
//                    NSLog(@"Got frame at %i", i);
//                    break;
//                } else {
//                    NSLog(@"Current time = %f", CACurrentMediaTime());
//                    NSLog(@"Calculate time = %lld", vTime.value);
//                }
//                if (i == 9) {
//                    NSLog(@"Failed to acquire");
//                }
//            }
//        }
@end
