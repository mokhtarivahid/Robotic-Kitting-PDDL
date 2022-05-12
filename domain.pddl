;Header and description

(define (domain kitting)

    ; define requirements here
    (:requirements
     :strips
     :fluents
     :typing
     :durative-actions
     :action-costs
     :equality
     :derived-predicates
     :disjunctive-preconditions
     :negative-preconditions
     :conditional-effects
     :universal-preconditions)

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
        (set_fluents)
        (fluents_set)
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

    (:durative-action set_fluents
        :parameters ()
        :duration (= ?duration 1)
        :condition (and (at start (set_fluents)))
        :effect (and 
            (forall (?w - workcell ?k - kit)
                (at start (assign (has-object ?w ?k) 0)))
            (forall (?w2 - workcell ?k2 - kit)
                (at start (assign (deliver-at ?k2 ?w2) 0)))
            (at start (not (set_fluents)))
            (at end (fluents_set))
        )
    )

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; take an empty kit from a kit storage 
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    (:durative-action take
        :parameters (?m - mobile ?k - kit ?s - slot ?l - location)
        :duration (= ?duration (collect-time ?k))
        :condition (and 
            (at start (fluents_set))
            (over all (robot_at ?m ?l))
            (at start (has_arm_free ?m))
            (at start (has_slot_free ?m ?s))
            (at start (> (has-object ?l ?k) 0))
        )
        :effect (and 
            (at start (arm_holding ?k))
            (at start (not (has_arm_free ?m)))
            (at start (has_kit_at ?m ?k ?s))
            (forall (?p - part)
                (and (at start (assign (inserted ?m ?p ?k ?s) 0))))
            (at end (not (arm_holding ?k)))
            (at end (has_arm_free ?m))
            (at end (not (has_slot_free ?m ?s)))
            (at end (decrease (has-object ?l ?k) 1))
        )
    )

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; put an empty kit back to a kit storage
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    (:durative-action put
        :parameters (?m - mobile ?k - kit ?s - slot ?l - kit_storage)
        :duration (= ?duration (collect-time ?k))
        :condition (and 
            (at start (fluents_set))
            (at start (robot_at ?m ?l))
            (at start (has_arm_free ?m))
            (at start (has_kit_at ?m ?k ?s))
            (at start (>= (has-object ?l ?k) 0))
            (at start 
                (forall (?p - part) 
                    (= (inserted ?m ?p ?k ?s) 0)))
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
            (at start (fluents_set))
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
        :parameters (?m - mobile ?k - kit ?s - slot ?w - workcell)
        :duration (= ?duration (deliver-time ?w))
        :condition (and 
            (at start (fluents_set))
            (at start (robot_at ?m ?w))
            (at start (has_kit_at ?m ?k ?s))
            (over all 
                (forall (?kit - kit) 
                    (= (has-object ?w ?kit) 0)))
            (at start 
                (forall (?p - part) 
                    (= (inserted ?m ?p ?k ?s) (set-part-size ?k ?p))))
        )
        :effect (and 
            (at start (not (has_kit_at ?m ?k ?s)))
            (at start (has_slot_free ?m ?s))
            (at end (increase (has-object ?w ?k) 1))
            (at end (increase (deliver-at ?k ?w) 1))
        )
    )

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; drive mobile platform between locations
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    (:durative-action drive
        :parameters (?m - mobile ?from ?to - location)
        :duration (= ?duration (* (distance ?from ?to) (* 5 (drive-time-pm ?m))))
        :condition (and 
            (at start (fluents_set))
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