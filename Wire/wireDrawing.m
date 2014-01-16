//
//  wireDrawing.m
//  Wire
//
//  Created by Lane Shetron on 1/16/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import "wireDrawing.h"

#define             STROKE_WIDTH_MIN 0.002 // Stroke width determined by touch velocity
#define             STROKE_WIDTH_MAX 0.010
#define       STROKE_WIDTH_SMOOTHING 0.5   // Low pass filter alpha

#define           VELOCITY_CLAMP_MIN 20
#define           VELOCITY_CLAMP_MAX 5000

#define QUADRATIC_DISTANCE_TOLERANCE 3.0   // Minimum distance to make a curve

#define             MAXIMUM_VERTICES 100000


static GLKVector3 StrokeColor = { 0, 0, 0 };

struct wireDrawingPoint {
    GLKVector3 vertex;
    GLKVector3 color;
};
typedef struct wireDrawingPoint wireDrawingPoint;


// maximum # of vertices
static const int maxLength = MAXIMUM_VERTICES;

// Append vertex to array buffer
static inline void addVertex(uint *length, wireDrawingPoint v) {
    if ((*length) >= maxLength) {
        return;
    }
    
    GLvoid *data = glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
    memcpy(data + sizeof(wireDrawingPoint) * (*length), &v, sizeof(wireDrawingPoint));
    glUnmapBufferOES(GL_ARRAY_BUFFER);
    
    (*length)++;
}

static inline CGPoint QuadraticPointInCurve(CGPoint start, CGPoint end, CGPoint controlPoint, float percent) {
    double a = pow((1.0 - percent), 2.0);
    double b = 2.0 * percent * (1.0 - percent);
    double c = pow(percent, 2.0);
    
    return (CGPoint) {
        a * start.x + b * controlPoint.x + c * end.x,
        a * start.y + b * controlPoint.y + c * end.y
    };
}

static float generateRandom(float from, float to) { return random() % 10000 / 10000.0 * (to - from) + from; }
static float clamp(min, max, value) { return fmaxf(min, fminf(max, value)); }

static GLKVector3 perpendicular(wireDrawingPoint p1, wireDrawingPoint p2) {
    GLKVector3 ret;
    ret.x = p2.vertex.y - p1.vertex.y;
    ret.y = -1 * (p2.vertex.x - p1.vertex.x);
    ret.z = 0;
    return ret;
}

static wireDrawingPoint ViewPointToGL(CGPoint viewPoint, CGRect bounds, GLKVector3 color) {
    
    return (wireDrawingPoint)
    {
        {
            (viewPoint.x / bounds.size.width * 2.0 - 1),
            ((viewPoint.y / bounds.size.height) * 2.0 - 1) * -1,
            0
        },
        color
    };
}


@interface wireDrawing () {
    // OpenGL state
    EAGLContext *context;
    GLKBaseEffect *effect;
    
    GLuint vertexArray;
    GLuint vertexBuffer;
    GLuint dotsArray;
    GLuint dotsBuffer;
    
    
    // Array of verteces, with current length
    wireDrawingPoint SignatureVertexData[maxLength];
    uint length;
    
    wireDrawingPoint SignatureDotsData[maxLength];
    uint dotsLength;
    
    
    // Width of line at current and previous vertex
    float penThickness;
    float previousThickness;
    
    
    // Previous points for quadratic bezier computations
    CGPoint previousPoint;
    CGPoint previousMidPoint;
    wireDrawingPoint previousVertex;
    wireDrawingPoint currentVelocity;
}

@end


@implementation wireDrawing

@end
