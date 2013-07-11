//
// Created by lishuo on 13-5-28.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FVDeclaration.h"

@interface FVDeclaration()
@property (nonatomic, assign) BOOL xCalculated;
@property (nonatomic, assign) BOOL yCalculated;
@property (nonatomic, assign) BOOL widthCalculated;
@property (nonatomic, assign) BOOL heightCalculated;

@property (nonatomic, assign) CGRect unExpandedFrame; // this is the original frame which not expanded.

//all the subviews managed by sub declaration
@property (nonatomic, strong) NSMutableArray *declareManagedSubview;

@property (nonatomic, copy) FVDeclarationProcessBlock postProcessBlock;

@end

@implementation FVDeclaration
@synthesize subDeclarations = _subDeclarations;
@synthesize parent = _parent;

@synthesize postProcessBlock = _postProcessBlock;

-(id)init{
    if(self = [super init]){
    }
    return self;
}

+(FVDeclaration *)declaration:(NSString*)name frame:(CGRect)frame {
    FVDeclaration *declaration = [[FVDeclaration alloc]init];
    declaration.name = name;
    declaration.frame = frame;
    return declaration;
}

-(FVDeclaration *)assignObject:(UIView*)object{
    self.object = object;
    return self;
}

-(FVDeclaration *)withDeclarations:(NSArray *)array{
    _subDeclarations = [array mutableCopy];
    [_subDeclarations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((FVDeclaration *)obj)->_parent = self;
    }];
    return self;
}

-(FVDeclaration *)declarationByName:(NSString *)name {
    if([self.name isEqualToString:name]) {
        return self;
    }
    else{
        for(FVDeclaration *declaration in _subDeclarations){
            FVDeclaration *dec = [declaration declarationByName:name];
            if(dec != nil){
                return dec;
            }
        }
    }

    return nil;
}

-(void)calculateLayout {
    if (!self.xCalculated){
        CGRect frame = self.unExpandedFrame;
        frame.origin.x = self.frame.origin.x;
        self.unExpandedFrame = frame;
    }
    if (!self.yCalculated){
        CGRect frame = self.unExpandedFrame;
        frame.origin.y = self.frame.origin.y;
        self.unExpandedFrame = frame;
    }
    if (!self.widthCalculated){
        CGRect frame = self.unExpandedFrame;
        frame.size.width = self.frame.size.width;
        self.unExpandedFrame = frame;
    }
    if (!self.heightCalculated){
        CGRect frame = self.unExpandedFrame;
        frame.size.height = self.frame.size.height;
        self.unExpandedFrame = frame;
    }

    // add sub declarations to refresh their parent node
    [self withDeclarations:_subDeclarations];

    [self calculateX];

    [self calculateWidth];

    [self calculateY];

    [self calculateHeight];

    for(FVDeclaration *declaration in _subDeclarations){
        [declaration calculateLayout];
    }
}

- (void)calculateHeight {
    if (!self.heightCalculated){
        CGFloat h = self.frame.size.height;
        if (FVIsNormal(h)){
            self.heightCalculated = YES;
        }
        else if (FVIsPercent(h)){
            if (self.parent && self.parent.heightCalculated){
                [self assignHeight: self.parent.frame.size.height * FVF2P(h)];
            }
        }
        else if(FVIsRelated(h)){
            NSAssert(self.parent, @"FVRelated: self.parent is nil");
            FVDeclaration *prev = [self.parent prevSiblingOfChild:self];
            if(prev){
                if (prev.heightCalculated) {
                    [self assignHeight: prev.frame.size.height + FVF2R(h)];
                }
                //In order to prevent deadloop, the calculation order is top down, left right rule,
                //if prev height not calculated, wait next time
            }
            else{
                [self assignHeight:FVF2R(h)];
            }
        }
        else if (FVIsTail(h)){
            NSAssert(self.parent, @"FVTail must has a valid parent, and its height already calcualted");
            if(self.parent.heightCalculated){
                [self assignHeight:self.parent.frame.size.height - FVFloat2Tail(h)];
            }
        }
        else if(FVIsFill(h)){
            NSAssert(self.parent, @"FVFill: self.parent is nil");
            FVDeclaration *next = [self.parent nextSiblingOfChild:self];
            if (next) {
                if(!next.yCalculated){
                    [next calculateLayout];
                    NSAssert(next.yCalculated, @"FVFill for height: next y must be calculated");
                    [self assignHeight: next.frame.origin.y - self.frame.origin.y];
                }
            }
            else{
                [self assignHeight:self.parent.frame.size.height - self.frame.origin.y];
            }
        }
        else if(FVIsAuto(h)){
            if (_subDeclarations && _subDeclarations.count > 0){
                CGFloat height = 0.0f;
                for(FVDeclaration *declaration in _subDeclarations){
                    [declaration calculateLayout];
                    NSAssert(declaration.yCalculated && declaration.heightCalculated, @"%@ FVAuto: y and height must calculated", self.name);
                    CGFloat bottom = declaration.frame.origin.y + declaration.frame.size.height;
                    height = height > bottom ? height : bottom;
                }
                [self assignHeight:height];
            }
            else{
                [self assignHeight:0];
            }
        }
        else if (FVIsTillEnd(h)){
            NSAssert(_parent && _parent->_heightCalculated, @"Height TillEnd requires a valid parent and its height already calculated");
            NSAssert(_yCalculated, @"Height TillEnd requires y calculated");
            [self assignHeight:_parent->_frame.size.height - _frame.origin.y];
        }
        else{
            NSAssert(NO, @"Code should not hit this place");
        }
    }
}

