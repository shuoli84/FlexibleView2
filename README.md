FlexibleView2
=============

FlexibleView is a library which helps you layout subviews without pain of calculating the frame. 
e.g, now you can do things in this way:
[[FVDeclaration declaration:@"root" frame:CGRectMake(0, 0, FVP(1), FVP(1)] withDeclarations:@[
    [FVDeclaration declaration:@"sideBar" frame:CGRectMake(0, 0, 44, FVP(1)],... //the side bar is 44 width, and height 100% of its parent height
    [FVDeclaration declaration:@"topBar" frame:CGRectMake(FVAfter(0), 0, FVTillEnd, 44],... //the topbar's x right after the prev node and the width fill the parent width
    [FVDeclaration declaration:@"centerStuff", frame:CGRectMake(FVCenter, FVCenter, 40, 40)],...//the center stuff will locate right in center of parent view
]]

