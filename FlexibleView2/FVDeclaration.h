//
// Created by lishuo on 13-5-28.
// Copyright (c) 2013 Li Shuo. All rights reserved.
//


#import <Foundation/Foundation.h>

@class FVDeclaration;

/**
* The FlexibleView make heavy usage on special (magic) values to express lots of different layout relations.
*
*     Percent
*     After
*     RelatedTo
*     Auto
*     Fill
*
* By using these relations, the layout can be expressed in a relative way. E.g,
*
* This view is after the prev view, with same height.
* This view contains several subviews, calculate the height automatically.
* This view is half width of its parent view.
* This view's width just fills the gap between prev and next view.
* This view has the same x with prev loadView.
*
*/
#define FVSpecialValueMin 100000

/**
* The min of the range which reserved for After
*/
#define FVAfterMin 400000

/**
* The base value of the After
*/
#define FVAfterBase 450000
#define FVAfterMax 499999
#define FVIsAfter(x) ((x)>=FVAfterMin && (x) <= FVAfterMax)
#define FVAfter2Float(x) ((x) + FVAfterBase)
#define FVA FVAfter2Float
#define FVFloat2After(x) ((x) - FVAfterBase)
#define FVAfter FVAfter2Float(0)

/**
* FVFill make this loadView fill part, for width, it is xViewNext + widthViewNext - xViewPrev - xViewWidth
*/
#define FVFill 100001
#define FVIsFill(x) ((x)==FVFill)

/**
* FVAuto automatic calculate this loadView's width or height to make it just hold all sub views
*/
#define FVAuto 100002
#define FVIsAuto(x) ((x)==FVAuto)

/**
*
*/
#define FVPercentMin 100100
#define FVPercentMax 100200
#define FVIsPercent(x) ((x) >= FVPercentMin && (x) <= FVPercentMax)
#define FVPercentToFloat(x) ((x)*100 + FVPercentMin)
#define FVP(x) FVPercentToFloat(x)
#define FVFloat2Percent(x) (((x) - FVPercentMin) / 100)
#define FVF2P(x) FVFloat2Percent(x)
#define FVTailMin 200000
#define FVTailMax 299999
#define FVIsTail(x) ((x) >= FVTailMin && (x) <= FVTailMax)
#define FVTail2Float(x) ((x) + FVTailMin)
#define FVT(x) FVTail2Float(x)
#define FVFloat2Tail(x) ((x) - FVTailMin)
#define FVF2T(x) FVFloat2Tail(x)
#define FVRelatedMin 300000
#define FVRelatedBase 350000
#define FVRelatedMax 399999
#define FVIsRelated(x) ((x)>= FVRelatedMin && (x)<= FVRelatedMax)
#define FVR(x) ((x) + FVRelatedBase)
#define FVF2R(x) ((x) - FVRelatedBase)
#define FVSameAsPrev FVR(0)

#define FVIsNormal(x) ((x) < FVSpecialValueMin)

/**
* The typedef of View creation block
*/
typedef UIView* (^FVViewCreateBlock)(NSDictionary *context);

/**
* The typedef of template block, a typical usage: Create one block for each reusable UI element. The bar, form element etc.
*/
typedef FVDeclaration *(^FVDeclareTemplateBlock)();

/**
* This class stands for one view, though just its declaration. It holds the position, size information and also
* knows how to create the real UIView object.
*
* Example usage:
*
*         [[FVDeclaration declaration:@"NavigationBar" frame:CGRectMake(0, 0, FVP(1), 44)] withDeclarations:@[
*             [FVDeclaration declaration:@"MenuButton" frame:CGRectMake(0, 0, 44, FVP(1))],
*             [FVDeclaration declaration:@"ComposeButton" frame:CGRectMake(FVT(44), 0, 44, FVP(1))], ]]
*
* Above code create a navigation bar with 2 buttons, menu button stands on left with width 44. Compose button on right
*     FVP(1) : percentage 100%
*     FVT(44) : count from tail by 44 points
*     FVR(20) : count from the prev view's same attribute, x for x, y for y, and then plus 20
*     FVA(20) : follows the prev view, and then plus 20
*     FVAuto : auto calculate the width or height to just contain all subviews.  **
*
* @warning *note* prev view only counts in the siblings in the same parent.
* @warning *important* **when use auto, all its subviews' related frame attributes must be able to calculated without
* this loadView's info, otherwise, a dependency loop detected and error return
*/

@interface FVDeclaration : NSObject

/**
* The name of the node, it can be used to retrieve the node from the node tree
*/
@property (nonatomic,strong) NSString* name;

/**
* The frame of the node, it may contain all the magic values, and when calculate layout, they will be translated
*/
@property (nonatomic) CGRect frame;

/**
* The sub nodes if any
*/
@property (nonatomic, strong) NSMutableArray *subDeclarations;

/**
* The parent node if any
*/
@property (nonatomic, weak) FVDeclaration *parent;

/**
* The object is the view for this declaration, it will be merged with all sub declaration and returned
* when [self loadView] called
*/
@property (nonatomic, strong) UIView *object; //this is the object which this declaration owns

/**
* The block which will be called when there is no object available
*
* @warning: *note* if neither object nor objectCreationBlock exists, the library will create a default UIView with random
* color. The random color indicates that you forget something and useful when just trouble shooting the layout issue.
*/
@property (nonatomic, copy) FVViewCreateBlock objectCreationBlock;

/**
* The context will be passed into the objectCreationBlock when create the object, useful for pass
* some information
*/
@property (nonatomic, strong) NSDictionary *context;

/**
* The debug flag is not used in prod code, but useful in trouble shooting, set the flag and a conditional breakpoint helped
*/
@property (nonatomic) BOOL debug;

+(FVDeclaration *)declaration:(NSString*)name frame:(CGRect)frame;
-(FVDeclaration *)assignObject:(UIView*)object;
-(FVDeclaration *)assignObjectCreationBlock:(FVViewCreateBlock)creationBlock;
-(FVDeclaration *)withDeclarations:(NSArray*)array;
-(FVDeclaration *)Context:(NSDictionary *)context;
-(FVDeclaration *)declarationByName:(NSString*)name;

-(FVDeclaration *)Frame:(CGRect)frame;

/**
* Calculate the layout, call this before get the final loadView
*/
-(void)calculateLayout;

/**
* Get the layout calculation status
*
* @param recursive whether count child declaration in
* @return YES if all x,y,width,height calculated
*/
-(BOOL)calculated:(BOOL)recursive;

/**
* Get the fully setup loadView, it contains all the sub views.
*
* @warning: *important* When get the view, it will give up the ownership to prevent cycle pointer.
* From that point, declaration only holds a weak pointer for future usage.
*/
-(UIView *)loadView;
@end

