//
//  MGPointParticleEffect.m
//  Particle
//
//  Created by Mac on 2019/8/13.
//  Copyright © 2019 马 爱林. All rights reserved.
//

#import "MGPointParticleEffect.h"
#import "MGVertexAttribArrayBuffer.h"

//粒子属性
typedef struct {
    GLKVector3 emissionPosition;//发射位置
    GLKVector3 emissionVelocity;//发射速度
    GLKVector3 emissionForce;//发射重力
    GLKVector2 size;//大小
    GLKVector2 emissionTimeAndLife;//发射时间和寿命
}MGParticleAttributes;

//GLSL程序 Uniform参数
enum{
    MGMVPMatrix,
    MGSamplers2D,
    MGElasedSeconds,//耗时
    MGGravity,//重力
    MGNumUniforms
};

//属性标示符
typedef enum {
    MGParticleEmissionPosition =0,
    MGParticleEmissionVelocity,//速度
    MGParticleEmissionForce,//重力
    MGParticleSize,
    MGParticleEmissionTimeAndLife//粒子发射时间和寿命
}MGParticleAttrib;

@interface MGPointParticleEffect(){
    GLuint program;
    GLint uniforms[MGNumUniforms];//Uniforms数组
}

//顶点属性数组缓冲区
@property (nonatomic, strong) MGVertexAttribArrayBuffer *particleAttributeBuffer;

//粒子个数
@property (nonatomic, assign, readonly) NSUInteger numberOfParticles;

//粒子属性数据
@property (nonatomic, strong, readonly) NSMutableData *particleAttributesData;

//是否更新粒子数据
@property (nonatomic, assign) BOOL  particleDataWasUpdated;

//加载
-(BOOL)loadShaders;
//编译
-(BOOL)compileShader:(GLuint*)shader
                type:(GLenum)type
                file:(NSString*)file;
//链接
-(BOOL)linkProgram:(GLuint)prog;
//验证
-(BOOL)validateProgram:(GLuint)prog;
@end

@implementation MGPointParticleEffect

-(instancetype)init{
    self =[super init];
    if (self) {
        _texture2d0 =[[GLKEffectPropertyTexture alloc]init];
        _texture2d0.enabled =YES;
        _texture2d0.name =0;
        _texture2d0.target =GLKTextureTarget2D;
        _texture2d0.envMode =GLKTextureEnvModeReplace;
        
        _texture2d1 =[[GLKEffectPropertyTexture alloc]init];
        _texture2d1.enabled =YES;
        _texture2d1.name =0;
        _texture2d1.target =GLKTextureTarget2D;
        _texture2d1.envMode =GLKTextureEnvModeReplace;
        
        _transform =[[GLKEffectPropertyTransform alloc]init];
        _gravity =MGDefaultGravity;
        _elapsedSeconds =0.0f;
        _particleAttributesData =[NSMutableData data];
    }
    return self;
}

//获取粒子属性值
-(MGParticleAttributes)particleAtIndex:(NSUInteger)anIndex{
    const MGParticleAttributes *particlesPtr =(const MGParticleAttributes *)[self.particleAttributesData bytes];
    return particlesPtr[anIndex];
}

//设置粒子属性值
-(void)setParticle:(MGParticleAttributes)aParticle atIndex:(NSUInteger )anIndex{
    MGParticleAttributes *particlePtr =(MGParticleAttributes *)[self.particleAttributesData mutableBytes];
    particlePtr[anIndex] =aParticle;
    self.particleDataWasUpdated =YES;
}

//添加一个粒子
-(void)addParticleAtPosition:(GLKVector3)aPosition velocity:(GLKVector3)aVelocity force:(GLKVector3)aForce size:(float)aSize lifeSpanSecond:(NSTimeInterval)aSpan fadeDurationSecond:(NSTimeInterval)aDuration{
    MGParticleAttributes newParticle;
    newParticle.emissionPosition =aPosition;
    newParticle.emissionVelocity =aVelocity;
    newParticle.emissionForce =aForce;
    newParticle.size =GLKVector2Make(aSize, aDuration);
    newParticle.emissionTimeAndLife =GLKVector2Make(_elapsedSeconds, _elapsedSeconds +aSpan);
    
    BOOL foundSlot =NO;
    const long count =self.numberOfParticles;
    for (int i=0; i<count && !foundSlot; i++) {
        MGParticleAttributes oldParticle =[self particleAtIndex:i];
        //NSLog(@"%f---%f----%ld",oldParticle.emissionTimeAndLife.y,self.elapsedSeconds,count);
        if (oldParticle.emissionTimeAndLife.y <self.elapsedSeconds) {
            //NSLog(@"=======更新第几个%d",i);
            [self setParticle:newParticle atIndex:i];
            foundSlot =YES;
        }
    }
    
    if (!foundSlot) {
        [self.particleAttributesData appendBytes:&newParticle length:sizeof(newParticle)];
        self.particleDataWasUpdated =YES;
    }
}

//获取粒子个数
-(NSUInteger)numberOfParticles{
    static long last;
    long ret =[self.particleAttributesData length]/sizeof(MGParticleAttributes);
    if (last != ret) {
        last =ret;
    }
    return ret;
}

