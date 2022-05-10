# The Robotic Kitting Application

This repository contains the planning domains for a **Robotic Kitting** application. Two planning domains have been developed for problem solving. A [`full planning domain`](domain.pddl) and an [`abstract planning domain`](domain-light.pddl). The full domain provides a detailed specification and description of the application, however, the planning computation time for even slightly large problems turns out to be very complex and even intractable. The abstract domain is a light version of the full domain which can solve a same problem. however, with little detailed description, i.e., the actions for filling the kits are relaxed and abstracted in this domain.


## Contents
1. [Types](#types)
2. [The problem instance description](#the-problem-instance-description)
3. [How to specify the goal](#how-to-specify-the-goal)
4. [How to run the solver](#how-to-run-the-solver)
5. [The planner output](#the-planner-output)

## Types

The following data types are used to describe the objects in this application. 
**Note:** this is a representative data type hierarchy and it can be extended easily to include other types of objects.

```lisp
(:types 
    location graspable robot slot - object
    spot workcell storage - location
    kit_storage part_storage - storage
    part kit - graspable
    bearing bearing_housing cover locknut rotor rotor_housing screw top - part
    mobile - robot
    slot
)
```

For example the following objects are defined in the problem [`prob01.pddl`](prob01.pddl):

```lisp
(:objects 
    ; robots
    MIR1 - mobile
    Left Right - slot ; two slots for placing two kits

    ; locations 
    Kit_Storage - kit_storage
    Part_Storage - part_storage
    Workcell1 Workcell2 Workcell3 - workcell
    Spot - spot

    ; kits
    KitA KitB - kit

    ; parts 
    Bearing - bearing
    Bearing_Housing - bearing_housing
    Rotor - rotor
    Rotor_Housing - rotor_housing
    Locknut - locknut
    Screw - screw
    Cover - cover
    Top - top
)
```

## The problem instance description

### predicates
The following predicates are necessary to describe a planning problem instance.

```lisp
(route ?from ?to - location) ; there is a path between ?from and ?to locations
(robot_at ?robot - mobile ?from - location) ; robot is at a location
(has_slot_free ?robot - mobile ?slot - slot) ; robot has a free slot for carrying a kit
(has_arm_free ?m - mobile) ; the robot arm is free for manipulation
```

### fluents
The following functions (fluents) are necessary to describe a planning problem instance.

In the initial state description:

```lisp
(drive-time-pm ?r - mobile) ; to define the speed of the robot
(collect-time ?g - graspable) ; to define the collection time for an object
(deliver-time ?w - workcell) ; to define the delivery time of a kit at a workcell
(distance ?from ?to - location) ; to define the distance between locations
(location-size ?l - location) ; to define the maximum size of a location for moving robots there
(has-object ?l - location ?o - graspable) ; to define the number of objects at a location
(set-part-size ?k - kit ?p - part) ; to define the maximum number of each part in a kit
```

In the goal description:
```lisp
(deliver-at ?k - kit ?w - workcell) ; to store the number of kits delivered in a workcell
```

Please see the problem [`prob01.pddl`](prob01.pddl) as an example on how to use the above properties in a planning problem instance.

## How to specify the goal

The goal of a problem instance can be simply specified using the function `(deliver-at ?k - kit ?w - workcell)`. For example the following goal specification defines one kit of type _A_ and one kit of type _B_ to be delivered at _workcell1_ and _workcell2_.

```lisp
(= (deliver-at KitA Workcell1) 1)
(= (deliver-at KitB Workcell2) 1)
```

**Note:**

If it is intended to do not remain any kit at workcells, the following goal specification can be used:

```lisp
;; no kit will remain on workcells
(forall (?w - workcell ?k - kit)
    (and (= (has-object ?w ?k) 0)))
```

And, if it is intended to do not remain any kit at robot platforms (that means kits must be returned to kit storages), the following goal specification can be used:

```lisp
;; no kit will remain on the robot platform
(forall (?m - mobile)
    (and (has_slot_free ?m Left)
            (has_slot_free ?m Right)))
```

**Please note that the above two additional goal specification to return back the kits to kit storages increases considerably the planning computation time.**

## How to run the solver

We found two off-the-shelf PDDL solvers, [OPTIC] and [TFD - Temporal Fast Downward], that support reasoning over our domain specification. 
We implemented a python script ['solver.py'](solver.py) which runs both planners in parallel to solve a given problem within a certain computation time. Once a planner carried out the planning, the solver script reports the best found plan. However, for large problems the planners attempt to compute an optimal plan which usually takes too long time, so, the solver script terminates the planning process within the given computation time and then reports the best found plan so far.

The following command can be used to run the solvers:

```bash
# using the 'sover.py' script
python solver.py <DOMAIN> <PROBLEM> <DOMAIN> <PROBLEM> [-t <TIME>]

# for example, the default computation time is 60 seconds
python solver.py domain.pddl prob01.pddl

# or within 20 seconds computation time
python solver.py domain.pddl prob01.pddl -t 20
```

### How to run solvers independently

<!-- Two solvers already exist in the [`solvers`](solvers) folder. -->

[OPTIC]: https://nms.kcl.ac.uk/planning/software/optic.html
[TFD - Temporal Fast Downward]: http://gki.informatik.uni-freiburg.de/tools/tfd/

```bash
# using the 'optic-clp.sh' script
./solvers/optic-clp.sh <DOMAIN> <PROBLEM>
```

```bash
# using the 'tfd.sh' script
./solvers/tfd.sh <DOMAIN> <PROBLEM>
```

## The planner output

The solver script reports the best found plan within the given computation time (if any) in the terminal screen. It also translates the plan into a json format and generates a json file in the same directory of the given problem instance file.

For example the following commands will generate a json file containing a plan in json format as bellow:

```bash
python solver.py domain-light.pddl prob01.pddl
```

```json
{
    "metric": 400.703, 
    "steps": [
        "0.000", 
        "1.001", 
        "76.002", 
        "77.502", 
        "152.502", 
        "302.502", 
        "377.503"
    ], 
    "0.0": [
        {
            "action": "set_fluents", 
            "duration": 1.0, 
            "args": []
        }
    ], 
    "1.001": [
        {
            "action": "drive", 
            "duration": 75.0, 
            "args": [
                "mir1", 
                "spot", 
                "kit_storage"
            ]
        }
    ], 
    "76.002": [
        {
            "action": "take", 
            "duration": 1.5, 
            "args": [
                "mir1", 
                "kita", 
                "left", 
                "kit_storage"
            ]
        }
    ], 
    "77.502": [
        {
            "action": "drive", 
            "duration": 75.0, 
            "args": [
                "mir1", 
                "kit_storage", 
                "part_storage"
            ]
        }
    ], 
    "152.502": [
        {
            "action": "fill", 
            "duration": 150.0, 
            "args": [
                "mir1", 
                "kita", 
                "left", 
                "part_storage"
            ]
        }
    ], 
    "302.502": [
        {
            "action": "drive", 
            "duration": 75.0, 
            "args": [
                "mir1", 
                "part_storage", 
                "workcell1"
            ]
        }
    ], 
    "377.503": [
        {
            "action": "deliver", 
            "duration": 23.2, 
            "args": [
                "mir1", 
                "kita", 
                "left", 
                "workcell1"
            ]
        }
    ]
}
```