pragma solidity ^0.4.18;

import "./AtomicMultisig.sol";

contract ValidatorSetChild is AtomicMultisig {
    address constant SYSTEM_ADDRESS = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    bool public changingValidators;
    address[] public pendingList;

    event InitiateChange(bytes32 indexed _parent_hash, address[] _new_set);

    function ValidatorSetChild() public {
        validatorsList.push(0x00Aa39d30F0D20FF03a22cCfc30B7EfbFca597C2);
        validatorsList.push(0x002E28950558Fbede1A9675Cb113F0BD20912019);
        validatorsList.push(0x00a94Ac799442FB13De8302026fd03068bA6A428);
        ValidatorsChange(0, validatorsList);
    }

    function finalizeChange() public {
        require(msg.sender == SYSTEM_ADDRESS);
        doChangeValidators(pendingList);
        changingValidators = false;
        delete(pendingList);
    }

    function changeValidators(address[] _newValidatorsList) public {
        require(_newValidatorsList.length>0);
        require(msg.sender == address(this));
        require(!changingValidators);
        changingValidators = true;
        pendingList = _newValidatorsList;
        InitiateChange(block.blockhash(block.number - 1), pendingList);
    }
}
