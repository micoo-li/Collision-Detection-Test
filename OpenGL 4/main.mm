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
#import <dispatch/dispatch.h>

//C/C++ Stuff
#include <iostream>
#include <string>
#include <sstream>
#include <cmath>
#include <time.h>
#include <vector>

//Boost cuz i'm lazy as fuck
#include <boost/tokenizer.hpp>
#include <boost/foreach.hpp>

//Third Party Collision Detection Code
#include <Octree/octree.h>

//My Custom Files
#include "tiny_obj_loader.h"
#include "GLUtil.h"
#include "Sorting.c"

//Namespace
using namespace std;
using namespace boost;

//Preprocessor Functions
#define PI 3.141592653589793238462643383279502884197169399

#define radians(n) n*PI/180
#define degrees(n) n*180/pi

//Preprocessor Preferences

#define SHOULD_FULLSCREEN 0 //0 for window mode, 1 for fullscreen mode
#define BATCH_DRAWING 1 //0 for no batch (multiple VBO), 1 for batch drawing (1 VBO)
//None batch probably doesn't work anymore

#define COLLISION_DETECTION_METHOD 2 //-1 for nothing, 0 for nested loop, 1 for grid, 2 for 1 axis sweep and prune, 3 for 3 axis sweep and prune

#define COLLISION_CHECK_INTERVAL_CHANGE 000 //In microseconds (or .000001 seconds)
#define FPS 0.016666666 //Frames per second, less calculation
unsigned int COLLISION_CHECK_INTERVAL = 5000;


//Note: Non batched will not support moving vertices, only implemented for batched

#define PRINT_ARRAY(a, s) for(int i=0;i<s;i++){printf("%i: %.1f\n", i, (float)a[i]);}

//All the shapes in the file
vector<tinyobj::shape_t> shapes;

GLfloat *posVert;
GLfloat *normalVert;

//vector<glm::vec3> posVert;
//vector<glm::vec3> normalVert;

unsigned int *indices;

float diameter = 2; //Diameter of sphere
int containerSize = 1024; //Size of the box that contains the spheres
//Has to be powers of 2 in order for octree to work
int maxVelocity = 10;

//GCD (Dispatch) Variables
dispatch_queue_t collisionQueue;
dispatch_queue_t drawQueue;

//Important variables
GLint numberOfObjects = 10000;

GLFWwindow *window;
unsigned int *verticesVBO;
unsigned int *normalsVBO;
unsigned int texturesVBO;
unsigned int *elementsVBO;
unsigned int colorVBO;
unsigned int *vao;
unsigned int shaderProgram;

float radius = 1.0000001;

vector<glm::vec3> positions;
vector<glm::vec3> velocity;

int *collisions;

int gridSize = 16; //Divides the container size by this, change according to container size
vector<int> grid;

static glm::vec3 gravity = glm::vec3(0, -9.81, 0); //Acceleration of velocity of each ball.


//Spatial algo, grid/cell based
#if COLLISION_DETECTION_METHOD == 1

Octree<unsigned int> tree(containerSize);

#endif

//1 Axis Sweep and Prune
#if COLLISION_DETECTION_METHOD == 2

float *xAxisSorted;
int *xAxisElement;

#endif

//3 Axis Sweep and Prune
#if COLLISION_DETECTION_METHOD == 3

float *xAxisSorted;
int *xAxisElement;

float *yAxisSorted;
int *yAxisElement;

float *zAxisSorted;
int *zAxisElement;

#endif

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
float camSpeed = 30; //Camera Speed
float camYawSpeed = 190; //Degrees per second

float camPosition[] = {static_cast<float>(containerSize/2), static_cast<float>(containerSize/2), static_cast<float>(containerSize*1.5)}; //Self-explanatory
float camYaw = 0; //O Degrees

#define GL_LOG_FILE "/Users/michael/Desktop/gl.log"

#pragma mark Window Functions