- (void)calculateY {
    if(!self.yCalculated){
        CGFloat y = self.frame.origin.y;
        if(FVIsNormal(y)){
            self.yCalculated = YES;
        }
        else if(FVIsPercent(y)){
            NSAssert(self.parent, @"Percent y: must have a parent");
            if(self.parent.heightCalculated){
                [self assignY:self.parent.frame.size.height * FVF2P(y)];
            }
        }
        else if(FVIsAfter(y)){
            NSAssert(self.parent, @"FVAfter must has a valid parent");
            FVDeclaration *prev = [self.parent prevSiblingOfChild:self];
            if(prev){
                if(prev.yCalculated && prev.heightCalculated){
                    [self assignY: prev.frame.origin.y + prev.frame.size.height + FVFloat2After(y)];
                }
            }
            else{
                [self assignY:FVFloat2After(y)];
            }
        }
        else if(FVIsTail(y)){
            if(self.parent && self.parent.heightCalculated){
                [self assignY:self.parent.frame.size.height - FVF2T(y)];
            }
        }
        else if(FVIsRelated(y)){
            if(self.parent){
                FVDeclaration *prev = [self.parent prevSiblingOfChild:self];
                if(prev && prev.yCalculated){
                    [self assignY: prev.frame.origin.y + FVF2R(y)];
                }
                else{
                    [self assignY:FVF2R(y)];
                }
            }
        }
        else if (FVIsCenter(y)){
            NSAssert(self.parent && self.parent.heightCalculated, @"FVCenter must has a valid parent");
            if(!self.heightCalculated){
                [self calculateHeight];
            }
            NSAssert(self.heightCalculated, @"Height must be calcuated for FVCenter Y");
            [self assignY:(self.parent.frame.size.height - self.frame.size.height)/2];
        }
        else if (FVIsAutoTail(y)){
            NSAssert(self.parent && self.parent.heightCalculated, @"FVAutoTail must has a vlid parent and height been calculated");
            if(!self.heightCalculated){
                [self calculateHeight];
            }
            NSAssert(self.heightCalculated, @"Height must be calculated for FVAutoTail Y");
            [self assignY:(self.parent.frame.size.height - self.frame.size.height)];
        }
    }
}

