//
//  ViewController.m
//  Particle
//
//  Created by Mac on 2019/8/12.
//  Copyright © 2019 马 爱林. All rights reserved.
//

#import "ViewController.h"
#import "MGPointParticleEffect.h"
#import "MGVertexAttribArrayBuffer.h"
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/ES2/glext.h>
#import "LYVideoCompostion.h"
#import "BackTexture.h"
#import "ParticleView.h"


@interface ViewController ()

@property (nonatomic, strong) EAGLContext *mContext;
@property (nonatomic, strong) MGPointParticleEffect *particleEffect;//管理并绘制所有粒子

@property (nonatomic, assign) NSTimeInterval  autoSpawnDelta;//过多长时间发射一次
@property (nonatomic, assign) NSTimeInterval  lastSpawnTime;//时间一直累加

@property (nonatomic, assign) NSInteger  currentEmitterIndex;
@property (nonatomic, strong) NSArray *emitterBlocks;
@property (nonatomic, strong) GLKTextureInfo *ballParticleTexture;//纹理
@property (nonatomic, strong) GLKTextureInfo *Texture1;//纹理1


@property (nonatomic, strong) CALayer *animaLayer;//动画
@property (nonatomic, strong) GLKView *particleView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //OpenGL ES上下文
    self.mContext =[[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    GLKView *view =[[GLKView alloc]initWithFrame:self.view.bounds context:self.mContext];
    [self.view addSubview:view];
    _particleView =view;
    view.delegate =self;
    view.context =self.mContext;
    view.drawableColorFormat =GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat =GLKViewDrawableDepthFormat24;
    [EAGLContext setCurrentContext:self.mContext];
    self.preferredFramesPerSecond =60;
    view.backgroundColor =[UIColor clearColor];
    view.layer.backgroundColor =[UIColor clearColor].CGColor;
    _animaLayer =view.layer;
    
    //纹理
    NSString *path =[[NSBundle bundleForClass:[self class]] pathForResource:@"ball" ofType:@"png"];
    self.ballParticleTexture =[GLKTextureLoader textureWithContentsOfFile:path options:nil error:nil];
    NSString *path1 =[[NSBundle bundleForClass:[self class]] pathForResource:@"qq" ofType:@"png"];
    self.Texture1 =[GLKTextureLoader textureWithContentsOfFile:path1 options:nil error:nil];
    //粒子
    self.particleEffect =[[MGPointParticleEffect alloc]init];
    self.particleEffect.texture2d0.name =self.ballParticleTexture.name;
    self.particleEffect.texture2d0.target =self.ballParticleTexture.target;
    self.particleEffect.texture2d1.name =self.Texture1.name;
    self.particleEffect.texture2d1.target =self.Texture1.target;
    //
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    //
    void(^blockA)(void) = ^{
        self.autoSpawnDelta = 0.5f;
        //重力
        self.particleEffect.gravity = MGDefaultGravity;
        //X轴上随机速度
        float randomXVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
        /*
         Position:出发位置
         velocity:速度
         force:抛物线
         size:大小
         lifeSpanSeconds:耗时
         fadeDurationSeconds:渐逝时间
         */
        [self.particleEffect
         addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.9f)
         velocity:GLKVector3Make(randomXVelocity, 1.0f, -1.0f)
         force:GLKVector3Make(0.0f, 9.0f, 0.0f) size:8.0f
         lifeSpanSecond:3.2f
         fadeDurationSecond:0.5f];
    };
    //
    void(^blockE)(void) = ^{
        self.autoSpawnDelta = 0.01f;
        //重力
        self.particleEffect.gravity = MGDefaultGravity;
        //X轴上随机速度
        float randomXVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
        /*
         Position:出发位置
         velocity:速度
         force:抛物线
         size:大小
         lifeSpanSeconds:耗时
         fadeDurationSeconds:渐逝时间
         */
        [self.particleEffect
         addParticleAtPosition:GLKVector3Make(randomXVelocity, 0.99f, 0.4f)
         velocity:GLKVector3Make(0.0f, 0.0f, -0.1f)
         force:GLKVector3Make(0.0f, 9.0f, 0.0f) size:8.0f
         lifeSpanSecond:3.2f
         fadeDurationSecond:0.5f];
    };

    self.emitterBlocks =@[[blockA copy], [blockE copy]];
    float aspect =CGRectGetWidth(self.view.bounds)/CGRectGetHeight(self.view.bounds);
    [self preparePointOfViewWithAspectRatio:aspect];
}
//MVP矩阵
-(void)preparePointOfViewWithAspectRatio:(GLfloat)aspectRatio{
    //设置透视投影矩阵
    self.particleEffect.transform.projectionMatrix =GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85), aspectRatio, 0.1f, 20.0f);
    //模型试图变换矩阵，第一组，眼睛位置，第二组，物体位置，第三组，头顶朝向
    self.particleEffect.transform.modelviewMatrix =GLKMatrix4MakeLookAt(
                                                                        0.0, 0.0, 1.0,
                                                                        0.0, 0.0, 0.0,
                                                                        0.0, 1.0, 0.0);
}
-(void)update{
    self.particleEffect.elapsedSeconds =self.timeSinceFirstResume;
    if (self.autoSpawnDelta<(self.timeSinceFirstResume -self.lastSpawnTime)) {
        self.lastSpawnTime =self.timeSinceFirstResume;
        void(^emitterBlock)(void) =[self.emitterBlocks objectAtIndex:1];
        emitterBlock();
    }
    [_particleView display];
}
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(0.3, 0.3, 0.3, 0.1f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self.particleEffect prepareToDraw];
    [self.particleEffect draw];
}
-(NSUInteger)degressFromVideoFileWithAsset:(AVAsset*)asset {
   NSUInteger degress = 0;
   NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
   if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
    return degress;
}
- (void)insertPictureWith:(NSString *)videoPath outPath:(NSString *)outPath animLayer:(CALayer *)aLayer{
    // 1. 获取视频资源`AVURLAsset`。
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];// 本地文件
    AVAsset *videoAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    
    if (!videoAsset) {
        return;
    }
    CMTime durationTime = videoAsset.duration;//视频的时长
    // 2. 创建自定义合成对象`AVMutableComposition`，我定义它为可变组件。
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    // 3. 在可变组件中添加资源数据，也就是轨道`AVMutableCompositionTrack`（一般添加2种：音频轨道和视频轨道）
    // - 视频轨道
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    NSArray *videoAssetTraks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
    if (videoAssetTraks.count == 0) {
        return;
    }
    AVAssetTrack *videoAssetTrack1 = [videoAssetTraks firstObject];
    
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, durationTime)
                        ofTrack:videoAssetTrack1
                         atTime:kCMTimeZero
                          error:nil];
    // - 音频轨道
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    NSArray *audioAssetTraks = [videoAsset tracksWithMediaType:AVMediaTypeAudio];
    if (audioAssetTraks.count == 0) {
        return;
    }
    AVAssetTrack *audioAssetTrack = [audioAssetTraks firstObject];
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, durationTime)
                        ofTrack:audioAssetTrack
                         atTime:kCMTimeZero
                          error:nil];
    
    // 6. 创建视频应用层的指令`AVMutableVideoCompositionLayerInstruction` 用户管理视频框架应该如何被应用和组合,也就是说是子视频在总视频中出现和消失的时间、大小、动画等。
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    // - 设置视频层级的一些属性 /准备好机器加工粮食
    [videolayerInstruction setTransform:videoAssetTrack1.preferredTransform atTime:kCMTimeZero];
    
    // 5. 创建视频组件的指令`AVMutableVideoCompositionInstruction`，这个类主要用于管理应用层的指令。
    AVMutableVideoCompositionInstruction *mainCompositionIns = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainCompositionIns.timeRange = CMTimeRangeMake(kCMTimeZero, durationTime);// 设置视频轨道的时间范围
    mainCompositionIns.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
    
    // 4. 创建视频组件`AVMutableVideoComposition`,这个类是处理视频中要编辑的东西。可以设定所需视频的大小、规模以及帧的持续时间。以及管理并设置视频组件的指令
    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];
    //CGSize videoSize = videoAssetTrack1.naturalSize;
    CGAffineTransform translateToCenter;
    CGAffineTransform mixedTransform;
    NSUInteger degrees = [self degressFromVideoFileWithAsset:videoAsset];
    if (degrees == 0) { //不需要旋转
    } else{
        if(degrees == 90){
            //顺时针旋转90°
            NSLog(@"视频旋转90度,home按键在左");
            translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2);
            mainComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);

        } else if(degrees == 180){
            //顺时针旋转180° NSLog(@"视频旋转180度，home按键在上");
            translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI);
            mainComposition.renderSize = CGSizeMake(videoTrack.naturalSize.width,videoTrack.naturalSize.height);

        } else { //顺时针旋转270° NSLog(@"视频旋转270度，home按键在右");
            translateToCenter = CGAffineTransformMakeTranslation(0.0, videoTrack.naturalSize.width);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2*3.0);
            mainComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);

        }
    }
    mainComposition.instructions = [NSArray arrayWithObject:mainCompositionIns];
    mainComposition.frameDuration = CMTimeMake(1, 60); // FPS 帧
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, mainComposition.renderSize.width, mainComposition.renderSize.height);
    videoLayer.frame = CGRectMake(0, 0, mainComposition.renderSize.width, mainComposition.renderSize.height);
    aLayer.frame =CGRectMake(10, 10, CGRectGetWidth(videoLayer.frame)-20, CGRectGetHeight(videoLayer.frame)-20);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:aLayer];
    

    mainComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    //mainComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayers:@[videoLayer, aLayer] inLayer:parentLayer];
    //mainComposition.animationTool =[AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithAdditionalLayer:aLayer asTrackID:kCMPersistentTrackID_Invalid];
    
    // 7. 创建视频导出会话对象`AVAssetExportSession`,主要是根据`videoComposition`去创建一个新的视频，并输出到一个指定的文件路径中去。
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(durationTime.value , durationTime.timescale));
    exporter.outputURL = [NSURL fileURLWithPath:outPath];
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainComposition;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (exporter.status == AVAssetExportSessionStatusCompleted) {
                UISaveVideoAtPathToSavedPhotosAlbum(outPath, nil, nil, nil);
                NSLog(@"合成成功");
            }else {
                NSLog(@"合成失败 ---- -%@",exporter.error);
            }
        });
    }];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"IMG_7112" ofType:@"MOV"];
    //NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"压缩后" ofType:@"mp4"];
    NSString *outPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    outPath =[outPath stringByAppendingString:@"mtv.mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outPath error:nil];
    }
    [self insertPictureWith:videoPath outPath:outPath animLayer:_animaLayer];
    NSLog(@"%@",outPath);
}


@end
