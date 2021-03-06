//
//  wireDrawing.m
//  Wire
//
//  Created by Lane Shetron on 1/16/14.
//  Copyright (c) 2014 VINE Entertainment, Inc. All rights reserved.
//

#import "wireDrawing.h"
#import "GLKContainer.h"
#import "UIColor+colorWithRGB.h"

#define             STROKE_WIDTH_MIN 0.002 // Stroke width determined by touch velocity
#define             STROKE_WIDTH_MAX 0.015 // default is 0.010
#define       STROKE_WIDTH_SMOOTHING 0.3   // Low pass filter alpha

#define           VELOCITY_CLAMP_MIN 20
#define           VELOCITY_CLAMP_MAX 5000

#define QUADRATIC_DISTANCE_TOLERANCE 2.0   // Minimum distance to make a curve
                                           // default is 3.0, but it's at 2.0 currently to avoid breaking at cusps
#define             MAXIMUM_VERTICES 100000
#define               SPIN_SMOOTHING 0.05

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

static GLKVector3 hexToVector3(int color)
{
    return (GLKVector3)
    {
        ( (float) ((color & 0xFF0000) >> 16) ) / 255.0f,
        ( (float) ((color & 0xFF00) >> 8) ) / 255.0f,
        ( (float) (color & 0xFF) ) / 255.0f
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
    
    // double-panned points
    CGPoint previousDPPoint;
    
    // color wheel gesture
    UIPanGestureRecognizer *spin;
    CGPoint previousSPPoint;
    GLKVector2 blackDelta;
    GLKVector2 redDelta;
    GLKVector2 tealDelta;
    GLKVector2 orangeDelta;
    GLKVector2 greenDelta;
    GLKVector2 pinkDelta;
    
    CGImageRef backgroundBrush;
    GLubyte *backgroundData;
    GLuint backgroundTexture;
    CGContextRef backgroundContext;
    size_t backgroundWidth, backgroundHeight;
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
        // double resolution on iPhone
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            self.contentScaleFactor = 5.0f;
        }
        else
        {
            // Turn on antialiasing
            self.drawableMultisample = GLKViewDrawableMultisample4X;
        }
        
        // make background transparent
        //CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        //eaglLayer.opaque = NO;
        
        [self setupGL];
        
        // Spinning color wheel gesture
        spin = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(spin:)];
        spin.maximumNumberOfTouches = spin.minimumNumberOfTouches = 1;
        [self addGestureRecognizer:spin];

        blackDelta = (GLKVector2) { 0, -42.5f };
        redDelta = (GLKVector2) { 42.5f, -21.25f };
        tealDelta = (GLKVector2) { 42.5f, 21.25f };
        orangeDelta = (GLKVector2) { 0, 42.5f };
        greenDelta = (GLKVector2) { -42.5f, 21.25f };
        pinkDelta = (GLKVector2) { -42.5f, -21.25f };
        
        // create background texture
        
        backgroundBrush = [UIImage imageNamed:@"sticky note"].CGImage;
        backgroundWidth = CGImageGetWidth(backgroundBrush);
        backgroundHeight = CGImageGetHeight(backgroundBrush);
        
        if (backgroundBrush)
        {
            backgroundData = (GLubyte *) calloc(backgroundWidth * backgroundHeight * 4, sizeof(GLubyte));
            backgroundContext = CGBitmapContextCreate(backgroundData, backgroundWidth, backgroundHeight, 8, backgroundWidth * 4, CGImageGetColorSpace(backgroundBrush), kCGImageAlphaPremultipliedLast);
            CGContextDrawImage(backgroundContext, CGRectMake(0, 0, (CGFloat)backgroundWidth, (CGFloat)backgroundHeight), backgroundBrush);
            CGContextRelease(backgroundContext);
            glGenTextures(1, &backgroundTexture);
            glBindTexture(GL_TEXTURE_2D, backgroundTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, backgroundWidth, backgroundHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, backgroundData);
            free(backgroundData);
            
            /*glEnable(GL_TEXTURE_2D);
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_BLEND);*/
        }
        else
        {
            NSLog(@"Failed to load image");
        }
        
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

- (void)setupGestures
{
    [_blackButton setHidden:YES];
    [_redButton setHidden:YES];
    [_tealButton setHidden:YES];
    [_greenButton setHidden:YES];
    [_orangeButton setHidden:YES];
    [_pinkButton setHidden:YES];
    
    [self removeGestureRecognizer:spin];
    
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
    
    // Sending with double pan
    UIPanGestureRecognizer *doublepan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(doublepan:)];
    doublepan.maximumNumberOfTouches = doublepan.minimumNumberOfTouches = 2;
    [self addGestureRecognizer:doublepan];
}

#pragma mark - color selection

- (IBAction)blackSelected:(id)sender
{
    StrokeColor = (GLKVector3) { 0, 0, 0 };
    
    [self setupGestures];
}

- (IBAction)redSelected:(id)sender
{
    StrokeColor = hexToVector3(0xCF6767);
    
    [self setupGestures];
}

