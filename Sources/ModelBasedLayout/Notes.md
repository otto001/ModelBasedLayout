Layout transition order of operation (especially important for for working with sticky headers)

prepare new layout (called twice for some reason)
old layout returns old attrs (called from setCollectionViewLayout)
new layout returns new (but not necessarily final) attrs (called from setCollectionViewLayout)

old layout returns new, final attrs in final layout call (called from setCollectionViewLayout / doubleSidedAnimation)
     uses: new layout returns new, final attrs

new layout returns old attrs in initial layout call (called from setCollectionViewLayout / doubleSidedAnimation)
     uses: old layout returns old attrs in layout call

new layout returns new, final attrs in layout call (after animation completes)

Result:
 Animation A: old layout -> old final
 Animation B: new inital -> new layout

Issue: Animation A & B are not identical
Solution 1: Hide Animation B by setting isHidden = true
Solution 2: Hide Animation B by setting isHidden = true (does not work properly for some reason)
