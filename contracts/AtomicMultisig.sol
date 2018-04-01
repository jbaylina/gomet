pragma solidity ^0.4.18;

contract AtomicMultisig {
    address[] public validatorsList;
    uint public era;

    event ValidatorsChange(uint era, address[] _new_set);
    event Execute(uint era, address indexed dest, uint value, bytes data);

    function getValidators() public constant returns (address[] _validators) {
        return validatorsList;
    }

    function nValidators() public constant returns (uint) {
        return validatorsList.length;
    }

    function changeValidators(address[] _newValidatorsList) public {
        doChangeValidators(_newValidatorsList);
        require(msg.sender == address(this));
    }

    function doChangeValidators(address[] _newValidatorsList) internal {
        validatorsList = _newValidatorsList;
        era ++;
        ValidatorsChange(era, validatorsList);
    }

    function validatorPos(address a) view public returns(int) {
        uint i;
        for(i=0; i<validatorsList.length; i++) {
            if (a == validatorsList[i]) return int(i);
        }
        return -1;
    }

    function isValidMultisig(bytes32 hash, uint8[] _v, bytes32[] _r, bytes32[] _s) view internal returns(bool) {
        require(_r.length == _s.length);
        require(_s.length == _v.length);
        bool[] memory usedAddresses = new bool[](validatorsList.length);
        uint mSigned;
        uint i;
        for (i=0; i<_r.length; i++) {
            address a = ecrecover(hash, _v[i], _r[i], _s[i]);
            int pos = validatorPos(a);
            if (pos>=0 && (! usedAddresses[uint(pos)])) {
                usedAddresses[uint(pos)] = true;
                mSigned++;
            }
        }
        return (mSigned>validatorsList.length/2);
    }

    function execute(uint _era, address _dest, uint _value, bytes _data,  uint8[] _v, bytes32[] _r, bytes32[] _s) public {
        require(era == _era);
        bytes32 h = keccak256("ValidatorsExecute", _era, _dest, _value, _data);
        require(isValidMultisig(h, _v, _r, _s));
        require(_dest.call.value(_value)(_data));
        Execute(era, _dest, _value, _data);
    }

}
