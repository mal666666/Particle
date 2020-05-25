//
//  ParticleView.m
//  视频加粒子动画
//
//  Created by Mac on 2020/5/22.
//  Copyright © 2020 马 爱林. All rights reserved.
//

#import "ParticleView.h"

@implementation ParticleView

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.3, 0.3, 0.3, 0.1f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

}

@end
