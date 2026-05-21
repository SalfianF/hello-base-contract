// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title  ANBLE Token
/// @notice ERC-20-compliant token with mint, burn, and burnFrom capabilities.
/// @dev    Single-file implementation (no external dependencies). Max supply
///         is capped at construction time and enforced on all mint operations.
/// @custom:security contact salfianf@github.com
contract ANBLE {
    // --- Errors ---
    error ANBLE__Unauthorized(address caller);
    error ANBLE__ExceedsMaxSupply(uint256 requested, uint256 maxSupply);
    error ANBLE__InsufficientBalance(address from, uint256 requested, uint256 available);
    error ANBLE__InsufficientAllowance(address owner, address spender, uint256 requested, uint256 available);

    // --- State ---
    string public constant name   = "ANBLE";
    string public constant symbol = "ANBLE";
    uint8  public constant decimals = 18;

    uint256 public totalSupply;
    uint256 public immutable MAX_SUPPLY;

    address public owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert ANBLE__Unauthorized(msg.sender);
        _;
    }

    // --- Constructor ---
    /// @param  initialOwner  Address granted ownership (can mint/burnFrom)
    /// @param  initialSupply Initial token supply minted to `initialOwner`
    constructor(address initialOwner, uint256 initialSupply) {
        if (initialSupply > (MAX_SUPPLY = 1_000_000_000 * 10**18))
            revert ANBLE__ExceedsMaxSupply(initialSupply, MAX_SUPPLY);

        owner = initialOwner;
        totalSupply = initialSupply;
        _balances[initialOwner] = initialSupply;

        emit Transfer(address(0), initialOwner, initialSupply);
    }

    // --- ERC-20 Core ---
    /// @return Balance of `account`
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice Transfers `value` from caller to `to`
    /// @return true on success
    function transfer(address to, uint256 value) external returns (bool) {
        address from = msg.sender;
        if (_balances[from] < value)
            revert ANBLE__InsufficientBalance(from, value, _balances[from]);

        _balances[from] -= value;
        _balances[to]   += value;

        emit Transfer(from, to, value);
        return true;
    }

    /// @notice Approves `spender` to spend `value` on behalf of caller
    /// @return true on success
    function approve(address spender, uint256 value) external returns (bool) {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /// @notice Transfers `value` from `from` to `to` using allowance
    /// @return true on success
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = _allowances[from][msg.sender];
        if (_balances[from] < value)
            revert ANBLE__InsufficientBalance(from, value, _balances[from]);
        if (allowed < value)
            revert ANBLE__InsufficientAllowance(from, msg.sender, value, allowed);

        _allowances[from][msg.sender] = allowed - value;
        _balances[from] -= value;
        _balances[to]   += value;

        emit Transfer(from, to, value);
        return true;
    }

    // --- Mint ---
    /// @notice Mint `amount` tokens to `to` (owner only)
    function mint(address to, uint256 amount) external onlyOwner {
        if (totalSupply + amount > MAX_SUPPLY)
            revert ANBLE__ExceedsMaxSupply(totalSupply + amount, MAX_SUPPLY);

        totalSupply += amount;
        _balances[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    // --- Burn ---
    /// @notice Burn `value` tokens from caller's balance
    function burn(uint256 value) external {
        if (_balances[msg.sender] < value)
            revert ANBLE__InsufficientBalance(msg.sender, value, _balances[msg.sender]);

        _balances[msg.sender] -= value;
        totalSupply -= value;

        emit Transfer(msg.sender, address(0), value);
    }

    /// @notice Burn `value` tokens from `from` (owner only)
    /// @dev    Does NOT require prior approval — intended for compliance/off-chain actions
    function burnFrom(address from, uint256 value) external onlyOwner {
        if (_balances[from] < value)
            revert ANBLE__InsufficientBalance(from, value, _balances[from]);

        _balances[from] -= value;
        totalSupply -= value;

        emit Transfer(from, address(0), value);
    }
}
