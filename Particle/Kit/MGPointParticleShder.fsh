uniform highp mat4      u_mvpMatrix;
uniform sampler2D       u_samplers2D[2];
uniform highp vec3       u_gravity;
uniform highp float       u_elapsedSeconds;

varying lowp float      v_particleOpacity;
varying lowp vec2      textureCoordinate;

void main(){
    lowp vec4 textureColor =texture2D(u_samplers2D[0], gl_PointCoord);
    lowp vec4 textureColor1 =texture2D(u_samplers2D[1], textureCoordinate);
   // textureColor =textureColor *textureColor1;
    textureColor.a =textureColor.a * v_particleOpacity;
    gl_FragColor =textureColor1;
    
}
