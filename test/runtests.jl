using OctTrees
using Base.Test

q=QuadTree()
insert!(q, Point(0.1, 0.1))
insert!(q, Point(0.9, 0.9))

@test !q.lxly.is_divided
@test !q.lxly.is_empty
@test !q.hxhy.is_divided
@test !q.hxhy.is_empty
@test q.lxly.is_divided
@test q.lxly.is_empty

