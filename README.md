OpenGL-4---Test
===============

Just playing around with OpenGL 4 on Mavericks

First Commit: 2013-11-29
- Renders basic triangle 

Added Color: 2013-12-08
- Adds Color to Triangle

Added Movement (Translation/Rotation): 2013-12-08
- Translational movement with 'asdw'
- Rotational movement with arrow keys

Switched Rotation method from Matrices to Quaternions: 2013-12-09
- Switched from using matrices to quaternions for rotations
  - Tested by making 1,000,000 100˚ rotational matrices
  - Matrices:
    - 1.674 seconds
  - Quaternions: 
    - .592
  - Quaternions are almost 3 times faster than matrices
  

