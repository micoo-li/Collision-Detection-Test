//
//  main.m
//  OpenGL 4
//
//  Created by Michael on 29/11/13.
//  Copyright (c) 2013 michael. All rights reserved.
//

//OpenGL Stuff
#import <GL/glew.h>
#import <GLFW/glfw3.h>
#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>
#import <glm/gtc/type_ptr.hpp>
#import <glm/gtc/quaternion.hpp>
#import <glm/gtx/quaternion.hpp>

//Apple Stuff
#import <Cocoa/Cocoa.h>

//C/C++ Stuff
#include <iostream>
#include <string>
#include <sstream>
#include <cmath>
#include <time.h>
#include <vector>

//My Custom Files
#include "tiny_obj_loader.h"
#include "GLUtil.h"
#import "GLImage.h" //Image Loading

//Namespace
using namespace std;

//Preprocessor Functions

#define PI 3.141592653589793238462643383279502884197169399

#define radians(n) n*PI/180
#define degrees(n) n*180/pi


float points[] = {
    -1, 1, 0,
    1, -1, 0,
    -1, -1, 0,
    1, 1, 0,
};

float normals[] = {
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0,
    0.0, 0.0, 1.0
};

GLint elements[] = {
    0, 1, 2,
    0, 3, 1
};

float texcoords[] = {
    0.0f, 1.0f,
    0.0f, 0.0f,
    1.0, 0.0,
    
    1.0, 0.0,
    1.0, 1.0,
    0.0, 1.0
};

//All the shapes in the file
vector<tinyobj::shape_t> shapes;


//Important variables
GLint numberOfObjects = 1;

GLFWwindow *window;
unsigned int verticesVBO;
unsigned int normalsVBO;
unsigned int texturesVBO;
unsigned int elementsVBO;
unsigned int colorVBO;
unsigned int vao;
unsigned int shaderProgram;

unsigned int tex = 0;

//Uniform Variables
unsigned int modelMatrixUniform;
unsigned int viewMatrixUniform;
unsigned int projectionMatrixUniform;


glm::mat4 translateMatrix;
glm::mat4 rotateMatrix;

glm::mat4 projectionMatrix;



// keep track of window size for things like the viewport and the mouse cursor
int g_gl_width = 640;
int g_gl_height = 480;

//Camera Variables
float camSpeed = 1; //Camera Speed
float camYawSpeed = 190; //Degrees per second

float camPosition[] = {0, 0, 2}; //Self-explanatory
float camYaw = 0; //O Degrees

#define GL_LOG_FILE "/Users/michael/Desktop/gl.log"

#define SHOULD_FULLSCREEN 0 //0 for window mode, 1 for fullscreen mode


#pragma mark Window Functions

void glfw_window_size_callback (GLFWwindow* window, int width, int height) {
    g_gl_width = width;
    g_gl_height = height;
    
    /* update any perspective matrices used here */
}

#pragma mark Error Functions 
//Dealing with errors and logs them to a file on the desktop called gl.log

bool restart_gl_log () {
    FILE* file = fopen (GL_LOG_FILE, "w+");
    if (!file) {
        fprintf (stderr, "ERROR: could not open %s log file for writing\n", GL_LOG_FILE);
        return false;
    }
    time_t now = time (NULL);
    char* date = ctime (&now);
    fprintf (file, "%s log. local time %s\n", GL_LOG_FILE, date);
    fclose (file);
    return true;
}

bool gl_log (const char* message, const char* filename, int line) {
    FILE* file = fopen (GL_LOG_FILE, "a+");
    if (!file) {
        fprintf (stderr, "ERROR: could not open %s for writing\n", GL_LOG_FILE);
        return false;
    }
    fprintf (file, "%s:%i %s\n", filename, line, message);
    fclose (file);
    return true;
}

void glfw_error_callback (int error, const char* description) {
    fputs (description, stderr);
    gl_log (description, __FILE__, __LINE__);
}

