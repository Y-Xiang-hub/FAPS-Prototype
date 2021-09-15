// @Author: Yuexin Xiang
// @Email: yuexin.xiang@cug.edu.cn


//Remix Compiler 0.4.25
pragma solidity >=0.4.22 <0.7.0;

contract Verification{

    //Start to verify the signed string
    function Verify_String(bytes memory signed_string) public returns (address){
    
        //This is a signed string data
		//e.g. bytes memory signed_string =hex"..."
        bytes32 data_h;
        //Divide the data into three parts
        bytes32 r = BytesToBytes32(Slice(signed_string,0,32));
        bytes32 s = BytesToBytes32(Slice(signed_string,32,32));
        byte v = Slice(signed_string,64,1)[0];
        return Ecrecover_Verify(data_h, r, s, v);
    }
  
    function Slice(bytes memory Data,uint Start,uint Len) public returns(bytes) {
        bytes memory Byt = new bytes(Len);
        for(uint i = 0; i < Len; i++){
            Byt[i] = Data[i + Start];
        }
        return Byt;
    }
  
    //Using ecrecover to recover the public key
    function Ecrecover_Verify(bytes32 data_h, bytes32 r,bytes32 s, byte v1) public returns(address Addr) {
        uint8 v = uint8(v1) + 27;
		//This is data hash
		// e.g. data_a = "..."
        Addr = ecrecover(data_a, v, r, s);
    }
  
    //Transfer bytes to bytes32
    function BytesToBytes32(bytes memory Source) public returns(bytes32 ResultVerify) {
        assembly{
            ResultVerify :=mload(add(Source,32))
        }
    }
}

