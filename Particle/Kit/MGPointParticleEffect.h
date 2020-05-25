//
//  MGPointParticleEffect.h
//  Particle
//
//  Created by Mac on 2019/8/13.
//  Copyright © 2019 马 爱林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN
extern const GLKVector3 MGDefaultGravity;//重力加速度

@interface MGPointParticleEffect : NSObject

@property (nonatomic, assign) GLKVector3  gravity;//重力
@property (nonatomic, assign) GLfloat  elapsedSeconds;//耗时,时间消逝
@property (nonatomic, strong,readonly) GLKEffectPropertyTexture *texture2d0;//纹理
@property (nonatomic, strong,readonly) GLKEffectPropertyTexture *texture2d1;//纹理
@property (nonatomic, strong,readonly) GLKEffectPropertyTransform *transform;//变换

//添加粒子
/*
 aPosition:位置
 aVelocity:速度
 aForce:重力
 aSize:大小
 aSpan:跨度，连续添加粒子多长时间，再去更新
 aDuration:时长
 */
-(void)addParticleAtPosition:(GLKVector3)aPosition
                   velocity:(GLKVector3)aVelocity
                      force:(GLKVector3)aForce
                       size:(float)aSize
             lifeSpanSecond:(NSTimeInterval)aSpan
         fadeDurationSecond:(NSTimeInterval)aDuration;

//准备绘制
-(void)prepareToDraw;
//绘制
-(void)draw;
@end

NS_ASSUME_NONNULL_END
