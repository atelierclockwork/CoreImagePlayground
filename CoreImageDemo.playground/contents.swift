import UIKit
import CoreImage
import CoreGraphics

// Gradient Drawing function, used to geenrated CIImage gradients for use in blending or masking
func drawLinearGradient(rect:CGRect, start:CGPoint, end:CGPoint, gradientPoints:[(CGColor, CGFloat)]) -> CIImage{
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()
    let colors = gradientPoints.map{ return $0.0 }
    let points = gradientPoints.map{ return $0.1 }
    let gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), colors, points)
    CGContextDrawLinearGradient(context, gradient, start, end, 0)
    let img = CIImage(image: UIGraphicsGetImageFromCurrentImageContext())
    UIGraphicsEndImageContext()
    return img
}

// A functional infix operator used to stack filter chains
infix operator >>> {
    associativity left
    precedence 155
}

func >>> (lhs: CIImage, rhs: CIFilter) -> CIImage
{
    rhs.setValue(lhs, forKey: "inputImage")
    return rhs.outputImage
}

let oni = UIImage(named: "oni.png")!

//Creating the CIContext to be used throughout
let eagl = EAGLContext(API: EAGLRenderingAPI.OpenGLES3)

let context = CIContext(EAGLContext: eagl)

// Creating the filter stack
//Increases vibrance to make colors pop more
let vibrance = CIFilter(name: "CIVibrance", withInputParameters: ["inputAmount": 255.0])

// The frame to be used for all of the calculations
let oniFrame = CGRectMake(0, 0, oni.size.width, oni.size.height)

let top = CGPointMake(oniFrame.midX, oniFrame.minY)

let bottom = CGPointMake(oniFrame.midX, oniFrame.maxY)

let multiplyDarken = drawLinearGradient(oniFrame, top, bottom,
    [(UIColor(white: 0.25, alpha: 1.0).CGColor, 0.0),
     (UIColor.whiteColor().CGColor, 1.0)])

let blurMask = drawLinearGradient(oniFrame, top, bottom,
    [(UIColor.whiteColor().CGColor, 0.0),
     (UIColor(white: 0.5, alpha: 1.0).CGColor, 0.75),
     (UIColor.blackColor().CGColor, 1.0)])

let blurAmount:CGFloat = 10.0

// Expands the image infinitely in all directions using the edge pixel color, used to make the blur look good at the edges
let afflineClamp = CIFilter(name: "CIAffineClamp", withInputParameters:["inputTransform": NSValue(CGAffineTransform: CGAffineTransformIdentity)])

// Crops the infinite expansion to a range useful for blurring
let expand = CIFilter(name: "CICrop", withInputParameters: ["inputRectangle": CIVector(CGRect: CGRectInset(oniFrame, 0 - (blurAmount * 10), 0 - (blurAmount * 10)))])

// Crops back to the original frame to remove the extra data created for blurring
let recrop = CIFilter(name: "CICrop", withInputParameters: ["inputRectangle": CIVector(CGRect: oniFrame)])

//Blurs the image based on the gradient being passed in
let blur = CIFilter(name: "CIMaskedVariableBlur", withInputParameters: ["inputMask": blurMask, "inputRadius": blurAmount])

//Darkens the image using a multiply overlay
let multiply = CIFilter(name: "CIMultiplyBlendMode", withInputParameters: ["inputBackgroundImage": multiplyDarken])

//Executes the filter stack
let oniCI = CIImage(image: oni) >>> vibrance >>> afflineClamp >>> expand >>> blur >>> recrop >>> multiply