- (IBAction)tealSelected:(id)sender
{
    StrokeColor = hexToVector3(0x20A1CB);
    
    [self setupGestures];
}

- (IBAction)greenSelected:(id)sender
{
    StrokeColor = hexToVector3(0x36E876);
    
    [self setupGestures];
}

- (IBAction)orangeSelected:(id)sender
{
    StrokeColor = hexToVector3(0xFFA13B);
    
    [self setupGestures];
}

- (IBAction)pinkSelected:(id)sender
{
    StrokeColor = hexToVector3(0xF33887);
    
    [self setupGestures];
}

- (void)dealloc
{
    [self tearDownGL];
    
    if (backgroundTexture)
    {
        glDeleteTextures(1, &backgroundTexture);
        backgroundTexture = 0;
    }
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    context = nil;
}

- (void)drawRect:(CGRect)rect
{
    glClearColor(1, 1, 1, 1.0f);
    //glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [effect prepareToDraw];
    
    // draw background texture
    GLfloat vert[] = { 0, 0, self.frame.size.width, 0, self.frame.size.width, self.frame.size.height, 0, self.frame.size.height };
    GLfloat tex[] = { 0,0, 1,0, 1,1, 0,1 };
    GLuint indexes[] = { 0, 1, 2, 2, 3, 0 };
    
    glBindTexture(GL_TEXTURE_2D, backgroundTexture);
    glEnable(GL_TEXTURE_2D);
    
    glVertexPointer(2, GL_FLOAT, 0, vert);
    glTexCoordPointer(2, GL_FLOAT, 0, tex);
    glDrawElements(GL_TRIANGLES, 2, GL_UNSIGNED_INT, indexes);
    

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
    NSArray *sysPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES);
    NSString *prefsDirectory = [[sysPaths objectAtIndex:0] stringByAppendingPathComponent:@"/Preferences"];
    NSString *outputFilePath = [prefsDirectory stringByAppendingPathComponent:@"data.plist"];
    NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:outputFilePath];
    
    // capture image
    UIImage *imagedata = [self signatureImage];
    NSData *pngData = UIImagePNGRepresentation(imagedata);
   
    // send to server
    NSString *address;
    for (NSDictionary *friend in [plistData objectForKey:@"friends"])
    {
        if ([friend objectForKey:@"username"] == [plistData objectForKey:@"recipient"])
        {
            address = [friend objectForKey:@"address"];
        }
    }
    NSString *recipient = [plistData objectForKey:@"recipient"];
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
    UINavigationController *navigationController = (UINavigationController*) self.window.rootViewController;
    [navigationController popToRootViewControllerAnimated:YES];
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
        GLKVector2 radius = (GLKVector2){ penThickness * 1.5 * generateRandom(0.5, 1.5), penThickness * 1.5 * generateRandom(0.75, 1.25) };
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

- (void)resetDrift {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    CGRect rect = self.frame;
    rect.origin.y = 0.0;
    self.frame = rect;
    [UIView commitAnimations];
}

- (void)doublepan:(UIPanGestureRecognizer *)dp {
    CGPoint v = [dp velocityInView:self.window];
    CGPoint l = [dp locationInView:self.window];
    float a = 5500.0f;
    float distance = (l.y - previousDPPoint.y);

    if ([dp state] == UIGestureRecognizerStateBegan)
    {
        previousDPPoint = l;
        [self.window setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    }
    else if ([dp state] == UIGestureRecognizerStateChanged)
    {
        if (self.frame.origin.y + distance <= 0.0)
        {
            previousDPPoint = l;
            CGRect rect = self.frame;
            rect.origin.y += distance;
            self.frame = rect;
        }
    }
    else if ([dp state] == UIGestureRecognizerStateEnded || [dp state] == UIGestureRecognizerStateCancelled)
    {
        if (self.frame.origin.y < -(self.window.frame.size.height / 3) * 2)
        {
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.3];
            CGRect rect = self.frame;
            rect.origin.y = -rect.size.height;
            self.frame = rect;
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(sendWire:)];
            [UIView commitAnimations];
        }
        else
        {
            float time = -v.y / a;
            float drift = v.y * time + (a / 2) * (time * time);
            if (drift < 0.0)
            {
                if (self.frame.origin.y + drift < -(self.window.frame.size.height / 3) * 2)
                {
                    [UIView beginAnimations:nil context:NULL];
                    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
                    [UIView setAnimationDuration:0.3];
                    CGRect rect = self.frame;
                    rect.origin.y = -rect.size.height;
                    self.frame = rect;
                    [UIView setAnimationDelegate:self];
                    [UIView setAnimationDidStopSelector:@selector(sendWire:)];
                    [UIView commitAnimations];
                }
                else
                {
                    [UIView beginAnimations:nil context:NULL];
                    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
                    [UIView setAnimationDuration:time];
                    CGRect driftRect = self.frame;
                    driftRect.origin.y += drift;
                    self.frame = driftRect;
                    [UIView setAnimationDelegate:self];
                    [UIView setAnimationDidStopSelector:@selector(resetDrift)];
                    [UIView commitAnimations];
                }
            }
            else
            {
                [self resetDrift];
            }
        }
    }
}

