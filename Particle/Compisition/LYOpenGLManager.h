//
//  LYOpenGLManager.h
//  LearnAVFoundation
//
//  Created by loyinglin on 2017/8/22.
//  Copyright © 2017年 loyinglin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface LYOpenGLManager : NSObject

@property (nonatomic,   copy) void(^compositionBlock)(CVPixelBufferRef buf);

+ (instancetype)shareInstance;

- (void)prepareToDraw:(CVPixelBufferRef)videoPixelBuffer andDestination:(CVPixelBufferRef)destPixelBuffer;

@end
