//
//  MGVertexAttribArrayBuffer.h
//  Particle
//
//  Created by Mac on 2019/8/13.
//  Copyright © 2019 马 爱林. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum {
    MGVertextAttribPosition  =GLKVertexAttribPosition,
    MGVertextAttribNormal   =GLKVertexAttribNormal,
    MGVertextAttribColor      =GLKVertexAttribColor,
    MGVertextAttribTexture0 =GLKVertexAttribTexCoord0,
    MGVertextAttribTexture1 =GLKVertexAttribTexCoord1
}MGVertextAttrib;

@interface MGVertexAttribArrayBuffer : NSObject

@property (nonatomic, readonly) GLuint name;//步长
@property (nonatomic, readonly) GLsizeiptr  bufferSizeBytes;//缓冲区大小字节数
@property (nonatomic, readonly) GLsizeiptr  stride;//缓存区名字

+(void)drawPreparedArrayWithMode:(GLenum)mode
                startVertexIndex:(GLint )first
                numberOfVertices:(GLsizei)count;

-(id)initWithAttribuStride:(GLsizeiptr)stride
            numberOfVertices:(GLsizei )count
                       bytes:(const GLvoid*)dataPtr
                       usage:(GLenum)usage;

-(void)preparToDrawWithAttrib:(GLuint)index
           numberOfCoodinates:(GLint)count
                 attribOffset:(GLsizeiptr )offset
                 shouldEnable:(BOOL)shouldEnable;

-(void)drawArrayWithMode:(GLenum)mode
        startVertexIndex:(GLint)first
        numberOfVertices:(GLsizei)count;

-(void)reinitWithAttribStride:(GLsizeiptr)stride
             numberOfVertices:(GLsizei)count
                        bytes:(const GLvoid*)dataPtr;
@end

NS_ASSUME_NONNULL_END