void log_gl_params () {
    GLenum params[] = {
        GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS,
        GL_MAX_CUBE_MAP_TEXTURE_SIZE,
        GL_MAX_DRAW_BUFFERS,
        GL_MAX_FRAGMENT_UNIFORM_COMPONENTS,
        GL_MAX_TEXTURE_IMAGE_UNITS,
        GL_MAX_TEXTURE_SIZE,
        GL_MAX_VARYING_FLOATS,
        GL_MAX_VERTEX_ATTRIBS,
        GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS,
        GL_MAX_VERTEX_UNIFORM_COMPONENTS,
        GL_MAX_VIEWPORT_DIMS,
        GL_STEREO,
    };
    const char* names[] = {
        "GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS",
        "GL_MAX_CUBE_MAP_TEXTURE_SIZE",
        "GL_MAX_DRAW_BUFFERS",
        "GL_MAX_FRAGMENT_UNIFORM_COMPONENTS",
        "GL_MAX_TEXTURE_IMAGE_UNITS",
        "GL_MAX_TEXTURE_SIZE",
        "GL_MAX_VARYING_FLOATS",
        "GL_MAX_VERTEX_ATTRIBS",
        "GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS",
        "GL_MAX_VERTEX_UNIFORM_COMPONENTS",
        "GL_MAX_VIEWPORT_DIMS",
        "GL_STEREO",
    };
    gl_log ("GL Context Params:", __FILE__, __LINE__);
    char msg[256];
    // integers - only works if the order is 0-10 integer return types
    for (int i = 0; i < 10; i++) {
        int v = 0;
        glGetIntegerv (params[i], &v);
        sprintf (msg, "%s %i", names[i], v);
        gl_log (msg, __FILE__, __LINE__);
    }
    // others
    int v[2];
    v[0] = v[1] = 0;
    glGetIntegerv (params[10], v);
    sprintf (msg, "%s %i %i", names[10], v[0], v[1]);
    gl_log (msg, __FILE__, __LINE__);
    unsigned char s = 0;
    glGetBooleanv (params[11], &s);
    sprintf (msg, "%s %i", names[11], (unsigned int)s);
    gl_log (msg, __FILE__, __LINE__);
    gl_log ("-----------------------------", __FILE__, __LINE__);
}


#pragma mark Calculate FPS
double calcFPS(double theTimeInterval = 1.0, std::string theWindowTitle = "NONE")
{
    //From http://r3dux.org/2012/07/a-simple-glfw-fps-counter/
	// Static values which only get initialised the first time the function runs
	static double t0Value       = glfwGetTime(); // Set the initial time to now
	static int    fpsFrameCount = 0;             // Set the initial FPS frame count to 0
	static double fps           = 0.0;           // Set the initial FPS value to 0.0
    
	// Get the current time in seconds since the program started (non-static, so executed every time)
	double currentTime = glfwGetTime();
    
	// Ensure the time interval between FPS checks is sane (low cap = 0.1s, high-cap = 10.0s)
	// Negative numbers are invalid, 10 fps checks per second at most, 1 every 10 secs at least.
	if (theTimeInterval < 0.1)
	{
		theTimeInterval = 0.1;
	}
	if (theTimeInterval > 10.0)
	{
		theTimeInterval = 10.0;
	}
    
	// Calculate and display the FPS every specified time interval
	if ((currentTime - t0Value) > theTimeInterval)
	{
		// Calculate the FPS as the number of frames divided by the interval in seconds
		fps = (double)fpsFrameCount / (currentTime - t0Value);
        
		// If the user specified a window title to append the FPS value to...
		if (theWindowTitle != "NONE")
		{
			// Convert the fps value into a string using an output stringstream
			std::ostringstream stream;
			stream << fps;
			std::string fpsString = stream.str();
            
			// Append the FPS value to the window title details
			theWindowTitle += " | FPS: " + fpsString;
            
			// Convert the new window title to a c_str and set it
			const char* pszConstString = theWindowTitle.c_str();
            glfwSetWindowTitle(window, pszConstString);
		}
		else // If the user didn't specify a window to append the FPS to then output the FPS to the console
		{
			std::cout << "FPS: " << fps << std::endl;
		}
        
		// Reset the FPS frame counter and set the initial time to be now
		fpsFrameCount = 0;
		t0Value = glfwGetTime();
	}
	else // FPS calculation time interval hasn't elapsed yet? Simply increment the FPS frame counter
	{
		fpsFrameCount++;
	}
    
	// Return the current FPS - doesn't have to be used if you don't want it!
	return fps;
}

#pragma mark Initialization Functions

