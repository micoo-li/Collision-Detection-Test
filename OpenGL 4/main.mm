//
//  main.m
//  OpenGL 4
//
//  Created by Michael on 29/11/13.
//  Copyright (c) 2013 michael. All rights reserved.
//

//Apple Stuff
#import <Cocoa/Cocoa.h>

//C/C++ Stuff
#include <iostream>
#include <string>
#include <sstream>
#include <cmath>
#include <time.h>

//OpenGL Stuff
#import <GL/glew.h>
#import <GLFW/glfw3.h>

//Namespace
using namespace std;

//Vertices
float points[] = {
    0.0, 0.5, 0.0,
    0.5, -0.5, 0.0,
    -0.5, -0.5, 0.0
};

float colors[] = {
    1.0, 0.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 0.0, 1.0
};

//Important variables
GLFWwindow *window;
unsigned int verticesVBO;
unsigned int colorVBO;
unsigned int vao;
unsigned int shaderProgram;
// keep track of window size for things like the viewport and the mouse cursor
int g_gl_width = 640;
int g_gl_height = 480;

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
    
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CW);
}

void initializeBuffers()
{
    glGenBuffers(1, &verticesVBO);
    glBindBuffer(GL_ARRAY_BUFFER, verticesVBO);
    glBufferData(GL_ARRAY_BUFFER, 9 * sizeof(float), points, GL_STATIC_DRAW);
    
    glGenBuffers(1, &colorVBO);
    glBindBuffer(GL_ARRAY_BUFFER, colorVBO);
    glBufferData(GL_ARRAY_BUFFER, 9 * sizeof(float), colors, GL_STATIC_DRAW);
}

void initializeArrays()
{
    glGenVertexArrays(1, &vao);
    glBindVertexArray(vao);
    glBindBuffer(GL_ARRAY_BUFFER, verticesVBO);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glBindBuffer(GL_ARRAY_BUFFER, colorVBO);
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
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
    glBindAttribLocation(shaderProgram, 1, "vertexColor");
    
    glLinkProgram(shaderProgram);
}

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        
        
        
        initializeWindow();
        
        char message[256];
        sprintf (message, "starting GLFW %s", glfwGetVersionString());
       // assert (gl_log (message, __FILE__, __LINE__));
        glfwSetErrorCallback (glfw_error_callback);
        
        
        initializeOpenGL();
        initializeBuffers();
        initializeArrays();
        compileShaders();
        
        //Extra Stuff Calls whatever lol
        
        log_gl_params();
        
        while(!glfwWindowShouldClose(window))
        {
            //Show FPS on window title, may be inefficient
            calcFPS(1, "OpenGL");
            
            glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            
            glViewport (0, 0, g_gl_width, g_gl_height);
            
            glUseProgram (shaderProgram);
            glBindVertexArray (vao);
            // draw points 0-3 from the currently bound VAO with current in-use shader
            glDrawArrays (GL_TRIANGLES, 0, 3);
            // update other events like input handling
            glfwPollEvents ();
            
            glfwSwapBuffers(window);
            
            //Key Presses
            if (GLFW_PRESS == glfwGetKey (window, GLFW_KEY_ESCAPE)) {
                glfwSetWindowShouldClose (window, 1);
            }
            
        }
        
        glfwTerminate();
    }
    return 0;
}

