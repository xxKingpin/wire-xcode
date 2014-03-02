//
//  wireDrawing.m
//  Wire
//
//  Created by Lane Shetron on 1/16/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import "wireDrawing.h"
#import "GLKContainer.h"

#define             STROKE_WIDTH_MIN 0.002 // Stroke width determined by touch velocity
#define             STROKE_WIDTH_MAX 0.015 // default is 0.010
#define       STROKE_WIDTH_SMOOTHING 0.3   // Low pass filter alpha

#define           VELOCITY_CLAMP_MIN 20
#define           VELOCITY_CLAMP_MAX 5000

#define QUADRATIC_DISTANCE_TOLERANCE 2.0   // Minimum distance to make a curve
                                           // default is 3.0, but it's at 2.0 currently to avoid breaking at cusps
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
    float previousVelocity;
    
    
    // Previous points for quadratic bezier computations
    CGPoint previousPoint;
    CGPoint previousMidPoint;
    wireDrawingPoint previousVertex;
    wireDrawingPoint currentVelocity;
}

@end


@implementation wireDrawing


- (void)commonInit {
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (context) {
        time(NULL);
        
        self.context = context;
        self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        self.enableSetNeedsDisplay = YES;
        
        // Turn on antialiasing
        self.drawableMultisample = GLKViewDrawableMultisample4X;
        
        [self setupGL];
        
        // Capture touches
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        pan.maximumNumberOfTouches = pan.minimumNumberOfTouches = 1;
        [self addGestureRecognizer:pan];
        
        // For dotting your i's
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [self addGestureRecognizer:tap];
        
        // Erase with long press
        /*
        [self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
         */
        
    } else [NSException raise:@"NSOpenGLES2ContextException" format:@"Failed to create OpenGL ES2 context"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) [self commonInit];
    return self;
}


- (id)initWithFrame:(CGRect)frame context:(EAGLContext *)ctx
{
    if (self = [super initWithFrame:frame context:ctx]) [self commonInit];
    return self;
}


- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    context = nil;
}

- (void)drawRect:(CGRect)rect
{
    glClearColor(1, 1, 1, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [effect prepareToDraw];
    
    // Drawing of signature lines
    if (length > 2) {
        glBindVertexArrayOES(vertexArray);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, length);
    }
    
    if (dotsLength > 0) {
        glBindVertexArrayOES(dotsArray);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, dotsLength);
    }
    
}

- (void)erase {
    length = 0;
    dotsLength = 0;
    self.hasSignature = NO;
    
    [self setNeedsDisplay];
}


- (UIImage *)signatureImage
{
    if (!self.hasSignature)
        return nil;
    
    return [self snapshot];
}

