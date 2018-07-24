module Common.BoundedNumber
    exposing
        ( BoundedNumber
        , bounds
        , dec
        , inc
        , init
        , set
        , value
        )


type BoundedNumber number
    = BoundedNumber number number number


init : number -> number -> BoundedNumber number
init min max =
    BoundedNumber min max min


set : number -> BoundedNumber number -> BoundedNumber number
set value (BoundedNumber min max _) =
    BoundedNumber min max (clamp min max value)


inc : BoundedNumber number -> BoundedNumber number
inc ((BoundedNumber min max value) as bounded) =
    set (value + 1) bounded


dec : BoundedNumber number -> BoundedNumber number
dec ((BoundedNumber min max value) as bounded) =
    set (value - 1) bounded


bounds : BoundedNumber number -> ( number, number )
bounds (BoundedNumber min max _) =
    ( min, max )


value : BoundedNumber number -> number
value (BoundedNumber _ _ boundedValue) =
    boundedValue
