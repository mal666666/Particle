//
//  MGVertexAttribArrayBuffer.m
//  Particle
//
//  Created by Mac on 2019/8/13.
//  Copyright © 2019 马 爱林. All rights reserved.
//

#import "MGVertexAttribArrayBuffer.h"

@implementation MGVertexAttribArrayBuffer
-(id)initWithAttribuStride:(GLsizeiptr)stride numberOfVertices:(GLsizei)count bytes:(const GLvoid *)dataPtr usage:(GLenum)usage{
    self =[super init];
    if (self) {
        _stride =stride;
        _bufferSizeBytes =_stride *count;
        glGenBuffers(1, &_name);
        glBindBuffer(GL_ARRAY_BUFFER, self.name);
        glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, dataPtr, usage);
    }
    return self;
}

-(void)reinitWithAttribStride:(GLsizeiptr)stride numberOfVertices:(GLsizei)count bytes:(const GLvoid *)dataPtr{
    _stride =stride;
    _bufferSizeBytes =_stride *count;
    glBindBuffer(GL_ARRAY_BUFFER, self.name);
    glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, dataPtr, GL_DYNAMIC_DRAW);
}

-(void)preparToDrawWithAttrib:(GLuint)index numberOfCoodinates:(GLint)count attribOffset:(GLsizeiptr)offset shouldEnable:(BOOL)shouldEnable{
    if (count <0 ||count>4) {
        NSLog(@"count error");
        return;
    }
    if (_stride <offset) {
        NSLog(@"error _stride <Offset");
        return;
    }
    if (_name ==0) {
        NSLog(@"Error: name ==NUll");
        return;
    }
    glBindBuffer(GL_ARRAY_BUFFER, self.name);

    if (shouldEnable) {
        glEnableVertexAttribArray(index);
    }
    glVertexAttribPointer(index, count, GL_FLOAT, GL_FALSE, (int)self.stride, NULL+offset);
}

+(void)drawPreparedArrayWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count{
    glDrawArrays(mode, first, count);
}

-(void)drawArrayWithMode:(GLenum)mode startVertexIndex:(GLint)first numberOfVertices:(GLsizei)count{
    if (self.bufferSizeBytes <(first +count) *self.stride) {
        NSLog(@"vertex Error");
    }
    glDrawArrays(mode, first, count);
}
-(void)dealloc{
    if (_name !=0) {
        glDeleteBuffers(1, &_name);
        _name =0;
    }
}
@end
