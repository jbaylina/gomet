pragma solidity ^0.4.18;

import "./AtomicMultisig.sol";

contract ValidatorsSetMain is AtomicMultisig {
    function ValidatorsSetMain() public {
        validatorsList.push(0x00Aa39d30F0D20FF03a22cCfc30B7EfbFca597C2);
        validatorsList.push(0x002E28950558Fbede1A9675Cb113F0BD20912019);
        validatorsList.push(0x00a94Ac799442FB13De8302026fd03068bA6A428);
        ValidatorsChange(0, validatorsList);
    }
}
