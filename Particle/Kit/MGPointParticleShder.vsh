attribute vec3 a_emissionPosition;//位置
attribute vec3 a_emissionVelocity;//速度
attribute vec3 a_emissionForce;//重力
attribute vec2 a_size;//大小和消逝透明度变化时间
attribute vec2 a_emissionAndDeathTimes;//添加时间和寿命
attribute vec2 inputTextureCoordinate;

uniform highp mat4 u_mvpMatrix;//MVP
uniform sampler2D u_samplers2D[2];//纹理
uniform highp vec3 u_gravity;//重力
uniform highp float u_elapsedSeconds;//现在时间

varying lowp float v_particleOpacity;
varying lowp vec2 textureCoordinate;

void main(){
    //消逝的时间
    highp float elapsedTime = u_elapsedSeconds - a_emissionAndDeathTimes.x;
    //点的速速
    highp vec3 velocity = a_emissionVelocity + ((a_emissionForce +u_gravity)*elapsedTime);
    //位置计算
    highp vec3 untransformedPosition = a_emissionPosition + 0.5 *(a_emissionVelocity +velocity)* elapsedTime;
    gl_Position =u_mvpMatrix *vec4(untransformedPosition, 1.0);
    gl_PointSize =a_size.x /gl_Position.w;
    //透明度变化算法
    v_particleOpacity =max(0.0, min(1.0, (a_emissionAndDeathTimes.y - u_elapsedSeconds) /max(a_size.y, 0.00001)));
    textureCoordinate = inputTextureCoordinate;
}