void glfw_window_size_callback (GLFWwindow* window, int width, int height) {
    g_gl_width = width;
    g_gl_height = height;
    /* update any perspective matrices used here */
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
    
    cout << "# of shapes : " << shapes.size() << std::endl;
  
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
    glfw_window_size_callback(window, vmode->width, vmode->height);
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
    
    
    //Positions of the objects, will change later
  /*
    positions.push_back(glm::vec3(-2, 0, -2));
    positions.push_back(glm::vec3(2, 0, -2));
    positions.push_back(glm::vec3(-8, 0, 0));
    positions.push_back(glm::vec3(-8, 4, 0));
    positions.push_back(glm::vec3(-8, 8, 0));
    positions.push_back(glm::vec3(-4, -8, 0));
    positions.push_back(glm::vec3(-4, -4, 0));
    positions.push_back(glm::vec3(-4, 0, 0));
    positions.push_back(glm::vec3(-4, 4, 0));
    positions.push_back(glm::vec3(-4, 8, 0));
    positions.push_back(glm::vec3(0, -8, 0));
    positions.push_back(glm::vec3(0, -4, 0));
    positions.push_back(glm::vec3(0, 0, 0));
    positions.push_back(glm::vec3(0, 4, 0));
    positions.push_back(glm::vec3(0, 8, 0));
    positions.push_back(glm::vec3(4, -8, 0));
    positions.push_back(glm::vec3(4, -4, 0));
    positions.push_back(glm::vec3(4, 0, 0));
    positions.push_back(glm::vec3(4, 4, 0));
    positions.push_back(glm::vec3(4, 8, 0));
    positions.push_back(glm::vec3(8, -8, 0));
    positions.push_back(glm::vec3(8, -4, 0));
    positions.push_back(glm::vec3(8, 0, 0));
    positions.push_back(glm::vec3(8, 4, 0));
    positions.push_back(glm::vec3(8, 8, 0));
     */
    
 /*
     positions.push_back(glm::vec3(4.414213562, 3, 0));
     positions.push_back(glm::vec3(3, 10, 0));
     
     velocity.push_back(glm::vec3(0, 0, 0));
     velocity.push_back(glm::vec3(0, 0, 0));
  */
  
    
    for (int i=0;i<numberOfObjects;i++)
    {
        glm::vec3 pos(arc4random()%containerSize, (unsigned int)arc4random()%(containerSize-1)+1, arc4random()%containerSize);
        
                positions.push_back(pos);
        
        
        //positions.push_back(glm::vec3(((signed int)arc4random())%containerSize-containerSize/2, 10, ((signed int)arc4random())%containerSize-containerSize/2));
        
        
        //velocity.push_back(glm::vec3(0, 0, 0)); //Change this to perhaps a random velocity later, or read velocity from input to have consistent results
        
        velocity.push_back(glm::vec3(arc4random()%maxVelocity, 0, arc4random()%maxVelocity));
        
    }
   
    collisions = (int*)malloc(numberOfObjects*sizeof(int));
    
    for (int i=0;i<numberOfObjects;i++)
        collisions[i] = -1;

    
    
#if COLLISION_DETECTION_METHOD == 1
    
    tree.setEmptyValue(UINT_MAX);
    
    for (int i=0;i<numberOfObjects;i++)
    {
        glm::vec3 pos = velocity[i];
        
        if (tree.at(pos.x, pos.y, pos.z) != UINT_MAX)
        {
            i--;
            continue;
        }
        
        tree.set(pos.x, pos.y, pos.z, i);
        
    }
    
   
    
     int zSize = containerSize;
     int ySize = containerSize;
     int xSize = containerSize;
    
    int total = 0;
     
     for ( int z = 0; z < zSize; ++z ) {
         for ( int y = 0; y < ySize; ++y ) {
                for ( int x = 0; x < xSize; ++x ) {
                    if (tree.at(x, y, z) != -1) total++;
                    printf("X: %i Y: %i Z: %i - %i\n", x, y, z, tree.at(x,y,z));
                }
         }
     }
    
    printf("Total: %i\n ", total);
    
    
#endif
    
#if COLLISION_DETECTION_METHOD == 2
    
    xAxisSorted = (float *)malloc(sizeof(float) * numberOfObjects);
    xAxisElement = (int *)malloc(sizeof(int) * numberOfObjects);
    
    for (int i=0;i<numberOfObjects;i++)
    {
        xAxisSorted[i] = positions[i].x;
        xAxisElement[i] = i;
    }
    
    insertionSort(xAxisSorted, xAxisElement, numberOfObjects);
    
    printArray(xAxisSorted, numberOfObjects);
    printA(xAxisElement, numberOfObjects);
    
#endif
    
#if COLLISION_DETECTION_METHOD == 3
    
    xAxisSorted = (float *)malloc(sizeof(float) * numberOfObjects);
    xAxisElement = (int *)malloc(sizeof(int) * numberOfObjects);
    
    for (int i=0;i<numberOfObjects;i++)
    {
        xAxisSorted[i] = positions[i].x;
        xAxisElement[i] = i;
    }
    
    insertionSort(xAxisSorted, xAxisElement, numberOfObjects);
    
    yAxisSorted = (float *)malloc(sizeof(float) * numberOfObjects);
    yAxisElement = (int *)malloc(sizeof(int) * numberOfObjects);
    
    for (int i=0;i<numberOfObjects;i++)
    {
        yAxisSorted[i] = positions[i].y;
        yAxisElement[i] = i;
    }
    
    insertionSort(yAxisSorted, yAxisElement, numberOfObjects);
    
    zAxisSorted = (float *)malloc(sizeof(float) * numberOfObjects);
    zAxisElement = (int *)malloc(sizeof(int) * numberOfObjects);
    
    for (int i=0;i<numberOfObjects;i++)
    {
        zAxisSorted[i] = positions[i].z;
        zAxisElement[i] = i;
    }
    
    insertionSort(xAxisSorted, xAxisElement, numberOfObjects);
    
#endif
    
    
    
#if !BATCH_DRAWING
    printf("Not Batch");
    verticesVBO = (unsigned int *)malloc(numberOfObjects * sizeof(unsigned int));
    normalsVBO = (unsigned int *)malloc(numberOfObjects * sizeof(unsigned int));
    elementsVBO = (unsigned int *)malloc(numberOfObjects * sizeof(unsigned int));
    vao = (unsigned int *)malloc(numberOfObjects * sizeof(unsigned int));
#else
    verticesVBO = (unsigned int *)malloc(sizeof(unsigned int));
    normalsVBO = (unsigned int *)malloc(sizeof(unsigned int));
    elementsVBO = (unsigned int *)malloc(sizeof(unsigned int));
    vao = (unsigned int *)malloc(sizeof(unsigned int));
#endif
    
 
    
}