-(void)prepareToDraw{
    if (program ==0) {
        [self loadShaders];
    }
    if (program !=0) {
        glUseProgram(program);
        GLKMatrix4 modeViewProjectionMatrix =GLKMatrix4Multiply(self.transform.projectionMatrix, self.transform.modelviewMatrix);
        //通过Uniform把值传递到小程序
        glUniformMatrix4fv(uniforms[MGMVPMatrix], 1, 0, modeViewProjectionMatrix.m);
        glUniform1i(uniforms[MGSamplers2D], 0);
        glUniform1i(uniforms[MGSamplers2D], 1);
        glUniform3fv(uniforms[MGGravity], 1, self.gravity.v);
        glUniform1fv(uniforms[MGElasedSeconds], 1, &_elapsedSeconds);
        
        if (self.particleDataWasUpdated) {
            if (self.particleAttributeBuffer == nil &&[self.particleAttributesData length] >0) {
                GLsizeiptr size =sizeof(MGParticleAttributes);
                int count =(int)[self.particleAttributesData length]/sizeof(MGParticleAttributes);
                self.particleAttributeBuffer =[[MGVertexAttribArrayBuffer alloc]
                                               initWithAttribuStride:size
                                               numberOfVertices:count
                                               bytes:[self.particleAttributesData bytes]
                                               usage:GL_DYNAMIC_DRAW];
            }else{
                GLsizeiptr size =sizeof(MGParticleAttributes);
                int count =(int) [self.particleAttributesData length]/size;
                [self.particleAttributeBuffer reinitWithAttribStride:size numberOfVertices:count bytes:[self.particleAttributesData bytes]];
            }
            self.particleDataWasUpdated =NO;
        }
        
        [self.particleAttributeBuffer
         preparToDrawWithAttrib:MGParticleEmissionPosition
         numberOfCoodinates:3
         attribOffset:offsetof(MGParticleAttributes, emissionPosition)
         shouldEnable:YES];
        
        [self.particleAttributeBuffer
         preparToDrawWithAttrib:MGParticleEmissionVelocity
         numberOfCoodinates:3
         attribOffset:offsetof(MGParticleAttributes, emissionVelocity)
         shouldEnable:YES];

        [self.particleAttributeBuffer
         preparToDrawWithAttrib:MGParticleEmissionForce
         numberOfCoodinates:3
         attribOffset:offsetof(MGParticleAttributes, emissionForce)
         shouldEnable:YES];

        [self.particleAttributeBuffer
         preparToDrawWithAttrib:MGParticleSize
         numberOfCoodinates:2
         attribOffset:offsetof(MGParticleAttributes, size)
         shouldEnable:YES];

        [self.particleAttributeBuffer
         preparToDrawWithAttrib:MGParticleEmissionTimeAndLife
         numberOfCoodinates:2
         attribOffset:offsetof(MGParticleAttributes, emissionTimeAndLife)
         shouldEnable:YES];

        glActiveTexture(GL_TEXTURE0);
        if (self.texture2d0.name !=0 &&self.texture2d0.enabled) {
            glBindTexture(GL_TEXTURE_2D, self.texture2d0.name);
        }else{
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        glActiveTexture(GL_TEXTURE1);
        if (self.texture2d1.name !=0 &&self.texture2d1.enabled) {
            glBindTexture(GL_TEXTURE_2D, self.texture2d1.name);
        }else{
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }
}

-(void)draw{
    glDepthMask(GL_FALSE);
    [self.particleAttributeBuffer drawArrayWithMode:GL_POINTS startVertexIndex:0 numberOfVertices:(int)self.numberOfParticles];
    glDepthMask(GL_TRUE);
}

#pragma mark -OpenGL ES shader compliation
-(BOOL)loadShaders{
    GLuint vertShader, fragShader;
    NSString *verShaderPathName, *fragShaderPathName;
    program =glCreateProgram();
    verShaderPathName =[[NSBundle mainBundle] pathForResource:@"MGPointParticleShder" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:verShaderPathName]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    fragShaderPathName =[[NSBundle mainBundle] pathForResource:@"MGPointParticleShder" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathName]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    glBindAttribLocation(program, MGParticleEmissionPosition, "a_emissionPosition");
    glBindAttribLocation(program, MGParticleEmissionVelocity, "a_emissionVelocity");
    glBindAttribLocation(program, MGParticleEmissionForce, "a_emissionForce");
    glBindAttribLocation(program, MGParticleSize, "a_size");
    glBindAttribLocation(program, MGParticleEmissionTimeAndLife, "a_emissionAndDeathTimes");
    
    if (![self linkProgram:program]) {
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader =0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader =0;
        }
        if (program) {
            glDeleteProgram(program);
            program =0;
        }
        return NO;
    }
    
    //获取uniform变量的位置
    //MVP变换矩阵
    uniforms[MGMVPMatrix] =glGetUniformLocation(program, "u_mvpMatrix");
    //纹理
    uniforms[MGSamplers2D] =glGetUniformLocation(program, "u_samplers2D[0]");
    uniforms[MGSamplers2D] =glGetUniformLocation(program, "u_samplers2D[1]");
    //glBindAttribLocation(program, uniforms[MGSamplers2D], "u_samplers2D");
    //重力
    uniforms[MGGravity] =glGetUniformLocation(program, "u_gravity");
    //持续时间，渐隐时间
    uniforms[MGElasedSeconds] =glGetUniformLocation(program, "u_elapsedSeconds");
    
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
    return YES;
}

//编译shader
-(BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    //GLint status;
    const GLchar*source;
    source =(GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load shader");
        return NO;
    }
    *shader =glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength>0) {
        GLchar *log =(GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"shader compile log:\n%s",log);
        free(log);
        return NO;
    }
    return YES;
}

//链接shader
-(BOOL)linkProgram:(GLuint)prog{
    //GLint status;
    glLinkProgram(prog);
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0){
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
        return NO;
    }
    return YES;
}

//验证program
-(BOOL)validateProgram:(GLuint)prog{
    GLint logLength, status;
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength>0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0){
        return NO;
    }
    return YES;
}

const GLKVector3 MGDefaultGravity ={0.0f, -9.8f, 0.0f};

@end