- (void)calculateWidth {
    if(!self.widthCalculated){
        CGFloat w = self.frame.size.width;
        if(FVIsNormal(w)){
            self.widthCalculated = YES;
        }
        else if(FVIsPercent(w)){
            if(self.parent && self.parent.widthCalculated){
                [self assignWidth: self.parent.frame.size.width * FVF2P(w)];
                self.widthCalculated = YES;
            }
        }
        else if (FVIsRelated(w)){
            FVDeclaration *prev = [self prevSibling];
            if(prev && prev.widthCalculated){
                [self assignWidth:prev.frame.size.width + FVF2R(w)];
            }
            else{
                [self assignWidth:FVF2R(w)];
            }
        }
        else if (FVIsTail(w)){
            NSAssert(self.parent, @"FVTail must has a valid parent, and its width already calcualted");
            if(self.parent.widthCalculated){
                [self assignWidth:self.parent.frame.size.width - FVF2T(w)];
            }
        }
        else if(FVIsFill(w)){
            //Need the next x's x been calculated
            FVDeclaration *next = [self nextSibling];
            if (next) {
                if(!next.xCalculated){
                    [next calculateLayout];
                }

                if(next.xCalculated){
                    [self assignWidth:next.frame.origin.x - self.frame.origin.x];
                }
            }
            else{
                [self assignWidth:self.parent.frame.size.width - self.frame.origin.x];
            }
        }
        else if(FVIsAuto(w)){
            if(_subDeclarations && _subDeclarations.count > 0){
                CGFloat width = 0.0f;
                for( FVDeclaration *declaration in _subDeclarations){
                    if(!declaration.xCalculated && !declaration.widthCalculated){
                        [declaration calculateLayout];
                    }
                    NSAssert(declaration.xCalculated && declaration.widthCalculated, @"Auto for w: sub declaration's x and width must be calculated");
                    CGFloat right = declaration.frame.origin.x + declaration.frame.size.width;
                    width = width > right ? width : right;
                }
                [self assignWidth:width];
            }
            else{
                [self assignWidth:0];
            }
        }
        else if (FVIsTillEnd(w)){
            NSAssert(_parent && _parent->_widthCalculated, @"TillEnd requires a valid parent and its width calculated");
            NSAssert(_xCalculated, @"TillEnd requires x already calculated");
            [self assignWidth:_parent->_frame.size.width - _frame.origin.x];
        }
    }
}

- (void)calculateX {
    if(!self.xCalculated){
        CGFloat x = self.frame.origin.x;
        if(FVIsNormal(x)){
            self.xCalculated = YES;
        }
        else if(FVIsPercent(x)){
            NSAssert(self.parent, @"For percent values, the parent must not be nil");
            if(self.parent.widthCalculated){
                [self assignX:self.parent.frame.size.width * FVF2P(x)];
            }
        }
        else if(FVIsFill(x)){
            NSAssert(!FVIsFill(x), @"x not support FVFill");
        }
        else if(FVIsAfter(x)){
            NSAssert(self.parent, @"FVAfter must has a valid parent");
            FVDeclaration *prev = [self.parent prevSiblingOfChild:self];
            if(prev){
                if(prev.xCalculated && prev.widthCalculated){
                    [self assignX: prev.frame.origin.x + prev.frame.size.width + FVFloat2After(x)];
                }
            }
            else{
                [self assignX:FVFloat2After(x)];
            }
        }
        else if(FVIsTail(x)){
            NSAssert(self.parent, @"FVTail must has a valid parent, and its width already calcualted");
            if(self.parent.widthCalculated){
                [self assignX: self.parent.frame.size.width - FVF2T(x)];
            }
        }
        else if(FVIsRelated(x)){
            NSAssert(self.parent, @"FVRelated must has a valid parent");
            FVDeclaration *prev = [self.parent prevSiblingOfChild:self];
            if(prev && prev.xCalculated){
                [self assignX: prev.frame.origin.x + FVF2R(x)];
            }
            else{
                [self assignX:FVF2R(x)];
            }
        }
        else if(FVIsCenter(x) || FVIsAutoTail(x)){
            NSAssert(self.parent && self.parent.widthCalculated, @"FVCenter or FVAutoTail must has a valid parent and width calcluated");
            //note: caution, if width needs x, and x needs width, dead lock occur
            if(!self.widthCalculated){
                [self calculateWidth];
            }
            NSAssert(self.widthCalculated, @"the width should be calcualted when FVCenter specified");

            if(FVIsCenter(x)){
                [self assignX: (self.parent.frame.size.width - self.frame.size.width)/2 ];
            }
            else if(FVIsAutoTail(x)){
                [self assignX:(self.parent.frame.size.width - self.frame.size.width)];
            }
        }
    }
}

-(FVDeclaration *)nextSiblingOfChild:(FVDeclaration *)declaration{
    NSUInteger index = [_subDeclarations indexOfObject:declaration];
    if(index != NSNotFound && index + 1 < _subDeclarations.count){
        return _subDeclarations[index+1];
    }
    return nil;
}

-(FVDeclaration *)prevSiblingOfChild:(FVDeclaration *)declaration{
    NSUInteger index = [_subDeclarations indexOfObject:declaration];
    if(index != NSNotFound && index > 0){
        return _subDeclarations[index-1];
    }
    return nil;
}