void initializeOpenGL()
{
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);
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
#if !BATCH_DRAWING
    printf("Not Batch");
    for (int i=0;i<numberOfObjects; i++)
    {
        translateMatrix = glm::translate(glm::mat4(1.0), positions[i]);
        
        GLfloat *tempPos = (GLfloat *)malloc(shapes[0].mesh.positions.size() * sizeof(GLfloat));
        //GLfloat *tempNorm = (GLfloat *)malloc(shapes[0].mesh.normals.size() * sizeof(GLfloat));
        
        for (int j = 0;j<shapes[0].mesh.positions.size()/3;j++)
        {
            tempPos[j*3] = shapes[0].mesh.positions[j*3] + positions[i].x;
            tempPos[j*3+1] = shapes[0].mesh.positions[j*3+1] + positions[i].y;
            tempPos[j*3+2] = shapes[0].mesh.positions[j*3+2] + positions[i].z;
        }
        /*
        for (int j=0;j<shapes[0].mesh.normals.size()/3;j++)
        {
            tempNorm[j*3] = shapes[0].mesh.normals[j*3] + positions[i].x;
            tempNorm[j*3+1] = shapes[0].mesh.normals[j*3+1] + positions[i].y;
            tempNorm[j*3+2] = shapes[0].mesh.normals[j*3+2] + positions[i].z;
        }
     */
        
        GetGLError();
        glGenBuffers(1, &verticesVBO[i]);
        glBindBuffer(GL_ARRAY_BUFFER, verticesVBO[i]);
        glBufferData(GL_ARRAY_BUFFER, shapes[0].mesh.positions.size() * sizeof(float), tempPos,GL_STATIC_DRAW);
        
        glGenBuffers(1, &normalsVBO[i]);
        glBindBuffer(GL_ARRAY_BUFFER, normalsVBO[i]);
        glBufferData(GL_ARRAY_BUFFER, shapes[0].mesh.normals.size() * sizeof(float), &shapes[0].mesh.normals[0], GL_STATIC_DRAW);
        
        
        GetGLError();
        glGenBuffers(1, &elementsVBO[i]);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementsVBO[i]);
        GetGLError();
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, shapes[0].mesh.indices.size() * sizeof(unsigned int), &shapes[0].mesh.indices[0], GL_STATIC_DRAW);
        GetGLError();
        
        free(tempPos);
    }
