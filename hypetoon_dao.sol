// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract HypeToon is ERC20, Ownable {
	uint256 public constant total_supply_limit = 2000000000000000000000000000; // Wei
	address public constant genesis_vault_address = 0x11FFc5bA95377eA1aFb7a8f62Ee394d91371Bd63; // Safe Multi-Sig Vault

	struct Proposal {
		bool executed;
		string description;
		uint256 total_votes;
		address[] voted_users;
	}

	Proposal[] public proposals;
	uint256 public next_proposal_id = 1;

	// Mapping to track user votes for each proposal
	mapping(uint256 => mapping(address => uint256)) public user_requested_votes;

	//---------------------------------------------------------------
	// Events
	//---------------------------------------------------------------
	event Mint(address indexed to, uint256 amount);
	event NewProposal(uint256 id, string description);
	event Vote(uint256 id, address indexed voter, uint256 requested_votes);

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor() ERC20("Hypetoon", "HYPE") {
		mint(genesis_vault_address, total_supply_limit);
	}

	receive() external payable {
		// Fallback function to receive Ether
	}

	function create_proposal(string memory _description) external {
		uint256 proposal_id = next_proposal_id;
		next_proposal_id++;
		proposals.push(Proposal(false, _description, 0, new address[](0)));

		emit NewProposal(proposal_id, _description);
	}

	function vote(uint256 _proposal_id, uint256 _requested_votes) external {
		require(_proposal_id < next_proposal_id, "vote: Invalid proposal ID");
		require(!proposals[_proposal_id].executed, "vote: Proposal already executed");
		require(_requested_votes > 0, "vote: Votes must be greater than 0");
		require(balanceOf(msg.sender) >= _requested_votes, "vote: Votes must be smaller than balance");

		// Update user votes and voted users for the proposal
		proposals[_proposal_id].voted_users.push(msg.sender);
		user_requested_votes[_proposal_id][msg.sender] = _requested_votes;

		emit Vote(_proposal_id, msg.sender, _requested_votes);
	}

	function execute_proposal(uint256 _proposal_id) external {
		require(_proposal_id < next_proposal_id, "execute_proposal: Invalid proposal ID");

		Proposal storage proposal = proposals[_proposal_id];
		require(!proposal.executed, "execute_proposal: Proposal already executed");

		// Calculate the total votes by considering each user's token balance and requested votes
		for (uint256 i = 0; i < proposal.voted_users.length; i++) {
			address user = proposal.voted_users[i];
			uint256 user_balance = balanceOf(user);
			proposal.total_votes += min(user_balance, user_requested_votes[_proposal_id][user]);
		}

		proposal.executed = true;
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function mint(address _to, uint256 _amount) private {
		require(totalSupply() + _amount <= total_supply_limit, "mint: limit exceed");

		super._mint(_to, _amount);

		emit Mint(_to, _amount);
	}

	function min(uint256 a, uint256 b) private pure returns (uint256) {
		return a < b ? a : b;
	}
}