contract FAPS {
    
    Verification vss;
    address public address_PKB;
    address public address_R;
    
    uint256 public deposit_A;//The amount of deposit that Alice should pay
    uint256 public deposit_B;//The amount of deposit that Bob should pay
    uint256 public block_num;//The number of the blocks of the data Bob wants to buy
    uint256 public block_price;//The price of each block of the data set by Alice
    uint256 public block_value;//The amount of the tokens Bob needs to pay
    uint256 public Time_Start;//The time when the transaction starts
    uint256 public Time_Limit;//The time limit of the transaction
    
    bytes public cheque_signed;//The cheque Bob sends to the smarc contract
    bytes public cheque_B;//The cheque_signed Alice verifies by PK_B and SK_A
    string public PK_A;//The public key of Alice
    string public PK_B;//The public key of Bob

    address public address_A;//The address of Alice
    address public address_B;//The address of Bob

    bool step_SetDepositA = false;
    bool step_SetDepositB = false;
    bool step_SetPrice = false;
    bool step_SendDepositA = false;
    bool step_SendPublicKeyA = false;
    bool step_SetTime = false;
    bool step_SetNumber = false;
    bool step_SendDepositB = false;
    bool step_SendValue = false;
    bool step_SendPublicKeyB = false;
    bool step_SendSignedCheque = false;
    bool step_CheckCheque = false;
    bool step_Result = false;
    bool step_Withdraw = false;
    
    //The creater of the smart contract
	constructor () public payable {
        address_A = msg.sender;
    }
    
    //Display the time 
    function Display_Time() public view returns (uint256) {
        return now;
    }

    //Alice sets the deposit of Alice
	function Set_DepositA (uint256 DepositAlice) public {
		if (msg.sender == address_A) {
		    step_SetDepositA = true;
		    deposit_A = DepositAlice;
		}
		else {
		    step_SetDepositA = false;
	        revert("Only Alice can set the deposit of Alice.");
		}
	}

    //Alice sets the deposit of Bob
	function Set_DepositB (uint256 DepositBob) public {
	    if (step_SetDepositA == true) {
	    	if (msg.sender == address_A) {
		        step_SetDepositB = true;
		        deposit_B = DepositBob;
		    }
		    else {
		        step_SetDepositB = false;
	            revert("Only Alice can set the deposit of Bob.");
		    }
	    }
	    else {
	        step_SetDepositB = false;
	        revert("Please set the deposit of Alice first.");
		}
	}
	
	//Alice sets the price of each block of the data
	function Set_Price (uint256 BlockPrice) public {
		if (step_SetDepositB == true) {
		    if (msg.sender == address_A) {
		        step_SetPrice = true;
		        block_price = BlockPrice;
		    }
		    else {
		        step_SetPrice = false;
	            revert("Wrong Price of Each Block.");
		    }
		}
		else {
		    step_SetPrice = false;
		    revert("Please set the deposit of Bob first.");
		}
	}
	
	//Alice sends the deposit to the smart contract
    function Send_DepositA () public payable returns(bool) {
	    if (step_SetPrice == true) {
	        if (msg.sender == address_A) {
	            if (msg.value == deposit_A) {
	                step_SendDepositA = true;
	                return address(this).send(msg.value);
	            }
	            else {
	                step_SendDepositA = false;
	                revert("The amount of deposit Alice pays is wrong.");
	            }
	        }
	        else {
	            step_SendDepositA = false;
	            revert("Only Alice can send the deposit of Alice.");
	        }
	    }
	    else {
	        step_SendDepositA = false;
	        revert("Please set the price of each block first.");
	    }
	}
	
	//Alice sends her public key to the smart contract
    function Send_PublicKeyA (string PublicKeyA) public {
        if (step_SendDepositA == true) {
        	if (msg.sender == address_A) {
        	    step_SendPublicKeyA = true;
            	PK_A = PublicKeyA;
        	}
        	else {
            	step_SendPublicKeyA = false;
            	revert("Only Alice can send her public key.");
        	}
        }
        else {
            step_SendPublicKeyA = false;
            revert("Please send the deposit of Alice first.");
        }
    }
    
    //Alice sets the time limit of the transaction
    function Set_Time (uint TimeLimit) public {
        if (step_SendPublicKeyA == true) {
            if (msg.sender == address_A) {
                step_SetTime = true;
                Time_Limit = TimeLimit;
                Time_Start = now;
            }
            else {
                step_SetTime = false;
                revert("Only Alice can set the limit of time.");
            }
        }
        else {
            step_SetTime = false;
            revert("Please send the public key of Alice first.");
        }
    }
	
	//Bob sends the number of blokcs he wants to buy to the smart contract
	function Set_Number (uint BlockNumber) public {
	    address_B = msg.sender;
	    if (step_SetTime == true) {
	        if (address_B != address_A) {
	            step_SetNumber = true;
	            block_num = BlockNumber;
	            block_value = block_price * block_num;
	        }
	        else {
	            step_SetNumber = false;
	            revert("The seller and the buyer can not be same.");
	        }
	    }
	    else {
	        step_SetNumber = false;
	        revert("Please send the public key of Alice first.");
	   }
    }
    
    //Bob sends the deposit to the smart contract
    function Send_DepositB () public payable returns(bool) {
        if (step_SetNumber == true) {
            if (msg.sender == address_B) {
                if (msg.value == deposit_B) {
                    step_SendDepositB = true;
                    return address(this).send(msg.value);
                }
                else {
	                step_SendDepositB = false;
	                revert("The amount of deposit Bob pays is wrong.");
	            }
            }
            else {
	            step_SendDepositB = false;
	            revert("Only Bob can send the deposit of Bob.");
	        }
        }
        else {
	        step_SendDepositB = false;
	        revert("Please set the number of blocks first.");
	    }
    }
    
    //Bob sends the value of blocks to the smart contract
    function Send_Value () public payable returns(bool) {
        if (step_SendDepositB == true) {
            if (msg.sender == address_B) {
                if (msg.value == block_value) {
                    step_SendValue = true;
                    return address(this).send(msg.value);
                }
                else {
	                step_SendValue = false;
	                revert("The value of blocks Bob pays is wrong.");
	            }
            }
            else {
	            step_SendValue = false;
	            revert("Only Bob can pay for the blocks.");
	        }
        }
        else {
	        step_SendValue = false;
	        revert("Please send the deposit of Bob first.");
	    }
    }
    
    //Bob sends his public key to the smart contract
    function Send_PublicKeyB (string PublicKeyB) public {
        if (step_SendValue == true) {
        	if (msg.sender == address_B) {
        	    step_SendPublicKeyB = true;
        	    PK_B = PublicKeyB;
        	}
        	else {
            	step_SendPublicKeyB = false;
            	revert("Only Bob can send the publick key of Bob.");
        	}
        }
        else {
            step_SendPublicKeyB = false;
            revert("Please send the value of blokcs first.");
        }
    }
    
    //Bob sends the signed cheque to the smart contract
    function Send_SignedCheque (bytes SignedCheque) public {
        if (step_SendPublicKeyB == true) {
        	if (msg.sender == address_B) {
        	    step_SendSignedCheque = true;
            	cheque_signed = SignedCheque;
        	}
        	else {
            	step_SendSignedCheque = false;
            	revert("Only Bob can send signed cheque.");
        	}
        }
        else {
            step_SendSignedCheque = false;
            revert("Please send the value of blokcs first.");
        }
    }

    //Alice check signed cheque and send it to the smart contract
    function Send_Cheque (bytes Cheque) public { 
        if (step_SendSignedCheque == true) {
            if (msg.sender == address_A) {
                cheque_B = Cheque;
                address_R = vss.Verify_String(Cheque);
                if (address_R == address_PKB) {
                    step_CheckCheque = true;
                }
                else {
                    step_CheckCheque = false;
                    revert("The signature of signed cheque is wrong.");
                }
            }
            else {
                step_CheckCheque = false;
                revert("Only Alice can send the cheque for verification.");
            }
        }
        else {
            step_CheckCheque = false;
            revert("Please send the signed cheque first.");
        }
    }
    
    //The result of the trasaction
    function Button_Result () public {
        if (step_CheckCheque == true) {
            if (msg.sender == address_A || msg.sender == address_B) {
                step_Result = true;
                address_A.transfer(deposit_A);
                address_B.transfer(deposit_B);
            }
            else {
                step_Result = false;
                revert("Only Alice or Bob can comfirm.");
            }
        }
        else {
            step_Result = false;
            revert("Please check the cheque first.");
        }
    }
    
    //To stop the transaction for waiting too long
    function Button_End () public {
        
        //Only Alice sends the deposit
        if ((msg.sender == address_A || msg.sender == address_B) &&
            now > Time_Start + Time_Limit &&
            step_SendDepositA == true) {
            address_A.transfer(deposit_A);
        }
        
        //Alice and Bob both send the deposit
        else if ((msg.sender == address_A || msg.sender == address_B) &&
                 now > Time_Start + Time_Limit &&
                 step_SendDepositB == true) {
            address_A.transfer(deposit_A);
            address_B.transfer(deposit_B);
        }
        
        //Bob sends the value of bloacks
        else if ((msg.sender == address_A || msg.sender == address_B) &&
                 now > Time_Start + Time_Limit &&
                 step_SendValue == true) {
            address_A.transfer(deposit_A);
            address_B.transfer(deposit_B);
            address_B.transfer(block_value);
        }
        
        else {
            revert("The transaction is running.");
        }
    }
    
    //Alice withdraws the money
    function Withdraw_Money () public {
        if (step_Result == true) {
            if (msg.sender == address_A) {
                step_Withdraw = true;
                address_A.transfer(block_value);
            }
            else {
                step_Withdraw = false;
                revert("Only Alice can use it.");
            }
        }
        else {
            step_Withdraw = false;
            revert("The transaction has not completed yet.");
        }
    }
}