# else
    //Single VBO
    
    posVert = (GLfloat *)malloc(shapes[0].mesh.positions.size() * sizeof(GLfloat) * numberOfObjects);
    normalVert = (GLfloat *)malloc(shapes[0].mesh.normals.size() * sizeof(GLfloat)* numberOfObjects);
    
    //posVert.reserve(shapes[0].mesh.positions.size()/3);
    //normalVert.reserve(shapes[0].mesh.normals.size()/3);
    
    
    indices = (unsigned int *)malloc(shapes[0].mesh.indices.size() * sizeof(unsigned int) * numberOfObjects);
    
    unsigned long posSize = shapes[0].mesh.positions.size();
    unsigned long normSize = shapes[0].mesh.normals.size();
    unsigned long indicesSize = shapes[0].mesh.indices.size();
    
    for (int i=0;i<numberOfObjects;i++)
    {
        for (int j=0;j<posSize/3;j++)
        {
            //posVert[j] = glm::vec3(shapes[0].mesh.positions[j*3] + positions[i].x, shapes[0].mesh.positions[j*3+1] + positions[i].y, shapes[0].mesh.positions[j*3+2] + positions[i].z);
            
            posVert[i*posSize + j*3] = shapes[0].mesh.positions[j*3] + positions[i].x;
            posVert[i*posSize + j*3 + 1] = shapes[0].mesh.positions[j*3+1] + positions[i].y;
            posVert[i*posSize + j*3 + 2] = shapes[0].mesh.positions[j*3+2] + positions[i].z;
        }
        for (int j=0;j<normSize/3;j++)
        {
            //normalVert[j] = glm::vec3(shapes[0].mesh.normals[j*3], shapes[0].mesh.normals[j*3+1], shapes[0].mesh.normals[j*3+2]);
            
            //Add translation later lol
            normalVert[i*posSize + j*3] = shapes[0].mesh.normals[j*3];
            normalVert[i*posSize + j*3 + 1] = shapes[0].mesh.normals[j*3+1];
            normalVert[i*posSize + j*3 + 2] = shapes[0].mesh.normals[j*3+2];
        }
        for (int j=0;j<indicesSize;j++)
        {
            indices[i*indicesSize + j] = shapes[0].mesh.indices[j]+(unsigned int)(i*posSize/3);
        }
    }
    
    glGenBuffers(1, &verticesVBO[0]);
    glBindBuffer(GL_ARRAY_BUFFER, verticesVBO[0]);
    glBufferData(GL_ARRAY_BUFFER, posSize * numberOfObjects * sizeof(GLfloat), posVert, GL_STATIC_DRAW);
    
    glGenBuffers(1, &normalsVBO[0]);
    glBindBuffer(GL_ARRAY_BUFFER, normalsVBO[0]);
    glBufferData(GL_ARRAY_BUFFER, normSize * numberOfObjects * sizeof(GLfloat), normalVert, GL_STATIC_DRAW);
    
    glGenBuffers(1, &elementsVBO[0]);
    glBindBuffer(GL_ARRAY_BUFFER, elementsVBO[0]);
    glBufferData(GL_ARRAY_BUFFER, indicesSize * numberOfObjects * sizeof(unsigned int), indices, GL_STATIC_DRAW);
    
#endif

}