-(FVDeclaration *)prevSibling{
    if(self.parent){
        return [self.parent prevSiblingOfChild:self];
    }
    return nil;
}

-(FVDeclaration *)nextSibling{
    if(self.parent){
        return [self.parent nextSiblingOfChild:self];
    }
    return nil;
}

-(void)assignWidth:(CGFloat)width{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
    self.widthCalculated = YES;
}

-(void)assignX:(CGFloat)x{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
    self.xCalculated = YES;
}

-(void)assignY:(CGFloat)y{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
    self.yCalculated = YES;
}

-(void)assignHeight:(CGFloat)height{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
    self.heightCalculated = YES;
}


-(BOOL)calculated:(BOOL)recursive {

    if (!self.xCalculated || !self.yCalculated || !self.widthCalculated || !self.heightCalculated){
        return NO;
    }
    if(recursive){
        for(FVDeclaration *declaration in _subDeclarations){
            if(![declaration calculated:recursive]){
                return NO;
            }
        }
    }

    return YES;
}

-(UIView*)loadView {
    [self fillView:nil offsetFrame:CGRectZero];
    return _object;
}

-(void)fillView:(UIView *)superView offsetFrame:(CGRect)frame{
    if (![self calculated:NO]){
        [self calculateLayout];
    }

    CGRect myFrame = CGRectOffset(_frame, frame.origin.x, frame.origin.y);
    if(_object != nil && !CGRectEqualToRect(_object.frame, myFrame)){
        _object.frame = myFrame;
    }

    if(superView != nil && _object != nil){
        [_object removeFromSuperview];
        [superView addSubview:_object];
    }

    CGRect subviewBaseOnFrame = myFrame;
    UIView *subviewAddIntoView = superView;
    if (_object != nil){
        subviewBaseOnFrame = CGRectZero;
        subviewAddIntoView = _object;
    }

    for(FVDeclaration *declaration in _subDeclarations){
        [declaration fillView:subviewAddIntoView offsetFrame:subviewBaseOnFrame];
    }

    if (_postProcessBlock){
        _postProcessBlock(self);
    }
}

-(FVDeclaration *)assignFrame:(CGRect)frame{
    self.frame = frame;
    return self;
}

-(FVDeclaration *)process:(FVDeclarationProcessBlock)processBlock {
    processBlock(self);
    return self;
}

-(void)resetLayout {
    [self resetLayoutWithDepth:INT32_MAX];
}


-(void)resetLayoutWithDepth:(int)depth {
    if (depth <= 0){
        return;
    }
    else if(depth >= 1){
        // restore the frame to the original one, doing this will discard all the changes made
        // So in order to update the frame, one should call reset layout first, then set new frame
        CGRect originalFrame = self.frame;
        if(_xCalculated){
            originalFrame.origin.x = self.unExpandedFrame.origin.x;
        }
        if(_yCalculated){
            originalFrame.origin.y = self.unExpandedFrame.origin.y;
        }
        if(_widthCalculated){
            originalFrame.size.width = self.unExpandedFrame.size.width;
        }
        if(_heightCalculated){
            originalFrame.size.height = self.unExpandedFrame.size.height;
        }

        _xCalculated = NO;
        _yCalculated = NO;
        _widthCalculated = NO;
        _heightCalculated = NO;

        self.frame = originalFrame;

        if(depth > 1){
            for (FVDeclaration *declaration in _subDeclarations){
                [declaration resetLayoutWithDepth:depth-1];
            }
        }
    }
}

-(FVDeclaration *)appendDeclaration:(FVDeclaration *)declaration {
    NSMutableArray *subDeclarations = [NSMutableArray arrayWithArray:_subDeclarations];
    [subDeclarations addObject:declaration];
    _subDeclarations = subDeclarations;
    declaration->_parent = self;
    return self;
}

-(void)removeDeclaration:(FVDeclaration*)declaration{
    NSMutableArray *array = [NSMutableArray arrayWithArray:_subDeclarations];
    [array removeObject:declaration];
    _subDeclarations = array;
}

-(void)removeFromParentDeclaration {
    [self.parent removeDeclaration:self];
    [_object removeFromSuperview];
    _parent = nil;
}

- (FVDeclaration *)postProcess:(FVDeclarationProcessBlock)processBlock {
    _postProcessBlock = processBlock;
    return self;
}
@end
