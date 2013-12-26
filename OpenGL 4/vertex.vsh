#version 330

layout(location = 0) in vec3 vertexPosition;
layout(location = 1) in vec3 vertexNormal;
layout(location = 2) in vec2 vertexTexcoords;

uniform mat4 modelMatrix, viewMatrix, projectionMatrix;


out vec3 positionEye, normalEye;
out vec2 texcoords;

void main()
{
    positionEye = vec3(viewMatrix * modelMatrix * vec4(vertexPosition, 1));
    normalEye = vec3(viewMatrix * modelMatrix * vec4(vertexNormal, 0));
    
    texcoords = vertexTexcoords;
    
    gl_Position = projectionMatrix * vec4(positionEye, 1);
}