void initializeArrays()
{
#if !BATCH_DRAWING
    
    for (int i=0;i<numberOfObjects;i++)
    {
        glGenVertexArrays(1, &vao[i]);
        glBindVertexArray(vao[i]);
    
        glBindBuffer(GL_ARRAY_BUFFER, verticesVBO[i]);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);
        glBindBuffer(GL_ARRAY_BUFFER, normalsVBO[i]);
        glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, NULL);
        //    glBindBuffer(GL_ARRAY_BUFFER, texturesVBO);
        //  glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    
        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
    }
#else
    //Single VBO
    
    glGenVertexArrays(1, &vao[0]);
    glBindVertexArray(vao[0]);
    
    glBindBuffer(GL_ARRAY_BUFFER, verticesVBO[0]);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glBindBuffer(GL_ARRAY_BUFFER, normalsVBO[0]);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
#endif
    
}
/*
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
*/
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
    
    
    projectionMatrix = glm::perspective(67.0f, (float)g_gl_width/(float)g_gl_height, 0.1f, 1000.0f);
    
    glUniformMatrix4fv(modelMatrixUniform, 1, GL_FALSE, glm::value_ptr(translateMatrix));
    glUniformMatrix4fv(viewMatrixUniform, 1, GL_FALSE, glm::value_ptr(rotateMatrix));
    glUniformMatrix4fv(projectionMatrixUniform, 1, GL_FALSE, glm::value_ptr(projectionMatrix));
}

#pragma mark Collisions

//Example right now, change return value later to a vector or smth, or can make another function

void collisionHappened(int objectOne, int objectTwo)
{
    printf("Collision Happened: %i and %i\n", objectOne, objectTwo);
    //Seperate into 3 different dimensions
    //fml
    //never mind you only swap the velocities cuz of the same mass
    if (collisions[objectOne] != objectTwo)
    {
        glm::vec3 posOne = positions[objectOne];
        glm::vec3 posTwo = positions[objectTwo];
        
        glm::vec3 velOne = velocity[objectOne];
        glm::vec3 velTwo = velocity[objectTwo];
        
        glm::vec3 newVelTwo = glm::normalize(posTwo - posOne) * glm::length(velTwo);
        glm::vec3 newVelOne = glm::normalize(posOne - posTwo) * glm::length(velOne);

        //velocity[objectOne] = velocity[objectTwo];
        //velocity[objectTwo] = velOne;
        
        velocity[objectOne] = newVelOne;
        velocity[objectTwo] = newVelTwo;
        
    }
}

void collided(int objectOne, int objectTwo)
{
    BOOL collided = NO;
    
    glm::vec3 object1 = positions[objectOne];
    glm::vec3 object2 = positions[objectTwo];
    
    if (sqrt((object1.x-object2.x) * (object1.x-object2.x) + ((object1.y-object2.y)*(object1.y-object2.y) + (object1.z-object2.z)*(object1.z-object2.z))) < diameter)
        collided = YES;
    else
        collided = NO;
    
    if (collided == YES)
        collisionHappened(objectOne, objectTwo);
}

//Easiest and shortest, but inefficient. Has runtime of O(n^2)


void collisionNestedLoop()
{
    for (int i=0;i<numberOfObjects;i++)
    {
        for (int j=i+1;j<numberOfObjects;j++)
            collided(i, j);
    }
}

#if COLLISION_DETECTION_METHOD == 1