void loadObj()
{
    //Load OBJ File, aka the sphere
    
    NSString *input = [[NSBundle mainBundle] pathForResource:@"Sphere_Simple" ofType:@"obj"];
    
    string err = tinyobj::LoadObj(shapes, [input UTF8String], [[input stringByDeletingLastPathComponent] UTF8String]);
    if (!err.empty())
    {
        cerr << err << endl;
        exit(1);
    }
    /*
     cout << "# of shapes : " << shapes.size() << std::endl;
     
     for (size_t i = 0; i < shapes.size(); i++) {
     printf("shape[%ld].name = %s\n", i, shapes[i].name.c_str());
     printf("shape[%ld].indices: %ld\n", i, shapes[i].mesh.indices.size());
     assert((shapes[i].mesh.indices.size() % 3) == 0);
     for (size_t f = 0; f < shapes[i].mesh.indices.size(); f++) {
     printf("  idx[%ld] = %d\n", f, shapes[i].mesh.indices[f]);
     }
     
     printf("shape[%ld].vertices: %ld\n", i, shapes[i].mesh.positions.size());
     assert((shapes[i].mesh.positions.size() % 3) == 0);
     for (size_t v = 0; v < shapes[i].mesh.positions.size() / 3; v++) {
     printf("  v[%ld] = (%f, %f, %f)\n", v,
     shapes[i].mesh.positions[3*v+0],
     shapes[i].mesh.positions[3*v+1],
     shapes[i].mesh.positions[3*v+2]);
     }
     
     printf("shape[%ld].material.name = %s\n", i, shapes[i].material.name.c_str());
     printf("  material.Ka = (%f, %f ,%f)\n", shapes[i].material.ambient[0], shapes[i].material.ambient[1], shapes[i].material.ambient[2]);
     printf("  material.Kd = (%f, %f ,%f)\n", shapes[i].material.diffuse[0], shapes[i].material.diffuse[1], shapes[i].material.diffuse[2]);
     printf("  material.Ks = (%f, %f ,%f)\n", shapes[i].material.specular[0], shapes[i].material.specular[1], shapes[i].material.specular[2]);
     printf("  material.Tr = (%f, %f ,%f)\n", shapes[i].material.transmittance[0], shapes[i].material.transmittance[1], shapes[i].material.transmittance[2]);
     printf("  material.Ke = (%f, %f ,%f)\n", shapes[i].material.emission[0], shapes[i].material.emission[1], shapes[i].material.emission[2]);
     printf("  material.Ns = %f\n", shapes[i].material.shininess);
     printf("  material.map_Ka = %s\n", shapes[i].material.ambient_texname.c_str());
     printf("  material.map_Kd = %s\n", shapes[i].material.diffuse_texname.c_str());
     printf("  material.map_Ks = %s\n", shapes[i].material.specular_texname.c_str());
     printf("  material.map_Ns = %s\n", shapes[i].material.normal_texname.c_str());
     std::map<std::string, std::string>::iterator it(shapes[i].material.unknown_parameter.begin());
     std::map<std::string, std::string>::iterator itEnd(shapes[i].material.unknown_parameter.end());
     for (; it != itEnd; it++) {
     printf("  material.%s = %s\n", it->first.c_str(), it->second.c_str());
     }
     printf("\n");
     }
     */
}

