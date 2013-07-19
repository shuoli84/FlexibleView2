//
// Created by lishuo on 13-5-28.
// Copyright (c) 2013 ___FULLUSERNAME___. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "FVDeclaration.h"
#import "NSArray+BlocksKit.h"

@interface FVDeclaration()


@property (nonatomic, assign) BOOL xCalculated;
@property (nonatomic, assign) BOOL yCalculated;
@property (nonatomic, assign) BOOL widthCalculated;
@property (nonatomic, assign) BOOL heightCalculated;
@property (nonatomic, assign) CGRect unExpandedFrame; // this is the original frame which not expanded.
@property (nonatomic, strong) NSMutableArray *postProcessBlocks;
@end

@implementation FVDeclaration{
    NSMutableArray *_subDeclarations;
}
@synthesize parent = _parent;

-(id)init{
    if(self = [super init]){
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    FVDeclaration *dec = [[FVDeclaration alloc] init];
    dec->_frame = _frame;
    dec->_name = [_name copy];
    dec->_postProcessBlocks = [_postProcessBlocks copy];
    dec->_object = _object; //Object is shared even in copied declare.

    dec->_xCalculated = _xCalculated;
    dec->_yCalculated = _yCalculated;
    dec->_widthCalculated = _widthCalculated;
    dec->_heightCalculated = _heightCalculated;
    dec->_unExpandedFrame = _unExpandedFrame;

    dec->_subDeclarations = [NSMutableArray arrayWithCapacity:_subDeclarations.count];
    [_subDeclarations each:^(FVDeclaration* d) {
        [dec appendDeclaration:[d copyWithZone:zone]];
    }];
    return dec;
}

+(FVDeclaration *)declaration:(NSString*)name frame:(CGRect)frame {
    FVDeclaration *declaration = [[FVDeclaration alloc]init];
    declaration->_name = name;
    declaration->_frame = frame;
    return declaration;
}

-(FVDeclaration *)assignObject:(UIView*)object{
    _object = object;
    return self;
}

-(FVDeclaration *)withDeclarations:(NSArray *)array{
    _subDeclarations = [array mutableCopy];
    [_subDeclarations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((FVDeclaration *)obj)->_parent = self;
    }];
    return self;
}

-(NSArray *)subDeclarations {
    return _subDeclarations;
}