- (void)spin:(UIPanGestureRecognizer *)sp {
    CGPoint v = [sp velocityInView:self];
    CGPoint l = [sp locationInView:self];
    float a = -5000.0f;
    
    float distance = (l.y - previousSPPoint.y);
    if (l.x < self.frame.size.width / 2)
        distance = -distance;
    
    if ([sp state] == UIGestureRecognizerStateBegan)
    {
        previousSPPoint = l;
    }
    else if ([sp state] == UIGestureRecognizerStateChanged)
    {
        float arcAngle = distance / (85*M_PI) * 360 * SPIN_SMOOTHING;
        
        float blackDeltaX = cosf(arcAngle) * 42.5f - blackDelta.x;
        float blackDeltaY = sinf(arcAngle) * 42.5f - blackDelta.y;
        float redDeltaX = cosf(arcAngle + 45) * 42.5f - redDelta.x;
        float redDeltaY = sinf(arcAngle + 45) * 42.5f - redDelta.y;
        float tealDeltaX = cosf(arcAngle + 90) * 42.5f - tealDelta.x;
        float tealDeltaY = sinf(arcAngle + 90) * 42.5f - tealDelta.y;
        float orangeDeltaX = cosf(arcAngle + 135) * 42.5f - orangeDelta.x;
        float orangeDeltaY = sinf(arcAngle + 135) * 42.5f - orangeDelta.y;
        float greenDeltaX = cosf(arcAngle + 180) * 42.5f - greenDelta.x;
        float greenDeltaY = sinf(arcAngle + 180) * 42.5f - greenDelta.y;
        float pinkDeltaX = cosf(arcAngle + 225) * 42.5f - pinkDelta.x;
        float pinkDeltaY = sinf(arcAngle + 225) * 42.5f - pinkDelta.y;
        
        CGRect blackRect = _blackButton.frame;
        blackRect.origin.x += blackDeltaX;
        blackRect.origin.y += blackDeltaY;
        _blackButton.frame = blackRect;
        
        CGRect redRect = _redButton.frame;
        redRect.origin.x += redDeltaX;
        redRect.origin.y += redDeltaY;
        _redButton.frame = redRect;
        
        CGRect tealRect = _tealButton.frame;
        tealRect.origin.x += tealDeltaX;
        tealRect.origin.y += tealDeltaY;
        _tealButton.frame = tealRect;
        
        CGRect orangeRect = _orangeButton.frame;
        orangeRect.origin.x += orangeDeltaX;
        orangeRect.origin.y += orangeDeltaY;
        _orangeButton.frame = orangeRect;
        
        CGRect greenRect = _greenButton.frame;
        greenRect.origin.x += greenDeltaX;
        greenRect.origin.y += greenDeltaY;
        _greenButton.frame = greenRect;
        
        CGRect pinkRect = _pinkButton.frame;
        pinkRect.origin.x += pinkDeltaX;
        pinkRect.origin.y += pinkDeltaY;
        _pinkButton.frame = pinkRect;
        
        blackDelta.x += blackDeltaX;
        blackDelta.y += blackDeltaY;
        redDelta.x += redDeltaX;
        redDelta.y += redDeltaY;
        tealDelta.x += tealDeltaX;
        tealDelta.y += tealDeltaY;
        orangeDelta.x += orangeDeltaX;
        orangeDelta.y += orangeDeltaY;
        greenDelta.x += greenDeltaX;
        greenDelta.y += greenDeltaY;
        pinkDelta.x += pinkDeltaX;
        pinkDelta.y += pinkDeltaY;
    }
    else if ([sp state] == UIGestureRecognizerStateEnded || [sp state] == UIGestureRecognizerStateCancelled)
    {
        /*
        float time = v.y / a;
        float drift = v.y * time + (a / 2) * (time * time);
        
        CAKeyframeAnimation *arcAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        arcAnimation.calculationMode = kCAAnimationPaced;
        arcAnimation.fillMode = kCAFillModeForwards;
        arcAnimation.removedOnCompletion = NO; // may remove this
        arcAnimation.duration = 3;
        
        float startX = acosf((_blackButton.frame.origin.x - 105.6f) / 85.0f);
        float offsetY = (_blackButton.frame.origin.y - 224.0f) / 85.0f;
        if (offsetY < 0.5)
        {
            startX = -startX;
        }
        NSLog(@"%f %f", startX, offsetY);
        
        CGMutablePathRef arcPath = CGPathCreateMutable();
        CGPathAddArc(arcPath, NULL, 160.625f, 279.0f, 42.5f, startX, startX + 2.0f, distance < 0.0f ? true : false);
        
        arcAnimation.path = arcPath;
        CGPathRelease(arcPath);
        
        [_blackButton.layer addAnimation:arcAnimation forKey:@"position"];
        */
    }
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