- (IBAction)sendWire:(id)sender {
    // load plist
    NSURL *plist = [[NSBundle mainBundle] URLForResource:@"data" withExtension:@"plist"];
    NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfURL:plist];
    
    // capture image
    UIImage *imagedata = [self signatureImage];
    NSData *pngData = UIImagePNGRepresentation(imagedata);
   
    // send to server
    NSString *address;
    for (NSDictionary *friend in [plistData objectForKey:@"friends"])
    {
        if ([friend objectForKey:@"username"] == self.recipient)
        {
            address = [friend objectForKey:@"address"];
        }
    }
    NSString *recipient = self.recipient;
    NSString *username = [plistData objectForKey:@"username"];
    NSString *wire_type = @"_private";
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    NSMutableData *httpBody = [NSMutableData data];
    [httpBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[@"Content-Disposition: form-data; name=\"wire_recipient\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[recipient dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[@"Content-Disposition: form-data; name=\"wire_sender\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[username dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[@"Content-Disposition: form-data; name=\"address\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[address dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[@"Content-Disposition: form-data; name=\"wire_type\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[wire_type dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[@"Content-Disposition: form-data; name=\"pngData\"; filename=\"test.png\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[@"Content-Type: image/png\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [httpBody appendData:[NSData dataWithData:pngData]];
    [httpBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableURLRequest *sendRequest = [[NSMutableURLRequest alloc] init];
    [sendRequest setURL:[NSURL URLWithString:@"http://graffiti.im/wire.php"]];
    [sendRequest setHTTPMethod:@"POST"];
    [sendRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [sendRequest setHTTPBody:httpBody];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:sendRequest delegate:self];
    self.connection = conn;
    self.response = [[NSMutableData alloc] init];
    [conn start];
    NSLog(@"Wire sent!");
    
    // perform animations
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.response appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // don't currently need this for anything
    
    // release connection & response data
    connection = nil;
    self.response = nil;
}


#pragma mark - Gesture Recognizers


- (void)tap:(UITapGestureRecognizer *)t {
    CGPoint l = [t locationInView:self];
    
    if (t.state == UIGestureRecognizerStateRecognized) {
        glBindBuffer(GL_ARRAY_BUFFER, dotsBuffer);
        
        wireDrawingPoint touchPoint = ViewPointToGL(l, self.bounds, (GLKVector3){1, 1, 1});
        addVertex(&dotsLength, touchPoint);
        
        wireDrawingPoint centerPoint = touchPoint;
        centerPoint.color = StrokeColor;
        addVertex(&dotsLength, centerPoint);
        
        static int segments = 20;
        GLKVector2 radius = (GLKVector2){ penThickness * 2.0 * generateRandom(0.5, 1.5), penThickness * 2.0 * generateRandom(0.5, 1.5) };
        GLKVector2 velocityRadius = radius;//GLKVector2Multiply(radius, GLKVector2MultiplyScalar(GLKVector2Normalize((GLKVector2){currentVelocity.vertex.y, currentVelocity.vertex.x}), 1.0));
        float angle = 0;
        
        for (int i = 0; i <= segments; i++) {
            
            wireDrawingPoint p = centerPoint;
            p.vertex.x += velocityRadius.x * cosf(angle);
            p.vertex.y += velocityRadius.y * sinf(angle);
            
            addVertex(&dotsLength, p);
            addVertex(&dotsLength, centerPoint);
            
            angle += M_PI * 2.0 / segments;
        }
        
        addVertex(&dotsLength, touchPoint);
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    
    [self setNeedsDisplay];
}

- (void)longPress:(UILongPressGestureRecognizer *)lp {
    [self erase];
}

- (void)pan:(UIPanGestureRecognizer *)p {
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    
    CGPoint v = [p velocityInView:self];
    CGPoint l = [p locationInView:self];
    
    currentVelocity = ViewPointToGL(v, self.bounds, (GLKVector3){0,0,0});
    float distance = 0.;
    if (previousPoint.x > 0) {
        distance = sqrtf((l.x - previousPoint.x) * (l.x - previousPoint.x) + (l.y - previousPoint.y) * (l.y - previousPoint.y));
    }
    
    float velocityMagnitude = sqrtf(v.x*v.x + v.y*v.y);
    float clampedVelocityMagnitude = clamp(VELOCITY_CLAMP_MIN, VELOCITY_CLAMP_MAX, velocityMagnitude);
    float normalizedVelocity = (clampedVelocityMagnitude - VELOCITY_CLAMP_MIN) / (VELOCITY_CLAMP_MAX - VELOCITY_CLAMP_MIN);
    // added for velocity smoothing
    float lowPassFilterAlpha = STROKE_WIDTH_SMOOTHING;
    normalizedVelocity = previousVelocity * lowPassFilterAlpha + normalizedVelocity * (1 - lowPassFilterAlpha);
    previousVelocity = normalizedVelocity;
    
    /* old thickness algorithm
    float newThickness = (STROKE_WIDTH_MAX - STROKE_WIDTH_MIN) * normalizedVelocity + STROKE_WIDTH_MIN;
     */
    float newThickness = (STROKE_WIDTH_MIN - STROKE_WIDTH_MAX) * normalizedVelocity + STROKE_WIDTH_MAX;
    penThickness = penThickness * lowPassFilterAlpha + newThickness * (1 - lowPassFilterAlpha);
    
    if ([p state] == UIGestureRecognizerStateBegan) {
        
        previousPoint = l;
        previousMidPoint = l;
        
        wireDrawingPoint startPoint = ViewPointToGL(l, self.bounds, (GLKVector3){1, 1, 1});
        previousVertex = startPoint;
        previousThickness = penThickness;
        
        addVertex(&length, startPoint);
        addVertex(&length, previousVertex);
        
        self.hasSignature = YES;
        
    } else if ([p state] == UIGestureRecognizerStateChanged) {
        
        CGPoint mid = CGPointMake((l.x + previousPoint.x) / 2.0, (l.y + previousPoint.y) / 2.0);
        
        if (distance > QUADRATIC_DISTANCE_TOLERANCE) {
            // Plot quadratic bezier instead of line
            unsigned int i;
            
            int segments = (int) distance / 1.5;
            
            float startPenThickness = previousThickness;
            float endPenThickness = penThickness;
            previousThickness = penThickness;
            
            for (i = 0; i < segments; i++)
            {
                penThickness = startPenThickness + ((endPenThickness - startPenThickness) / segments) * i;
                
                CGPoint quadPoint = QuadraticPointInCurve(previousMidPoint, mid, previousPoint, (float)i / (float)(segments));
                
                wireDrawingPoint v = ViewPointToGL(quadPoint, self.bounds, StrokeColor);
                [self addTriangleStripPointsForPrevious:previousVertex next:v];
                
                previousVertex = v;
            }
        } else if (distance > 1.0) {
            
            wireDrawingPoint v = ViewPointToGL(l, self.bounds, StrokeColor);
            [self addTriangleStripPointsForPrevious:previousVertex next:v];
            
            previousVertex = v;
            previousThickness = penThickness;
        }
        
        previousPoint = l;
        previousMidPoint = mid;
        
    } else if (p.state == UIGestureRecognizerStateEnded | p.state == UIGestureRecognizerStateCancelled) {
        
        wireDrawingPoint v = ViewPointToGL(l, self.bounds, (GLKVector3){1, 1, 1});
        addVertex(&length, v);
        
        previousVertex = v;
        addVertex(&length, previousVertex);
    }
    
    [self setNeedsDisplay];
}


#pragma mark - Private

- (void)bindShaderAttributes {
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(wireDrawingPoint), 0);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE,  6 * sizeof(GLfloat), (char *)12);
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:context];
    
    effect = [[GLKBaseEffect alloc] init];
    
    glDisable(GL_DEPTH_TEST);
    
    // Signature Lines
    glGenVertexArraysOES(1, &vertexArray);
    glBindVertexArrayOES(vertexArray);
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SignatureVertexData), SignatureVertexData, GL_DYNAMIC_DRAW);
    [self bindShaderAttributes];
    
    
    // Signature Dots
    glGenVertexArraysOES(1, &dotsArray);
    glBindVertexArrayOES(dotsArray);
    
    glGenBuffers(1, &dotsBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, dotsBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SignatureDotsData), SignatureDotsData, GL_DYNAMIC_DRAW);
    [self bindShaderAttributes];
    
    
    glBindVertexArrayOES(0);
    
    
    // Perspective
    GLKMatrix4 ortho = GLKMatrix4MakeOrtho(-1, 1, -1, 1, 0.1f, 2.0f);
    effect.transform.projectionMatrix = ortho;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.0f);
    effect.transform.modelviewMatrix = modelViewMatrix;
    
    length = 0;
    penThickness = 0.003;
    previousPoint = CGPointMake(-100, -100);
}

- (void)addTriangleStripPointsForPrevious:(wireDrawingPoint)previous next:(wireDrawingPoint)next {
    float toTravel = penThickness / 2.0;
    
    for (int i = 0; i < 2; i++) {
        GLKVector3 p = perpendicular(previous, next);
        GLKVector3 p1 = next.vertex;
        GLKVector3 ref = GLKVector3Add(p1, p);
        
        float distance = GLKVector3Distance(p1, ref);
        float difX = p1.x - ref.x;
        float difY = p1.y - ref.y;
        float ratio = -1.0 * (toTravel / distance);
        
        difX = difX * ratio;
        difY = difY * ratio;
        
        wireDrawingPoint stripPoint = {
            { p1.x + difX, p1.y + difY, 0.0 },
            StrokeColor
        };
        addVertex(&length, stripPoint);
        
        toTravel *= -1;
    }
}


- (void)tearDownGL
{
    [EAGLContext setCurrentContext:context];
    
    glDeleteBuffers(1, &vertexBuffer);
    glDeleteVertexArraysOES(1, &vertexArray);
    
    effect = nil;
}

@end
