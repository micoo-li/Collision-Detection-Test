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
  

Used Indices and Added Lighting: 2013-12-26
- Used Indices (elements) instead
- Also added simple lighting support (along with normals ofc)

Added Model To Render: 2013-12-26
- Can now read obj files


==============
Problems

- Don't know how to translate normals from object to world space. Whatever screw it lol close enough