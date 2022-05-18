# The adapted domain in order to use popf in plansys2

This domain is an alternative to the original domain for using `popf` in PlanSys2.

We try to preserve as much as possible the compatibility between this domain and the original domain. 

We replace all `forall` conditions with some alternative non-universal conditions. 

Since `popf` does not support fluents/functions as part of the goal description, two other predicates are also added ( `(empty ?w - location)` and `(delivered-at ?k - kit ?w - workcell)`). 

**Note:** In this this domain only one kit of its type can be delivered at a work-cell (and no more kit of the same type). That means, if it is intended, for example, to deliver two `KitA` at `Workcell1`, two planning calls must happen to solve two single problems of delivering one `KitA` at `Workcell1` in each problem.