-(FVDeclaration *)declarationByName:(NSString *)name {
    if([_name isEqualToString:name]) {
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
    if (!_xCalculated){
        CGRect frame = _unExpandedFrame;
        frame.origin.x = _frame.origin.x;
        _unExpandedFrame = frame;
    }
    if (!_yCalculated){
        CGRect frame = _unExpandedFrame;
        frame.origin.y = _frame.origin.y;
        _unExpandedFrame = frame;
    }
    if (!_widthCalculated){
        CGRect frame = _unExpandedFrame;
        frame.size.width = _frame.size.width;
        _unExpandedFrame = frame;
    }
    if (!_heightCalculated){
        CGRect frame = _unExpandedFrame;
        frame.size.height = _frame.size.height;
        _unExpandedFrame = frame;
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
    if (!_heightCalculated){
        CGFloat h = _frame.size.height;
        if (FVIsNormal(h)){
            _heightCalculated = YES;
        }
        else if (FVIsPercent(h)){
            if (_parent && _parent.heightCalculated){
                [self assignHeight: _parent->_frame.size.height * FVF2P(h)];
            }
        }
        else if(FVIsRelated(h)){
            NSAssert(_parent, @"%@ FVRelated: parent is nil", _name);
            FVDeclaration *prev = [_parent prevSiblingOfChild:self];
            if(prev){
                if (prev->_heightCalculated) {
                    [self assignHeight: prev->_frame.size.height + FVF2R(h)];
                }
                //In order to prevent deadloop, the calculation order is top down, left right rule,
                //if prev height not calculated, wait next time
            }
            else{
                [self assignHeight:FVF2R(h)];
            }
        }
        else if (FVIsTail(h)){
            NSAssert(_parent, @"%@ FVTail must has a valid parent, and its height already calcualted", _name);
            if(_parent.heightCalculated){
                [self assignHeight:_parent->_frame.size.height - FVFloat2Tail(h)];
            }
        }
        else if(FVIsFill(h)){
            NSAssert(_parent, @"FVFill: parent is nil");
            FVDeclaration *next = [_parent nextSiblingOfChild:self];
            if (next) {
                if(!next.yCalculated){
                    [next calculateLayout];
                    NSAssert(next.yCalculated, @"FVFill for height: next y must be calculated");
                    [self assignHeight: next.frame.origin.y - _frame.origin.y];
                }
            }
            else{
                [self assignHeight:_parent.frame.size.height - _frame.origin.y];
            }
        }
        else if(FVIsAuto(h)){
            if (_subDeclarations && _subDeclarations.count > 0){
                CGFloat height = 0.0f;
                for(FVDeclaration *declaration in _subDeclarations){
                    [declaration calculateLayout];
                    NSAssert(declaration.yCalculated && declaration.heightCalculated, @"%@ FVAuto: y and height must calculated", _name);
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
    if(!_yCalculated){
        CGFloat y = _frame.origin.y;
        if(FVIsNormal(y)){
            _yCalculated = YES;
        }
        else if(FVIsPercent(y)){
            NSAssert(_parent, @"Percent y: must have a parent");
            if(_parent.heightCalculated){
                [self assignY:_parent.frame.size.height * FVF2P(y)];
            }
        }
        else if(FVIsAfter(y)){
            NSAssert(_parent, @"FVAfter must has a valid parent");
            FVDeclaration *prev = [_parent prevSiblingOfChild:self];
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
            if(_parent && _parent.heightCalculated){
                [self assignY:_parent.frame.size.height - FVF2T(y)];
            }
        }
        else if(FVIsRelated(y)){
            if(_parent){
                FVDeclaration *prev = [_parent prevSiblingOfChild:self];
                if(prev && prev.yCalculated){
                    [self assignY: prev.frame.origin.y + FVF2R(y)];
                }
                else{
                    [self assignY:FVF2R(y)];
                }
            }
        }
        else if (FVIsCenter(y)){
            NSAssert(_parent && _parent.heightCalculated, @"FVCenter must has a valid parent");
            if(!_heightCalculated){
                [self calculateHeight];
            }
            NSAssert(_heightCalculated, @"Height must be calcuated for FVCenter Y");
            [self assignY:(_parent.frame.size.height - _frame.size.height)/2];
        }
        else if (FVIsAutoTail(y)){
            NSAssert(_parent && _parent.heightCalculated, @"FVAutoTail must has a vlid parent and height been calculated");
            if(!_heightCalculated){
                [self calculateHeight];
            }
            NSAssert(_heightCalculated, @"Height must be calculated for FVAutoTail Y");
            [self assignY:(_parent.frame.size.height - _frame.size.height)];
        }
    }
}

- (void)calculateWidth {
    if(!_widthCalculated){
        CGFloat w = _frame.size.width;
        if(FVIsNormal(w)){
            _widthCalculated = YES;
        }
        else if(FVIsPercent(w)){
            if(_parent && _parent.widthCalculated){
                [self assignWidth: _parent.frame.size.width * FVF2P(w)];
                _widthCalculated = YES;
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
            NSAssert(_parent, @"FVTail must has a valid parent, and its width already calcualted");
            if(_parent.widthCalculated){
                [self assignWidth:_parent.frame.size.width - FVF2T(w)];
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
                    [self assignWidth:next.frame.origin.x - _frame.origin.x];
                }
            }
            else{
                [self assignWidth:_parent.frame.size.width - _frame.origin.x];
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
    if(!_xCalculated){
        CGFloat x = _frame.origin.x;
        if(FVIsNormal(x)){
            _xCalculated = YES;
        }
        else if(FVIsPercent(x)){
            NSAssert(_parent, @"For percent values, the parent must not be nil");
            if(_parent.widthCalculated){
                [self assignX:_parent.frame.size.width * FVF2P(x)];
            }
        }
        else if(FVIsFill(x)){
            NSAssert(!FVIsFill(x), @"x not support FVFill");
        }
        else if(FVIsAfter(x)){
            NSAssert(_parent, @"FVAfter must has a valid parent");
            FVDeclaration *prev = [_parent prevSiblingOfChild:self];
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
            NSAssert(_parent, @"FVTail must has a valid parent, and its width already calcualted");
            if(_parent.widthCalculated){
                [self assignX: _parent.frame.size.width - FVF2T(x)];
            }
        }
        else if(FVIsRelated(x)){
            NSAssert(_parent, @"FVRelated must has a valid parent");
            FVDeclaration *prev = [_parent prevSiblingOfChild:self];
            if(prev && prev.xCalculated){
                [self assignX: prev.frame.origin.x + FVF2R(x)];
            }
            else{
                [self assignX:FVF2R(x)];
            }
        }
        else if(FVIsCenter(x) || FVIsAutoTail(x)){
            NSAssert(_parent && _parent.widthCalculated, @"FVCenter or FVAutoTail must has a valid parent and width calcluated");
            //note: caution, if width needs x, and x needs width, dead lock occur
            if(!_widthCalculated){
                [self calculateWidth];
            }
            NSAssert(_widthCalculated, @"the width should be calcualted when FVCenter specified");

            if(FVIsCenter(x)){
                [self assignX: (_parent.frame.size.width - _frame.size.width)/2 ];
            }
            else if(FVIsAutoTail(x)){
                [self assignX:(_parent.frame.size.width - _frame.size.width)];
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
    if(_parent){
        return [_parent prevSiblingOfChild:self];
    }
    return nil;
}

-(FVDeclaration *)nextSibling{
    if(_parent){
        return [_parent nextSiblingOfChild:self];
    }
    return nil;
}

-(void)assignWidth:(CGFloat)width{
    CGRect frame = _frame;
    frame.size.width = width;
    _frame = frame;
    _widthCalculated = YES;
}

-(void)assignX:(CGFloat)x{
    CGRect frame = _frame;
    frame.origin.x = x;
    _frame = frame;
    _xCalculated = YES;
}

-(void)assignY:(CGFloat)y{
    CGRect frame = _frame;
    frame.origin.y = y;
    _frame = frame;
    _yCalculated = YES;
}

-(void)assignHeight:(CGFloat)height{
    CGRect frame = _frame;
    frame.size.height = height;
    _frame = frame;
    _heightCalculated = YES;
}


-(BOOL)calculated:(BOOL)recursive {

    if (!_xCalculated || !_yCalculated || !_widthCalculated || !_heightCalculated){
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
    [self fillView:nil];
    return _object;
}

-(void)fillView:(UIView *)superView{
    FVDeclaration *wrapperDeclare = self;
    if(superView){
        wrapperDeclare = [FVDeclaration declaration:@"wrapper" frame:superView.bounds];
        [wrapperDeclare appendDeclaration:self];
    }
    [wrapperDeclare updateViewFrame];
    [self setupViewTreeInto:superView];
}

-(void)setupViewTreeInto:(UIView *)superView{
    if(superView != nil && _object != nil){
        [_object removeFromSuperview];
        [superView addSubview:_object];
    }

    UIView *subviewAddIntoView = superView;
    if (_object != nil){
        subviewAddIntoView = _object;
    }

    for(FVDeclaration *declaration in _subDeclarations){
        [declaration setupViewTreeInto:subviewAddIntoView];
    }
}

-(void)updateViewFrame{
    //Find this node's offset frame
    CGPoint offsetPoint = CGPointZero;
    FVDeclaration *dec = _parent;
    while(dec && dec.object == nil){
        NSAssert([dec calculated:NO], @"The parent's layout has to be calculated when call updateView frame in sub declaration");
        offsetPoint.x += dec.frame.origin.x;
        offsetPoint.y += dec.frame.origin.y;
        dec = dec.parent;
    }

    [self updateViewFrameInternalWithOffsetFrame:CGRectMake(offsetPoint.x, offsetPoint.y, 0, 0)];
}

-(void)updateViewFrameInternalWithOffsetFrame:(CGRect)offsetFrame{
    if (![self calculated:NO]){
        [self calculateLayout];
    }

    CGRect myFrame = CGRectOffset(_frame, offsetFrame.origin.x, offsetFrame.origin.y);

    if(_object != nil && !CGRectEqualToRect(_object.frame, myFrame)){
        _object.frame = myFrame;
    }

    CGRect subviewBaseOnFrame = myFrame;
    if (_object != nil){
        subviewBaseOnFrame = CGRectZero;
    }
    for(FVDeclaration *declaration in _subDeclarations){
        [declaration updateViewFrameInternalWithOffsetFrame:subviewBaseOnFrame];
    }

    for(FVDeclarationProcessBlock block in _postProcessBlocks){
        block(self);
    }
}

-(FVDeclaration *)assignFrame:(CGRect)frame{
    _frame = frame;
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
        CGRect originalFrame = _frame;
        if(_xCalculated){
            originalFrame.origin.x = _unExpandedFrame.origin.x;
        }
        if(_yCalculated){
            originalFrame.origin.y = _unExpandedFrame.origin.y;
        }
        if(_widthCalculated){
            originalFrame.size.width = _unExpandedFrame.size.width;
        }
        if(_heightCalculated){
            originalFrame.size.height = _unExpandedFrame.size.height;
        }

        _xCalculated = NO;
        _yCalculated = NO;
        _widthCalculated = NO;
        _heightCalculated = NO;

        _frame = originalFrame;

        if(depth > 1){
            for (FVDeclaration *declaration in _subDeclarations){
                [declaration resetLayoutWithDepth:depth-1];
            }
        }
    }
}

-(FVDeclaration *)appendDeclaration:(FVDeclaration *)declaration {
    if(_subDeclarations == nil){
        _subDeclarations = [NSMutableArray array];
    }
    [_subDeclarations addObject:declaration];
    declaration->_parent = self;
    return self;
}

-(void)removeDeclaration:(FVDeclaration*)declaration{
    [_subDeclarations removeObject:declaration];
}

-(void)removeFromParentDeclaration {
    [_parent removeDeclaration:self];
    [_object removeFromSuperview];
    _parent = nil;
}

- (FVDeclaration *)postProcess:(FVDeclarationProcessBlock)processBlock {
    if(_postProcessBlocks == nil){
        _postProcessBlocks = [NSMutableArray array];
    }
    [_postProcessBlocks addObject:[processBlock copy]];
    return self;
}
@end
