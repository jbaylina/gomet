pragma solidity ^0.4.18;


contract LockingContract {
    address owner;
    uint lasIdTx;

    event Lock(uint indexed txId, address indexed thisChaiAddre, address indexed otherChainAddr, uint amount);
    event Unlock(uint indexed otherChainTxId, address indexed otherChainAddress, address indexed thisChinAddress, uint amount);

    function LockingContract(address _owner) public {
        owner = _owner;
    }

    function lock(address otherChainAddress) public payable {
        lasIdTx ++;
        emit Lock(lasIdTx, msg.sender, otherChainAddress, msg.value);
    }

    function unlock(uint otherChainTxId, address otherChainAddress, address thisChinAddress, uint amount) public {
        require(msg.sender == owner);
        thisChinAddress.transfer(amount);
        emit Unlock(otherChainTxId, otherChainAddress, thisChinAddress, amount);
    }

    function changeOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }
}