void collisionOctree()
{
    for (int i=0;i<numberOfObjects;i++)
    {
        glm::vec3 pos = positions[i];
        
        
        printf("X: %f, Y: %f, Z: %f\n", pos.x, pos.y, pos.z);
        
        pos.x = round(pos.x);
        pos.y = round(pos.y);
        pos.z = round(pos.z);
        
        if (tree.at((int)pos.x, (int)pos.y, (int)pos.z)!=i)
        {
            tree.set(pos.x, pos.y, pos.z, i);
            tree.erase(pos.x, pos.y, pos.z);
        }
        
        
        //Loop through all the positions around it, 27 tests per sphere (including itself)
        for (int z=-1;z<=1;z++)
        {
            for (int y=-1;y<=1;y++)
            {
                for (int x=-1;x<=1;x++)
                {
                    //No need to check collision with itself, continue
                    if (x==0 && y==0 && z==0) continue;
                    //Checks that are out of bounds, continue
                    //Can probably improve efficiency by changing the condition in the loop
                    if (pos.x+x < 0 || pos.y+y < 0 || pos.z + z < 0 || pos.x+x >= containerSize || pos.y+y >= containerSize || pos.z+z >= containerSize) continue;
                    
                    int j = tree.at(pos.x+x, pos.y+y, pos.z+z);
                    
                    if (j != -1)
                    {
                        BOOL collide = collided(i, j);
                        if (collide == YES)
                            collisionHappened(i, j);
                    }
                }
            }
        }
    }
    
    
    /*
    int zSize = containerSize;
    int ySize = containerSize;
    int xSize = containerSize;
    
    for ( int z = 0; z < zSize; ++z ) {
        for ( int y = 0; y < ySize; ++y ) {
            for ( int x = 0; x < xSize; ++x ) {
                printf("X: %i Y: %i Z: %i - %i\n", x, y, z, tree.at(x,y,z));
            }
        }
    }
    */
    
}

//I give up on octree :'(
void collisionSpatialGrid()
{
    
}

#endif

#if COLLISION_DETECTION_METHOD == 2


//WHATEVER FUCK THIS CLOSE ENOUGH
void collisionSweepAndPrune()
{
    for (int i=0;i<numberOfObjects;i++)
        xAxisSorted[i] = positions[xAxisElement[i]].x;
    
    //lol forgot to update list
    insertionSort(xAxisSorted, xAxisElement, numberOfObjects);
    
    for (int i=0;i<numberOfObjects;i++)
    {
        int j = i+1;
        
        //SPHERE RADIUS IS 1 NOT 0.5 OH SHIT THAT'S WHY I SCREWED UP MY ALGORITHMS FML
        //Adds 1.001 cuz of float error
        while (xAxisSorted[i] > xAxisSorted[j]-diameter && j < numberOfObjects)
        {
            collided(xAxisElement[i], xAxisElement[j]);
            j++;
        }
    }
}

#endif

#if COLLISION_DETECTION_METHOD == 3

