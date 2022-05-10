; using only one robot

(define (problem prob1) (:domain kitting)
(:objects 
    ; robots
    MIR1 - mobile
    Left Right - slot ; each robot has two slots for placing two kits

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

(:init
    ; robot1
    (= (drive-time-pm MIR1) 1.5)
    (robot_at MIR1 Spot)
    (has_arm_free MIR1)
    (has_slot_free MIR1 Left)
    (has_slot_free MIR1 Right)

    ; parts sizes at different storages
    (= (has-object Kit_Storage KitA) 100)
    (= (has-object Kit_Storage KitB) 100)
    (= (has-object Part_Storage Bearing) 100)
    (= (has-object Part_Storage Bearing_Housing) 100)
    (= (has-object Part_Storage Rotor) 100)
    (= (has-object Part_Storage Rotor_Housing) 100)
    (= (has-object Part_Storage Locknut) 100)
    (= (has-object Part_Storage Screw) 100)
    (= (has-object Part_Storage Cover) 100)
    (= (has-object Part_Storage Top) 100)

    ; delivery time for each kit
    (= (deliver-time Workcell1) 23.2)
    (= (deliver-time Workcell2) 5.33)
    (= (deliver-time Workcell3) 15.1)

    ; collection time for each graspable
    (= (collect-time KitA) 1.5)
    (= (collect-time KitB) 1.5)
    (= (collect-time Bearing) 1.5)
    (= (collect-time Bearing_Housing) 1.5)
    (= (collect-time Rotor) 1.5)
    (= (collect-time Rotor_Housing) 1.5)
    (= (collect-time Locknut) 1.5)
    (= (collect-time Screw) 1.5)
    (= (collect-time Cover) 1.5)
    (= (collect-time Top) 1.5)

    ; locations
    (route Kit_Storage Workcell1)
    (route Kit_Storage Workcell2)
    (route Kit_Storage Workcell3)
    (route Kit_Storage Spot)
    (route Kit_Storage Part_Storage)

    (route Workcell1 Kit_Storage)
    (route Workcell1 Workcell2)
    (route Workcell1 Workcell3)
    (route Workcell1 Spot)
    (route Workcell1 Part_Storage)

    (route Workcell2 Kit_Storage)
    (route Workcell2 Workcell1)
    (route Workcell2 Workcell3)
    (route Workcell2 Spot)
    (route Workcell2 Part_Storage)

    (route Workcell3 Kit_Storage)
    (route Workcell3 Workcell1)
    (route Workcell3 Workcell2)
    (route Workcell3 Spot)
    (route Workcell3 Part_Storage)

    (route Spot Kit_Storage)
    (route Spot Workcell1)
    (route Spot Workcell2)
    (route Spot Workcell3)
    (route Spot Part_Storage)

    (route Part_Storage Spot)
    (route Part_Storage Kit_Storage)
    (route Part_Storage Workcell1)
    (route Part_Storage Workcell2)
    (route Part_Storage Workcell3)
    
    ; distances
    (= (distance Kit_Storage Workcell1) 10)
    (= (distance Kit_Storage Workcell2) 10)
    (= (distance Kit_Storage Workcell3) 10)
    (= (distance Kit_Storage Spot) 10)
    (= (distance Kit_Storage Part_Storage) 10)

    (= (distance Workcell1 Kit_Storage) 10)
    (= (distance Workcell1 Workcell2) 10)
    (= (distance Workcell1 Workcell3) 10)
    (= (distance Workcell1 Spot) 10)
    (= (distance Workcell1 Part_Storage) 10)

    (= (distance Workcell2 Kit_Storage) 10)
    (= (distance Workcell2 Workcell1) 10)
    (= (distance Workcell2 Workcell3) 10)
    (= (distance Workcell2 Spot) 10)
    (= (distance Workcell2 Part_Storage) 10)

    (= (distance Workcell3 Kit_Storage) 10)
    (= (distance Workcell3 Workcell1) 10)
    (= (distance Workcell3 Workcell2) 10)
    (= (distance Workcell3 Spot) 10)
    (= (distance Workcell3 Part_Storage) 10)

    (= (distance Spot Kit_Storage) 10)
    (= (distance Spot Workcell1) 10)
    (= (distance Spot Workcell2) 10)
    (= (distance Spot Workcell3) 10)
    (= (distance Spot Part_Storage) 10)

    (= (distance Part_Storage Spot) 10)
    (= (distance Part_Storage Kit_Storage) 10)
    (= (distance Part_Storage Workcell1) 10)
    (= (distance Part_Storage Workcell2) 10)
    (= (distance Part_Storage Workcell3) 10)

    ; location sizes
    (= (location-size Kit_Storage) 1)
    (= (location-size Workcell1) 1)
    (= (location-size Workcell2) 1)
    (= (location-size Workcell3) 1)
    (= (location-size Spot) 4)
    (= (location-size Part_Storage) 2)

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; initilize different kits needed at each workcell.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    (set_fluents)

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; define the layout of different kit types.
    ;; make sure set a size for all parts for each kit.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; kit_a
    (= (set-part-size KitA Bearing) 2)
    (= (set-part-size KitA Bearing_Housing) 1)
    (= (set-part-size KitA Rotor) 2)
    (= (set-part-size KitA Rotor_Housing) 1)
    (= (set-part-size KitA Locknut) 2)
    (= (set-part-size KitA Screw) 6)
    (= (set-part-size KitA Cover) 1)
    (= (set-part-size KitA Top) 1)

    ;; kit_b
    (= (set-part-size KitB Bearing) 2)
    (= (set-part-size KitB Bearing_Housing) 4)
    (= (set-part-size KitB Rotor) 2)
    (= (set-part-size KitB Rotor_Housing) 1)
    (= (set-part-size KitB Locknut) 0)
    (= (set-part-size KitB Screw) 2)
    (= (set-part-size KitB Cover) 0)
    (= (set-part-size KitB Top) 0)

)

(:goal (and
    ;; put the goal condition here

    (= (deliver-at KitA Workcell1) 1)
    (= (deliver-at KitB Workcell2) 1)

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; uncomment the followings if empty kits must be returned to the kit storage.
    ;; this will affect the computation time.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;; no kit will remain on workcells
    (forall (?w - workcell ?k - kit)
        (and (= (has-object ?w ?k) 0)))

    ;; no kit will remain on the robot platform
    (forall (?m - mobile)
        (and (has_slot_free ?m Left)
             (has_slot_free ?m Right)))

))

(:metric minimize (total-time))
)
