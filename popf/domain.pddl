;Header and description

(define (domain kitting)

    ; define requirements here
    (:requirements
     :strips
     :fluents
     :typing
     :durative-actions
    ;  :action-costs
     :equality
    ;  :disjunctive-preconditions
     :negative-preconditions
     :conditional-effects
    ;  :universal-preconditions
    )

    (:types 
        location graspable robot slot - object
        spot workcell storage - location
        kit_storage part_storage - storage
        part kit - graspable
        bearing bearing_housing cover locknut rotor rotor_housing screw top - part
        mobile - robot
        slot
    )

    (:predicates ; define predicates here
        (route ?from ?to - location)
        (robot_at ?robot - mobile ?from - location)
        (has_kit_at ?robot - mobile ?kit - kit ?s - slot)
        (has_slot_free ?robot - mobile ?slot - slot)
        (has_arm_free ?m - mobile)
        (arm_holding ?o - graspable)
        ; (set_fluents)
        ; (fluents_set)

        ;; only added these two predicates for using popf in plansys2
        ;; they can be removed once optic or tfd were integrated into plansys2
        (empty ?w - location)
        (delivered-at ?k - kit ?w - workcell)
    )

    (:functions ; define numeric functions here
        (drive-time-pm ?r - mobile)
        (collect-time ?g - graspable)
        (deliver-time ?w - workcell)
        (processing-time ?k - kit)
        (distance ?from ?to - location)
        (location-size ?l - location)
        (has-object ?l - location ?o - graspable)
        (inserted ?r - mobile ?g - part ?k - kit ?s - slot)
        (set-part-size ?k - kit ?p - part)
        (deliver-at ?k - kit ?w - workcell)
    )

    ; define actions here

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; initialize some fluents
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; (:durative-action set_fluents
    ;     :parameters ()
    ;     :duration (= ?duration 1)
    ;     :condition (and (at start (set_fluents)))
    ;     :effect (and 
    ;         (forall (?w - workcell ?k - kit)
    ;             (at start (assign (has-object ?w ?k) 0)))
    ;         (forall (?w2 - workcell ?k2 - kit)
    ;             (at start (assign (deliver-at ?k2 ?w2) 0)))
    ;         (at start (not (set_fluents)))
    ;         (at end (fluents_set))
    ;     )
    ; )

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; take an empty kit from a kit storage 
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    (:durative-action take
        :parameters (?m - mobile 
                     ?k - kit 
                     ?s - slot 
                     ?l - location
                     ?bearing - bearing
                     ?bearing_housing - bearing_housing
                     ?cover - cover
                     ?locknut - locknut
                     ?rotor - rotor
                     ?rotor_housing - rotor_housing
                     ?screw - screw
                     ?top - top)
        :duration (= ?duration (collect-time ?k))
        :condition (and 
            ; (at start (fluents_set))
            (over all (robot_at ?m ?l))
            (at start (has_arm_free ?m))
            (at start (has_slot_free ?m ?s))
            (at start (> (has-object ?l ?k) 0))
        )
        :effect (and 
            (at start (arm_holding ?k))
            (at start (not (has_arm_free ?m)))
            (at start (has_kit_at ?m ?k ?s))
            ; (forall (?p - part)
            ;     (and (at start (assign (inserted ?m ?p ?k ?s) 0))))
            (at start (assign (inserted ?m ?bearing ?k ?s) 0))
            (at start (assign (inserted ?m ?bearing_housing ?k ?s) 0))
            (at start (assign (inserted ?m ?cover ?k ?s) 0))
            (at start (assign (inserted ?m ?locknut ?k ?s) 0))
            (at start (assign (inserted ?m ?rotor ?k ?s) 0))
            (at start (assign (inserted ?m ?rotor_housing ?k ?s) 0))
            (at start (assign (inserted ?m ?screw ?k ?s) 0))
            (at start (assign (inserted ?m ?top ?k ?s) 0))
            (at end (not (arm_holding ?k)))
            (at end (has_arm_free ?m))
            (at end (not (has_slot_free ?m ?s)))
            (at end (decrease (has-object ?l ?k) 1))

            ;; to use popf in plansys: meaning a workcell is empty
            (at end (empty ?l))
        )
    )

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; put an empty kit back to a kit storage
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    (:durative-action put
        :parameters (?m - mobile 
                     ?k - kit 
                     ?s - slot 
                     ?l - kit_storage
                     ?bearing - bearing
                     ?bearing_housing - bearing_housing
                     ?cover - cover
                     ?locknut - locknut
                     ?rotor - rotor
                     ?rotor_housing - rotor_housing
                     ?screw - screw
                     ?top - top)
        :duration (= ?duration (collect-time ?k))
        :condition (and 
            ; (at start (fluents_set))
            (at start (robot_at ?m ?l))
            (at start (has_arm_free ?m))
            (at start (has_kit_at ?m ?k ?s))
            (at start (>= (has-object ?l ?k) 0))
            ; (at start 
            ;     (forall (?p - part) 
            ;         (= (inserted ?m ?p ?k ?s) 0)))
            (at start (= (inserted ?m ?bearing ?k ?s) 0))
            (at start (= (inserted ?m ?bearing_housing ?k ?s) 0))
            (at start (= (inserted ?m ?cover ?k ?s) 0))
            (at start (= (inserted ?m ?locknut ?k ?s) 0))
            (at start (= (inserted ?m ?rotor ?k ?s) 0))
            (at start (= (inserted ?m ?rotor_housing ?k ?s) 0))
            (at start (= (inserted ?m ?screw ?k ?s) 0))
            (at start (= (inserted ?m ?top ?k ?s) 0))
        )
        :effect (and 
            (at start (arm_holding ?k))
            (at start (not (has_arm_free ?m)))
            (at end (not (arm_holding ?k)))
            (at end (has_arm_free ?m))
            (at start (not (has_kit_at ?m ?k ?s)))
            (at end (has_slot_free ?m ?s))
            (at end (increase (has-object ?l ?k) 1))
        )
    )

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; collect a part from a storage and insert it in the kit on the platform
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    (:durative-action collect
        :parameters (?m - mobile ?p - part ?k - kit ?s - slot ?l - storage)
        :duration (= ?duration (collect-time ?p))
        :condition (and 
            ; (at start (fluents_set))
            (over all (robot_at ?m ?l))
            (at start (has_arm_free ?m))
            (at start (has_kit_at ?m ?k ?s))
            (at start (> (has-object ?l ?p) 0))
        )
        :effect (and 
            (at start (arm_holding ?p))
            (at start (not (has_arm_free ?m)))
            (at end (not (arm_holding ?p)))
            (at end (has_arm_free ?m))
            (at end (increase (inserted ?m ?p ?k ?s) 1))
            (at end (decrease (has-object ?l ?p) 1))
        )
    )

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; deliver a kit on a workcell
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    (:durative-action deliver
        :parameters (?m - mobile 
                     ?k - kit 
                     ?s - slot 
                     ?w - workcell
                     ?bearing - bearing
                     ?bearing_housing - bearing_housing
                     ?cover - cover
                     ?locknut - locknut
                     ?rotor - rotor
                     ?rotor_housing - rotor_housing
                     ?screw - screw
                     ?top - top)
        :duration (= ?duration (+ (deliver-time ?w) (processing-time ?k)))
        :condition (and 
            ; (at start (fluents_set))
            (at start (robot_at ?m ?w))
            (at start (has_kit_at ?m ?k ?s))
            ; (over all 
            ;     (forall (?kit - kit) 
            ;         (= (has-object ?w ?kit) 0)))
            ;; workcell must be empty (an alternative to the above forall in popf)
            (at start (empty ?w))
            ; (at start 
            ;     (forall (?p - part) 
            ;         (= (inserted ?m ?p ?k ?s) (set-part-size ?k ?p))))
            (at start (= (inserted ?m ?bearing ?k ?s) (set-part-size ?k ?bearing)))
            (at start (= (inserted ?m ?bearing_housing ?k ?s) (set-part-size ?k ?bearing_housing)))
            (at start (= (inserted ?m ?cover ?k ?s) (set-part-size ?k ?cover)))
            (at start (= (inserted ?m ?locknut ?k ?s) (set-part-size ?k ?locknut)))
            (at start (= (inserted ?m ?rotor ?k ?s) (set-part-size ?k ?rotor)))
            (at start (= (inserted ?m ?rotor_housing ?k ?s) (set-part-size ?k ?rotor_housing)))
            (at start (= (inserted ?m ?screw ?k ?s) (set-part-size ?k ?screw)))
            (at start (= (inserted ?m ?top ?k ?s) (set-part-size ?k ?top)))
        )
        :effect (and 
            (at start (not (has_kit_at ?m ?k ?s)))
            (at start (has_slot_free ?m ?s))
            (at end (increase (has-object ?w ?k) 1))
            (at end (increase (deliver-at ?k ?w) 1))

            ;; workcell is not empty anymore to deliver a new kit
            (at start (not (empty ?w)))
            ;; only for using popf since it does not support fluents in the goal description
            (at end (delivered-at ?k ?w))
        )
    )

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; drive mobile platform between locations
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    (:durative-action drive
        :parameters (?m - mobile ?from ?to - location)
        :duration (= ?duration (* (distance ?from ?to) (* 5 (drive-time-pm ?m))))
        :condition (and 
            ; (at start (fluents_set))
            (at start (route ?from ?to))
            (at start (robot_at ?m ?from))
            (at start (> (location-size ?to) 0))
        )
        :effect (and 
            (at start (not (robot_at ?m ?from)))
            (at end (robot_at ?m ?to))
            (at start (increase (location-size ?from) 1))
            (at start (decrease (location-size ?to) 1))
        )
    )
)