void collision3AxisSweepAndPrune()
{
    
    for (int i=0;i<numberOfObjects;i++)
    {
        xAxisSorted[i] = positions[xAxisElement[i]].x;
        yAxisSorted[i] = positions[yAxisElement[i]].y;
        zAxisSorted[i] = positions[zAxisElement[i]].z;
    }
    
    
    insertionSort(xAxisSorted, xAxisElement, numberOfObjects);
    insertionSort(yAxisSorted, yAxisElement, numberOfObjects);
    insertionSort(zAxisSorted, zAxisElement, numberOfObjects);
    
    vector<string> xCollision, yCollision, zCollision;
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    for (int i=0;i<numberOfObjects;i++)
    {
        int j = i+1;
        int k = i+1;
        int l = i+1;
        
        while (xAxisSorted[i] > xAxisSorted[j]-diameter && j < numberOfObjects)
        {
            if (xAxisElement[i]<xAxisElement[j])
                xCollision.push_back(std::to_string(xAxisElement[i])+","+std::to_string(xAxisElement[j]));
            else
                xCollision.push_back(to_string(xAxisElement[j])+","+to_string(xAxisElement[i]));
            j++;
        }
        
        while (yAxisSorted[i] > yAxisSorted[k]-diameter && k<numberOfObjects)
        {
            if (yAxisElement[i]<yAxisElement[k])
                yCollision.push_back(std::to_string(yAxisElement[i])+","+std::to_string(yAxisElement[k]));
            else
                yCollision.push_back(to_string(yAxisElement[k])+","+to_string(yAxisElement[i]));
            k++;
        }
        
        while (zAxisSorted[i] > zAxisSorted[l]-diameter && l<numberOfObjects)
        {
            if (zAxisElement[i]<zAxisElement[l])
                zCollision.push_back(std::to_string(zAxisElement[i])+","+std::to_string(zAxisElement[l]));
            else
                zCollision.push_back(to_string(zAxisElement[l])+","+to_string(zAxisElement[i]));
            l++;
        }
    }
    
    /*
    for (int i=0;i<xCollision.size();i++)
    {
        printf("X: %s\n", xCollision[i].c_str());
    }
    
    for (int i=0;i<yCollision.size();i++)
    {
        printf("Y: %s\n", yCollision[i].c_str());
    }
    
    for (int i=0;i<zCollision.size();i++)
    {
        printf("Z: %s\n", zCollision[i].c_str());
    }
    
    */
    
    startTime = CFAbsoluteTimeGetCurrent();
    
    
    sort(xCollision.begin(), xCollision.end());
    sort(yCollision.begin(), yCollision.end());
    sort(zCollision.begin(), zCollision.end());

    printf("sort: %f\n", CFAbsoluteTimeGetCurrent() - startTime);
    
    vector<string>xyIntersection, xyzIntersection;
    set_intersection(xCollision.begin(), xCollision.end(), yCollision.begin(), yCollision.end(), back_inserter(xyIntersection));
    set_intersection(xyIntersection.begin(), xyIntersection.end(), zCollision.begin(), zCollision.end(), back_inserter(xyzIntersection));
    
    for (int i=0;i<xyzIntersection.size();i++)
    {
        string s = xyzIntersection[i];
        
        char_separator<char> sep(",");
        tokenizer<char_separator<char>> tokens(s, sep);
        
        int p[2];
        int q = 0;
        
        BOOST_FOREACH(string t, tokens)
        {
            p[q] = stoi(t);
            q++;
        }
        
        //Probably can switch this to collisionHappened(), but do that later
        //Can't use collisionHappened because it becomes a square, still needs narrowphase check
        //collisionHappened(xAxisElement[p[0]], xAxisElement[p[1]]);
        collided(xAxisElement[p[0]], xAxisElement[p[1]]);
        
        
    }

}

#endif

void checkCollisions() //Main Collision Function
{
    /*
     Problems:
     1. Keeps randomly increasing it's maximum height, presumably because of CPU lag, however suvat still doesn't solve it so
     2. Also slightly decreases it's maximum height
     */
    unsigned long posSize = shapes[0].mesh.positions.size();
    
    static double prev_seconds = glfwGetTime ();
    double curr_seconds = glfwGetTime ();
    double elapsed_seconds = curr_seconds - prev_seconds;
    
    prev_seconds = curr_seconds;
    
    glm::vec3 gravityFrame = gravity * (float)elapsed_seconds;
    //printf("Elapsed Seconds: %.10f\n", elapsed_seconds);
    //printf("Gravity Frame:  %.10f\n", gravityFrame.y);
    
    for (int i=0;i<numberOfObjects;i++)
    {
        //Temp velocity and position to check for next potential position
        glm::vec3 tempVelocity = velocity[i]+gravityFrame;
        glm::vec3 tempPos = positions[i];
        
        tempPos.y += tempVelocity.y*elapsed_seconds;
        

        //Flip velocity if it hits the bottom of the container
        if (tempPos.y<=0)
        {
            //Still slightly inaccurate, height slightly decreases each time
            
            //Too simple, gonna have to add a slightly more advanced algorithm
            //velocity[i].y*=-1;
            
            //Simple SUVAT to get velocity when it bounces back up
           
            float s = -positions[i].y;
            float u = velocity[i].y;
            float a = gravity.y;
            
            float v = sqrt(u*u + 2*a*s);
            float t = 2*s/(v-u);
            
            //Needs to add gravityFrame.y so the velocity doesn't keep dropping, don't know why..
            //velocity[i].y = v + a*timeRemain - gravityFrame.y;
            velocity[i].y = v - a*t;
        }
        else //Else apply gravity
        {
            velocity[i]+=gravityFrame;
        }
        
        
        
        //Checks for wall collisions
        if (tempPos.x<0+radius) //Half of a radius
        {
            velocity[i].x=abs(velocity[i].x);
        }
        else if (tempPos.x>containerSize-radius)
        {
            velocity[i].x=abs(velocity[i].x)*-1;
        }
        
        if (tempPos.z<0+ radius)
        {
            velocity[i].z=abs(velocity[i].z);
        }
        else if (tempPos.z>containerSize-1)
        {
            velocity[i].z=abs(velocity[i].z)*-1;
        }
        
        
        //positions[i].y+=velocity[i].y*elapsed_seconds;
    
        positions[i] += velocity[i] * (float)elapsed_seconds;
        
        for (int j=0;j<posSize/3;j++)
        {
            posVert[i*posSize + j*3] += velocity[i].x * elapsed_seconds;
            posVert[i*posSize + j*3+1]+=velocity[i].y * elapsed_seconds;
            posVert[i*posSize + j*3+2] += velocity[i].z * elapsed_seconds;
        }
    }
    
    //Check collision with each other object
    
#if COLLISION_DETECTION_METHOD == 0
    
    collisionNestedLoop();
    
#endif
    
#if COLLISION_DETECTION_METHOD == 1
    
    collisionOctree();
    
#endif
    
#if COLLISION_DETECTION_METHOD == 2
    
    collisionSweepAndPrune();
    
#endif
    
#if COLLISION_DETECTION_METHOD == 3
    
    collision3AxisSweepAndPrune();
    
#endif
    
    printf("Seconds: %f\n", elapsed_seconds);
    
    //printf("Position: %f\n", positions[10].y);
 //   printf("Velocity: %f\n", velocity[10].y);

}

