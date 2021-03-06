using OctTrees
import OctTrees: modify, stop_cond
using GeometricalPredicates
import GeometricalPredicates:getx, gety, getz
using Test


##################################################################
#
#   testing QUADTREES
#
##################################################################

q=QuadTree(100)

OctTrees.insert!(q, Point(0.1, 0.1))
OctTrees.insert!(q, Point(0.9, 0.9))

@test q.number_of_nodes_used == 5

q=QuadTree(100)

OctTrees.insert!(q, Point(0.1, 0.1))
OctTrees.insert!(q, Point(0.9, 0.9))

tot=0
for i in 1:q.number_of_nodes_used
    !isfullleaf(q.nodes[i]) && continue
    global tot+=1
end
@test tot == 2


@test !q.head.lxhy.is_divided
@test q.head.lxhy.is_empty
@test !q.head.hxly.is_divided
@test q.head.hxly.is_empty
@test !q.head.lxly.is_divided
@test !q.head.lxly.is_empty
@test !q.head.hxhy.is_divided
@test !q.head.hxhy.is_empty
@test q.head.is_divided
@test q.head.is_empty

OctTrees.insert!(q, Point(0.55, 0.9))

@test !q.head.hxhy.hxhy.is_divided
@test !q.head.hxhy.hxhy.is_empty
@test !q.head.hxhy.lxhy.is_divided
@test !q.head.hxhy.lxhy.is_empty
@test !q.head.hxhy.lxly.is_divided
@test q.head.hxhy.lxly.is_empty
@test !q.head.hxhy.hxly.is_divided
@test q.head.hxhy.hxly.is_empty

OctTrees.insert!(q, Point(0.9, 0.55))

@test !q.head.hxhy.hxhy.is_divided
@test !q.head.hxhy.hxhy.is_empty
@test !q.head.hxhy.lxhy.is_divided
@test !q.head.hxhy.lxhy.is_empty
@test !q.head.hxhy.lxly.is_divided
@test q.head.hxhy.lxly.is_empty
@test !q.head.hxhy.hxly.is_divided
@test !q.head.hxhy.hxly.is_empty

##################################################################

struct Part <: AbstractPoint2D
	_x::Float64
	_y::Float64
	Part(x,y) = new(x,y)
end
Part() = Part(0., 0.)
getx(p::Part) = p._x
gety(p::Part) = p._y

q=QuadTree(Part; n=4000100)

pa = [Part(rand(), rand()) for i in 1:1000000]
function insert_unsorted_array(pa::Array{Part,1}, q::QuadTree)
	for p in pa
		OctTrees.insert!(q, p)
	end
end


@time insert_unsorted_array(pa,q)

##################################################################

pa = [Point(rand(), rand()) for i in 1:1000000]
function insert_unsorted_array(pa::Array{Point2D,1}, q::QuadTree)
	for p in pa
		OctTrees.insert!(q, p)
	end
end
q=QuadTree(4000100)
@time insert_unsorted_array(pa,q)
clear!(q)
@time insert_unsorted_array(pa,q)



# a massive particle
struct Particle <: AbstractPoint2D
	_x::Float64
	_y::Float64
	_m::Float64
	Particle(x,y,m) = new(x,y,m)
end
Particle(x::Float64, y::Float64) = Particle(x, y, 1.)
Particle() = Particle(0., 0., 0.)
getx(p::Particle) = p._x
gety(p::Particle) = p._y

q=QuadTree(Particle; n=100)

function modify(q::QuadTreeNode{Particle}, p::Particle)
	total_mass = q.point._m + p._m
	newx = (q.point._x*q.point._m + p._x)/total_mass
	newy = (q.point._y*q.point._m + p._y)/total_mass
	q.point = Particle(newx, newy, total_mass)
end

@test q.head.is_empty == true

OctTrees.insert!(q, Particle(0.1, 0.1), Modify)

@test q.head.is_empty == false
@test q.head.point._m == 1.0
@test q.head.point._x == 0.1
@test q.head.point._y == 0.1

OctTrees.insert!(q, Particle(0.9, 0.9), Modify)

@test q.head.is_empty == true
@test q.head.point._m == 2.0
@test q.head.point._x == (0.1+0.9)/2
@test q.head.point._y == (0.1+0.9)/2
@test q.head.lxly.point._m == 1.0
@test q.head.lxly.point._x == 0.1
@test q.head.lxly.point._y == 0.1
@test q.head.hxhy.point._m == 1.0
@test q.head.hxhy.point._x == 0.9
@test q.head.hxhy.point._y == 0.9

cond_satisfied = false
function stop_cond(q::QuadTreeNode{Particle}, cond_data::Int64)
	q.point._m <= 1.1 && return false
	global cond_satisfied = true
	@test q.point._m == 2.0
	@test cond_data==1
	true
end

OctTrees.map(q, 1)

@test cond_satisfied == true

float_cond_satisfied = false
function stop_cond(q::QuadTreeNode{Particle}, cond_data::Float64)
	q.point._m <= 1.1 && return false
	global float_cond_satisfied = true
	@test q.point._m == 2.0
	@test cond_data==1.0
	true
