pragma solidity ^0.4.18;

contract ValidatorSet {
    function nValidators() public constant returns (uint);
    function ownerPos(address) public constant returns (int);
    function changeValidators(address[] _newValidatorsList) public;
    function era() public constant returns(uint);
}

contract LockingContract {
    function unlock(uint otherChainTxId, address otherChainAddress, address thisChinAddress, uint amount) public;
}

contract ValidatorOps {

    ValidatorSet public validatorSet;
    address public lockParent;
    address public lockChild;

    struct Call {
        uint nConfirmations;
        uint era;
        address dest;
        uint value;
        bytes data;
        mapping (address => bool) confirmations;
    }

    mapping(bytes32 => Call) public calls;


    event UnlockParent(uint era, uint indexed idTxChild, address indexed childAccount, address indexed parentAccount, uint amount, uint8 v, bytes32 r, bytes32 s);
    event UnlockChild(uint era, uint indexed idTxParent, address indexed parentAccount, address indexed childAccount, uint amount, uint8 v, bytes32 r, bytes32 s);
    event ChangeValidators(uint indexed era, address[] newOwners,  uint8 v, bytes32 r, bytes32 s);

    function ValidatorOps(ValidatorSet _validatorSet, address _lockParent, address _lockChild) public {
        validatorSet = _validatorSet;
        lockParent = _lockParent;
        lockChild = _lockChild;
    }

    function unlockParent(uint era, uint idTxChild, address childAccount, address parentAccount, uint amount, bytes32 r, bytes32 s, uint8 v) external {
        bytes memory data = encode(LockingContract(0).unlock.selector, idTxChild, childAccount, parentAccount, amount);
        checkCall(era, address(lockParent), 0, data,  v, r, s);
        emit UnlockParent(era, idTxChild, childAccount, parentAccount, amount, v, r, s);
    }

    function unlockChild(uint era, uint idTxParent, address parentAccount, address childAccount, uint amount, bytes32 r, bytes32 s, uint8 v) external {
        bytes memory data = encode(LockingContract(0).unlock.selector, idTxParent, parentAccount, childAccount, amount);
        saveAndExecute(era, address(lockChild), 0, data, v, r, s);
        emit UnlockChild(era, idTxParent, parentAccount, childAccount, amount, v, r, s);
    }

    function changeValidatorConfig(uint era, address[] newOwners, uint8 v, bytes32 r, bytes32 s) external {
        bytes memory data = encode(validatorSet.changeValidators.selector, newOwners);
        saveAndExecute(era, address(validatorSet), 0, data, v, r, s);
        emit ChangeValidators(era, newOwners, v, r, s);
    }

    function checkCall(uint era, address dest, uint value, bytes data,  uint8 v, bytes32 r, bytes32 s) view internal returns (bytes32) {
        require(tx.gasprice == 0);
        bytes32 hash = keccak256("ValidatorsExecute", era, dest, value, data);
        address src = ecrecover(hash, v, r, s);
        require(msg.sender == src);
        require(validatorSet.era() == era);
        return hash;
    }

    function saveAndExecute(uint era, address dest, uint value, bytes data,  uint8 v, bytes32 r, bytes32 s) internal {
        bytes32 hash = checkCall(era, dest, value, data, v, r, s);
        Call storage c = calls[hash];
        uint nVals = validatorSet.nValidators();
        int vpos = validatorSet.ownerPos(msg.sender);

        require(vpos>=0);
        if (c.nConfirmations == 0) {
            c.era = era;
            c.dest = dest;
            c.value = value;
            c.data = data;
        }

        require(c.confirmations[msg.sender] == false);
        c.confirmations[msg.sender] = true;
        c.nConfirmations ++;

        // Execute on threshold crossing
        if (c.nConfirmations == nVals / 2 + 1) {
            require(dest.call.value(c.value)(c.data));
        }
    }

    function encode(bytes4 sel, uint idTxParent, address parentAccount, address childAccount, uint amount) pure public returns(bytes) {
        uint l = (4 + 32 + 32 + 32 + 32 - 1) / 32 * 32 +32;
        bytes memory b = new bytes(l); // selector + pointer + length + array
        setSelector(b, sel);
        setBytes(b,4, bytes32(idTxParent));
        setBytes(b,36, bytes32(parentAccount));
        setBytes(b,68, bytes32(childAccount));
        setBytes(b,100, bytes32(amount));
        return b;
    }

    function encode(bytes4 sel, address[] c) pure public returns(bytes) {
        uint l = (4 + 32 + 32 + 32*c.length - 1) / 32 * 32 +32;
        bytes memory b = new bytes(l); // selector + pointer + length + array
        setSelector(b, sel);
        setBytes(b,4, bytes32(36));
        setBytes(b,36, bytes32(c.length));
        uint i;
        for (i=0; i<c.length; i++) {
            setBytes(b, 68+i*32, bytes32(c[i]));
        }
        return b;
    }

    function setSelector(bytes b,  bytes4 sel) pure internal {
        b[0]=sel[0];
        b[1]=sel[1];
        b[2]=sel[1];
        b[3]=sel[1];
    }

    function setBytes(bytes b, uint pos, bytes32 v) pure internal {
        assembly {
            mstore(add(b,add(32, pos)), v)
        }
    }
}