void initializeWindow()
{
    if (!glfwInit ()) {
        fprintf (stderr, "ERROR: could not start GLFW3\n");
    }
    
    //To get Core Profile
    glfwWindowHint( GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint( GLFW_CONTEXT_VERSION_MINOR, 2); //Core Profile, says OpenGL 3.2 but it's actually 4.1 lol apple
    glfwWindowHint (GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    glfwWindowHint( GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE );
    
    //Anti-aliasing
    glfwWindowHint (GLFW_SAMPLES, 4);
    
    //Window Creation must be after window hint or else you wouldn't get the hints, aka run OpenGL Legacy
    
    //Fullscreen/Window Mode Initialization
#if SHOULD_FULLSCREEN
    GLFWmonitor* mon = glfwGetPrimaryMonitor ();
    const GLFWvidmode* vmode = glfwGetVideoMode (mon);
    window = glfwCreateWindow (vmode->width, vmode->height, "Extended GL Init", mon, NULL);
#else
    window = glfwCreateWindow (640, 480, "OpenGL", NULL, NULL);
#endif
    
    glViewport (0, 0, g_gl_width, g_gl_height);
    
    //Set Current OpenGL Context
    glfwMakeContextCurrent (window);
    
    //Sets Callback for certain functions
    glfwSetWindowSizeCallback (window, glfw_window_size_callback);
    
    
    glfwWindowHint(GLFW_REFRESH_RATE, 61);
    
    glewExperimental = GL_TRUE;
    glewInit();
    
    const GLubyte* renderer = glGetString (GL_RENDERER); // get renderer string
    const GLubyte* version = glGetString (GL_VERSION); // version as a string
    printf ("Renderer: %s\n", renderer);
    printf ("OpenGL version supported %s\n", version);
}

void initializeOpenGL()
{
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    
    //glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CW);
}

void initializeBuffers()
{
 /*
    //Test Data
    NSLog (@"%lu, %lu", sizeof(points), sizeof(GLfloat));
    glGenBuffers(1, &verticesVBO);
    glBindBuffer(GL_ARRAY_BUFFER, verticesVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(points), points, GL_STATIC_DRAW);
    
    glGenBuffers(1, &normalsVBO);
    glBindBuffer(GL_ARRAY_BUFFER, normalsVBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(normals), normals, GL_STATIC_DRAW);
    
 //   glGenBuffers(1, &texturesVBO);
 //   glBindBuffer(GL_ARRAY_BUFFER, texturesVBO);
 //   glBufferData(GL_ARRAY_BUFFER, 2 * 6 * sizeof(float), texcoords, GL_STATIC_DRAW);
    
    glGenBuffers(1, &elementsVBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementsVBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(elements), elements, GL_STATIC_DRAW);
*/
    //Obj Data
   
    GetGLError();
    glGenBuffers(1, &verticesVBO);
    glBindBuffer(GL_ARRAY_BUFFER, verticesVBO);
    glBufferData(GL_ARRAY_BUFFER, shapes[0].mesh.positions.size() * sizeof(float), &shapes[0].mesh.positions[0],GL_STATIC_DRAW);
    
    glGenBuffers(1, &normalsVBO);
    glBindBuffer(GL_ARRAY_BUFFER, normalsVBO);
    glBufferData(GL_ARRAY_BUFFER, shapes[0].mesh.normals.size() * sizeof(float), &shapes[0].mesh.normals[0], GL_STATIC_DRAW);
    
    
    GetGLError();
    glGenBuffers(1, &elementsVBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementsVBO);
    GetGLError();
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, shapes[0].mesh.indices.size() * sizeof(unsigned int), &shapes[0].mesh.indices[0], GL_STATIC_DRAW);
    GetGLError();

}

void initializeArrays()
{
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, verticesVBO);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glBindBuffer(GL_ARRAY_BUFFER, normalsVBO);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, NULL);
//    glBindBuffer(GL_ARRAY_BUFFER, texturesVBO);
  //  glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    
    
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
//    glEnableVertexAttribArray(2);
}

void initializeTextures()
{
    glGenTextures(1, &tex);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, tex);
    
    GLImage *image = [GLImage imageWithImageName:@"texture" shouldFlip:NO];

    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, image.width, image.height, 0, GL_RGBA8, GL_UNSIGNED_INT_8_8_8_8, image.data);
    
    glPixelStorei(GL_UNPACK_ROW_LENGTH, image.width);
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
}

#define VSH_FILENAME [[NSBundle mainBundle] pathForResource:@"vertex" ofType:@"vsh"]
#define FSH_FILENAME [[NSBundle mainBundle] pathForResource:@"fragment" ofType:@"fsh"]

void compileShaders()
{
    const char *vshSource = [[NSString stringWithContentsOfFile:VSH_FILENAME encoding:NSUTF8StringEncoding error:nil] UTF8String];

    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vshSource, NULL);
    glCompileShader(vertexShader);
    
    
    const char *fshSource = [[NSString stringWithContentsOfFile:FSH_FILENAME encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fshSource, NULL);
    glCompileShader(fragmentShader);
    
    
    shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    
    //Bind Attributes
    glBindAttribLocation(shaderProgram, 0, "vertexPosition");
    glBindAttribLocation(shaderProgram, 1, "vertexNormal");
    //glBindAttribLocation(shaderProgram, 2, "vertexTexcoords");
    
    glLinkProgram(shaderProgram);
}

