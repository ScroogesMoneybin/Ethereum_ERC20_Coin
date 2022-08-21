pragma solidity 0.8.12;

library FixedPoint {
    uint public constant MULTIPLIER=10**18;

    // struct Wad {
    //     uint value;
    // } 
    //Using struct is old way and less gas effecient and as reference type requires identifying arguments to functions as memory.
    //  Now we use type. But we also input its value with Wad.unwrap(wad)

    type Wad is uint;

    function MultWad(uint number, Wad wad) internal pure returns (uint) {
        return (number * Wad.unwrap(wad))/MULTIPLIER;
    }

     function DivideWad(uint number, Wad wad) internal pure returns (uint) {
        return (number * MULTIPLIER)/Wad.unwrap(wad);
    }

    function fromFraction(uint numerator, uint denominator) internal pure returns (Wad) {
        if (numerator==0) {
            return Wad.wrap(0);
        }
        return Wad.wrap((numerator*MULTIPLIER)/denominator);
    }

}