end

OctTrees.map(q, 1.0)

@test float_cond_satisfied == true

nodata_cond_satisfied = false
function stop_cond(q::QuadTreeNode{Particle})
	q.point._m <= 1.1 && return false
	global nodata_cond_satisfied = true
	@test q.point._m == 2.0
	true
end

OctTrees.map(q)

@test nodata_cond_satisfied == true

q=QuadTree(Particle; n=100)

function modify(q::QuadTreeNode{Particle}, p::Particle, i::Int64)
	@test i==1
	q.point = Particle(q.point._x, q.point._y, 7.0)
end

OctTrees.insert!(q, Particle(0.1, 0.1), 1)
OctTrees.insert!(q, Particle(0.9, 0.9), 1)
@test q.head.point._m == 7.0


N = 10000
q=QuadTree()
for i in 1:N
	OctTrees.insert!(q, Point(rand(), rand()))
end
tot=0
for i in 1:q.number_of_nodes_used
    !isfullleaf(q.nodes[i]) && continue
    global tot+=1
end
@test tot == N


##################################################################
#
#   testing OCTTREES
#
##################################################################

q = OctTree(100)

OctTrees.insert!(q, Point(0.1, 0.1, 0.1))
OctTrees.insert!(q, Point(0.9, 0.9, 0.9))

@test q.number_of_nodes_used == 9

q = OctTree(100)

OctTrees.insert!(q, Point(0.1, 0.1, 0.1))
OctTrees.insert!(q, Point(0.9, 0.9, 0.9))

tot=0
for i in 1:q.number_of_nodes_used
    !isfullleaf(q.nodes[i]) && continue
    global tot+=1
end
@test tot == 2


@test !q.head.lxlylz.is_divided
@test !q.head.lxlylz.is_empty
@test !q.head.lxlyhz.is_divided
@test q.head.lxlyhz.is_empty
@test !q.head.lxhylz.is_divided
@test q.head.lxhylz.is_empty
@test !q.head.lxhyhz.is_divided
@test q.head.lxhyhz.is_empty
@test !q.head.hxlylz.is_divided
@test q.head.hxlylz.is_empty
@test !q.head.hxlyhz.is_divided
@test q.head.hxlyhz.is_empty
@test !q.head.hxhylz.is_divided
@test q.head.hxhylz.is_empty
@test !q.head.hxhyhz.is_divided
@test !q.head.hxhyhz.is_empty
@test q.head.is_divided
@test q.head.is_empty

OctTrees.insert!(q, Point(0.55, 0.9, 0.9))

@test !q.head.hxhyhz.hxhyhz.is_divided
@test !q.head.hxhyhz.hxhyhz.is_empty
@test !q.head.hxhyhz.lxhyhz.is_divided
@test !q.head.hxhyhz.lxhyhz.is_empty
@test !q.head.hxhyhz.lxlyhz.is_divided
@test q.head.hxhyhz.lxlyhz.is_empty
@test !q.head.hxhyhz.hxlyhz.is_divided
@test q.head.hxhyhz.hxlyhz.is_empty

OctTrees.insert!(q, Point(0.9, 0.55, 0.9))

@test !q.head.hxhyhz.hxhyhz.is_divided
@test !q.head.hxhyhz.hxhyhz.is_empty
@test !q.head.hxhyhz.lxhyhz.is_divided
@test !q.head.hxhyhz.lxhyhz.is_empty
@test !q.head.hxhyhz.lxlyhz.is_divided
@test q.head.hxhyhz.lxlyhz.is_empty
@test !q.head.hxhyhz.hxlyhz.is_divided
@test !q.head.hxhyhz.hxlyhz.is_empty

##################################################################

struct Part3D <: AbstractPoint3D
	_x::Float64
	_y::Float64
	_z::Float64
	Part3D(x,y,z) = new(x,y,z)
end
Part3D() = Part3D(0., 0., 0.)
getx(p::Part3D) = p._x
gety(p::Part3D) = p._y
getz(p::Part3D) = p._z

q=OctTree(Part3D; n=4000100)

pa = [Part3D(rand(), rand(), rand()) for i in 1:1000000]
function insert_unsorted_array(pa::Array{Part3D,1}, q::OctTree)
	for p in pa
		OctTrees.insert!(q, p)
	end
end


@time insert_unsorted_array(pa,q)

##################################################################

pa = [Point(rand(), rand(), rand()) for i in 1:1000000]
function insert_unsorted_array(pa::Array{Point3D,1}, q::OctTree)
	for p in pa
		OctTrees.insert!(q, p)
	end
end
q=OctTree(4000100)
@time insert_unsorted_array(pa,q)
clear!(q)
@time insert_unsorted_array(pa,q)



# a massive particle
struct Particle3D <: AbstractPoint3D
	_x::Float64
	_y::Float64
	_z::Float64
	_m::Float64
	Particle3D(x,y,z,m) = new(x,y,z,m)
end
Particle3D(x::Float64, y::Float64, z::Float64) = Particle3D(x, y, z, 1.)
Particle3D() = Particle3D(0., 0., 0., 0.)
getx(p::Particle3D) = p._x
gety(p::Particle3D) = p._y
getz(p::Particle3D) = p._z