void createUniforms()
{
    modelMatrixUniform = glGetUniformLocation(shaderProgram, "modelMatrix");
    viewMatrixUniform = glGetUniformLocation(shaderProgram, "viewMatrix");
    projectionMatrixUniform = glGetUniformLocation(shaderProgram, "projectionMatrix");
    
    glUseProgram(shaderProgram);
    
    translateMatrix = glm::translate(glm::mat4(1.0), glm::vec3(-camPosition[0], -camPosition[1], -camPosition[2]));
    
    //Rotate with Matrices
    //rotateMatrix = glm::rotate(glm::mat4(1.0), -camYaw, glm::vec3(0, 1, 0));
    
    //Rotate with Quaternions
    glm::quat rotateQuaternion;
    rotateQuaternion = glm::angleAxis(-camYaw, glm::vec3(0, 1, 0));
    
    rotateMatrix = glm::toMat4(rotateQuaternion);
    
    
    projectionMatrix = glm::perspective(67.0f, (float)g_gl_width/(float)g_gl_height, 0.1f, 100.0f);
    
    glUniformMatrix4fv(modelMatrixUniform, 1, GL_FALSE, glm::value_ptr(translateMatrix));
    glUniformMatrix4fv(viewMatrixUniform, 1, GL_FALSE, glm::value_ptr(rotateMatrix));
    glUniformMatrix4fv(projectionMatrixUniform, 1, GL_FALSE, glm::value_ptr(projectionMatrix));
}

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        
        loadObj();
        
        initializeWindow();
        
        char message[256];
        sprintf (message, "starting GLFW %s", glfwGetVersionString());
       // assert (gl_log (message, __FILE__, __LINE__));
        glfwSetErrorCallback (glfw_error_callback);
        
        
        initializeOpenGL();
        initializeBuffers();
        initializeArrays();
        //initializeTextures();
        compileShaders();
        createUniforms();
        
        //Extra Stuff Calls whatever lol
        
        log_gl_params();
        
        
        while(!glfwWindowShouldClose(window))
        {
            static double previous_seconds = glfwGetTime ();
            double current_seconds = glfwGetTime ();
            double elapsed_seconds = current_seconds - previous_seconds;
            previous_seconds = current_seconds;
            
            //Show FPS on window title, may be inefficient
            calcFPS(1, "OpenGL");
            
            glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            
            // draw points 0-3 from the currently bound VAO with current in-use shader
            //glDrawArrays (GL_TRIANGLES, 0, 6);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementsVBO);
            glDrawElements(GL_TRIANGLES, (GLsizei)shapes[0].mesh.indices.size(), GL_UNSIGNED_INT, 0);
            // update other events like input handling
            glfwPollEvents ();
            
            glfwSwapBuffers(window);
            
            //Key Presses
            bool cam_moved = false;
            
            if (GLFW_PRESS == glfwGetKey (window, GLFW_KEY_ESCAPE)) {
                glfwSetWindowShouldClose (window, 1);
            }
            else if (glfwGetKey (window, GLFW_KEY_A)) {
                camPosition[0] -= camSpeed * elapsed_seconds;
                cam_moved = true;
            }
            if (glfwGetKey (window, GLFW_KEY_D)) {
                camPosition[0] += camSpeed * elapsed_seconds;
                cam_moved = true;
            }
            if (glfwGetKey (window, GLFW_KEY_PAGE_UP)) {
                camPosition[1] += camSpeed * elapsed_seconds;
                cam_moved = true;
            }
            if (glfwGetKey (window, GLFW_KEY_PAGE_DOWN)) {
                camPosition[1] -= camSpeed * elapsed_seconds;
                cam_moved = true;
            }
            if (glfwGetKey (window, GLFW_KEY_W)) {
                camPosition[2] -= camSpeed * elapsed_seconds;
                cam_moved = true;
            }
            if (glfwGetKey (window, GLFW_KEY_S)) {
                camPosition[2] += camSpeed * elapsed_seconds;
                cam_moved = true;
            }
            if (glfwGetKey (window, GLFW_KEY_LEFT)) {
                camYaw += camYawSpeed * elapsed_seconds;
                cam_moved = true;
            }
            if (glfwGetKey (window, GLFW_KEY_RIGHT)) {
                camYaw -= camYawSpeed * elapsed_seconds;
                cam_moved = true;
            }
            
            if (cam_moved)
            {
                translateMatrix = glm::translate(glm::mat4(1.0), glm::vec3(-camPosition[0], -camPosition[1], -camPosition[2]));
                
                
                glm::quat rotateQuaternion;
                rotateQuaternion = glm::angleAxis(-camYaw, glm::vec3(0, 1, 0));
                rotateMatrix = glm::toMat4(rotateQuaternion);
                
                glUniformMatrix4fv(modelMatrixUniform, 1, GL_FALSE, glm::value_ptr(translateMatrix));
                glUniformMatrix4fv(viewMatrixUniform, 1, GL_FALSE, glm::value_ptr(rotateMatrix));
                
            }
            
        }
        
        glfwTerminate();
    }
    return 0;
}

