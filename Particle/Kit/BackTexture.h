//
//  BackTexture.h
//  视频加粒子动画
//
//  Created by Mac on 2019/8/26.
//  Copyright © 2019 马 爱林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BackTexture : NSObject

@property(nonatomic,strong)EAGLContext *myContext;
@property(nonatomic,strong)CAEAGLLayer *myEagLayer;
-(void)addTexture;

@end

NS_ASSUME_NONNULL_END