q=OctTree(Particle3D; n=100)

function modify(q::OctTreeNode{Particle3D}, p::Particle3D)
	total_mass = q.point._m + p._m
	newx = (q.point._x*q.point._m + p._x)/total_mass
	newy = (q.point._y*q.point._m + p._y)/total_mass
	newz = (q.point._z*q.point._m + p._z)/total_mass
	q.point = Particle3D(newx, newy, newz, total_mass)
end

@test q.head.is_empty == true

OctTrees.insert!(q, Particle3D(0.1, 0.1, 0.1), Modify)

@test q.head.is_empty == false
@test q.head.point._m == 1.0
@test q.head.point._x == 0.1
@test q.head.point._y == 0.1
@test q.head.point._z == 0.1

OctTrees.insert!(q, Particle3D(0.9, 0.9, 0.9), Modify)

@test q.head.is_empty == true
@test q.head.point._m == 2.0
@test q.head.point._x == (0.1+0.9)/2
@test q.head.point._y == (0.1+0.9)/2
@test q.head.point._z == (0.1+0.9)/2

cond_satisfied = false
function stop_cond(q::OctTreeNode{Particle3D}, cond_data::Int64)
	q.point._m <= 1.1 && return false
	global cond_satisfied = true
	@test q.point._m == 2.0
	@test cond_data==1
	true
end

OctTrees.map(q, 1)

@test cond_satisfied == true

float_cond_satisfied = false
function stop_cond(q::OctTreeNode{Particle3D}, cond_data::Float64)
	q.point._m <= 1.1 && return false
	global float_cond_satisfied = true
	@test q.point._m == 2.0
	@test cond_data==1.0
	true
end

OctTrees.map(q, 1.0)

@test float_cond_satisfied == true

nodata_cond_satisfied = false
function stop_cond(q::OctTreeNode{Particle3D})
	q.point._m <= 1.1 && return false
	global nodata_cond_satisfied = true
	@test q.point._m == 2.0
	true
end

OctTrees.map(q)

@test nodata_cond_satisfied == true

q=OctTree(Particle3D; n=100)

function modify(q::OctTreeNode{Particle3D}, p::Particle3D, i::Int64)
	@test i==1
	q.point = Particle3D(q.point._x, q.point._y, q.point._z, 7.0)
end

OctTrees.insert!(q, Particle3D(0.1, 0.1, 0.1), 1)
OctTrees.insert!(q, Particle3D(0.9, 0.9, 0.9), 1)
@test q.head.point._m == 7.0


N = 10000
q=OctTree()
for i in 1:N
	OctTrees.insert!(q, Point(rand(), rand(), rand()))
end
tot=0
for i in 1:q.number_of_nodes_used
    !isfullleaf(q.nodes[i]) && continue
    global tot+=1
end
@test tot == N

#################################################################
#
#   Testing CompiledOctTrees
#
################################################################

N = 10000
q=OctTree()
for i in 1:N
	OctTrees.insert!(q, Point(rand(), rand(), rand()))
end

c = CompiledOctTree(N, Point3D)
compile!(c, q)

for iter in 1:5
    total_number_of_particles=0
    for i in 1:c.number_of_nodes_used
        c.nodes[i].l > 0.0 && continue # not a leaf
        total_number_of_particles += 1
    end
    @test total_number_of_particles == N

    for i in 1:q.number_of_nodes_used
        n = q.nodes[i]
        if isemptyleaf(n)
            @test n.id <= 0
            continue
         end
        @test n.id > 0
        @test n.id <= c.number_of_nodes_used
        @test n.point._x == c.nodes[n.id].point._x
        @test n.point._y == c.nodes[n.id].point._y
        @test n.point._z == c.nodes[n.id].point._z
        if isleaf(n)
            @test c.nodes[n.id].l == -1.0
        else
            @test 2.0*n.r == c.nodes[n.id].l
        end
    end

    v=zeros(Int64, c.number_of_nodes_used)
    for i in 1:q.number_of_nodes_used
        if q.nodes[i].id>0
            v[q.nodes[i].id] = 1
        end
    end
    @test sum(v) == c.number_of_nodes_used

    for i in 1:q.number_of_nodes_used
        n = q.nodes[i]
        !n.is_divided && continue

        !isemptyleaf(n.lxlylz) && @test c.nodes[n.lxlylz.id].next == -1

        !isemptyleaf(n.lxlylz) && !isemptyleaf(n.lxlyhz) &&
            @test c.nodes[n.lxlyhz.id].next == n.lxlylz.id
        !isemptyleaf(n.hxlyhz) && !isemptyleaf(n.hxlylz) &&
            @test c.nodes[n.hxlyhz.id].next == n.hxlylz.id
        !isemptyleaf(n.hxhyhz) && !isemptyleaf(n.hxhylz) &&
            @test c.nodes[n.hxhyhz.id].next == n.hxhylz.id
    end

    clear!(q)
    for i in 1:N
    	OctTrees.insert!(q, Point(rand(), rand(), rand()))
    end
    compile!(c, q)
end