//Octree implementation at http://nomis80.org/code/octree.html
//Just the data structure, but that's like 90% of the work

#pragma mark GCD Functions

void setupGCD()
{
    collisionQueue = dispatch_queue_create("com.michael.collision.collisionqueue", NULL);
    drawQueue = dispatch_queue_create("com.michael.collision.drawqueue", NULL);
}

void runCollision()
{
    dispatch_async(collisionQueue, ^(void) {
        while(1)
        {
            checkCollisions();
            usleep(COLLISION_CHECK_INTERVAL);
        }
    });
}


#pragma mark Main

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        
        loadObj();
        
        initializeWindow();
    
        initializeOpenGL();
        GetGLError();
        initializeBuffers();
        GetGLError();
        initializeArrays();
        GetGLError();
        compileShaders();
        GetGLError();
        createUniforms();
        GetGLError();
        
        //GCD Stuff
        setupGCD();
        runCollision();
        
        unsigned long posSize = shapes[0].mesh.positions.size();
        
        while(!glfwWindowShouldClose(window))
        {
            static double previous_seconds = glfwGetTime ();
            double current_seconds = glfwGetTime ();
            double elapsed_seconds = current_seconds - previous_seconds;
            
            
            if (elapsed_seconds > FPS)
   //             COLLISION_CHECK_INTERVAL-=COLLISION_CHECK_INTERVAL_CHANGE;
            
            previous_seconds = current_seconds;
            
            //Show FPS on window title, may be inefficient
            calcFPS(1, "OpenGL");

            glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            
#if !BATCH_DRAWING
            for (int i=0;i<numberOfObjects;i++)
            {
                glBindVertexArray(vao[i]);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementsVBO[i]);
                glDrawElements(GL_TRIANGLES, (GLsizei)shapes[0].mesh.indices.size(), GL_UNSIGNED_INT, 0);
            }
#else
            glBindBuffer(GL_ARRAY_BUFFER, verticesVBO[0]);
            glBufferSubData(GL_ARRAY_BUFFER, 0, posSize * numberOfObjects * sizeof(GLfloat), posVert);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementsVBO[0]);
            glDrawElements(GL_TRIANGLES, (GLsizei)shapes[0].mesh.indices.size() * numberOfObjects, GL_UNSIGNED_INT, 0);
#endif
            GetGLError();
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
            if (glfwGetKey(window, GLFW_KEY_UP))
            {
                camPosition[1] += camSpeed * elapsed_seconds;
                cam_moved = true;
            }
            if (glfwGetKey(window, GLFW_KEY_DOWN))
            {
                camPosition[1] -= camSpeed * elapsed_seconds;
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

