/**
 *Submitted for verification at basescan.org on 2024-04-26
*/

// TG
// https://t.me/mewnbaseonbase
// Website 
// https://www.mewnbase.org/
// Twitter/X
// https://x.com/Mewnbase_erc20

// SPDX-License-Identifier: MIT


pragma solidity 0.8.25;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract MMN is IERC20, Ownable {
    using SafeMath for uint256;
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    string private constant _name = "Moomin";
    string private constant _symbol = "MMN";
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply = 770_000_000 * (10 ** _decimals);
    uint256 private _maxWalletToken = (_totalSupply * 100) / 10000;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isDividendExempt;
    mapping(address => bool) public isContractDividendAllowed;
    bool private tradingOpen = false;
    uint256 private startTime = 0;
    uint256 private deltaEnd = 2 minutes;
    IRouter router;
    address public pair;
    uint256 private buyFee = 770;
    uint256 private sellFee = 770;
    uint256 private initFee = 3000;
    uint256 private transferFee = 0;
    uint256 private denominator = 10000;
    uint256 public swapCounterTrigger = 5;
    bool private swapEnabled = true;
    uint256 public swapTimes;
    bool private swapping;
    uint256 public excessDividends;
    uint256 private swapThreshold = (_totalSupply * 100) / 100000;
    uint256 private _minTokenAmount = (_totalSupply * 10) / 100000;
    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }
    bool public autoRewards = true;
    // bool public blacklistRevoked = false;
    bool public saveEthRevoked =  false;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public currentDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 internal dividendsPerShareAccuracyFactor = 10 ** 36;
    address[] shareholders;
    
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    mapping(address => Share) public shares;
    mapping(address => bool)  public blacklist;
    uint256 internal currentIndex;
    uint256 public minPeriod = 15 minutes;
    uint256 public minDistribution = 1 * (10 ** 9);
    uint256 public distributorGas = 500000;

    address internal constant DEAD = 0x000000000000000000000000000000000000dEaD;

    constructor() Ownable(msg.sender) {
        IRouter _router = IRouter(0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb);
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
        router = _router;
        pair = _pair;
        isFeeExempt[address(this)] = true;
        isFeeExempt[msg.sender] = true;
        isDividendExempt[address(pair)] = true;
        isDividendExempt[address(msg.sender)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(DEAD)] = true;
        isDividendExempt[address(0)] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function setisExempt(address _address, bool _enabled) external onlyOwner {
        isFeeExempt[_address] = _enabled;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function circulatingSupply() public view override returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));
    }

    function preTxCheck(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        // require(blacklist[sender] == false && blacklist[recipient] == false ,"User is blacklisted");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            amount > uint256(0),
            "Transfer amount must be greater than zero"
        );
        require(
            amount <= balanceOf(sender),
            "You are trying to transfer more than your balance"
        );

    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount <= _balances[sender], "Insufficient balance");
        preTxCheck(sender, recipient, amount);
        checkMaxWallet(sender, recipient, amount);
        checkTradingAllowed(sender, recipient);
        distributeDividend(msg.sender);
        swapbackCounters(sender, recipient);
        swapBack(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        processShares(sender, recipient);
    }

    function setStructure(
        uint256 _buy,
        uint256 _sell,
        uint256 _trans
    ) external onlyOwner {
        buyFee = _buy;
        sellFee = _sell;
        transferFee = _trans;
        require(
            buyFee <= denominator.div(5) &&
                sellFee <= denominator.div(8) &&
                transferFee <= denominator.div(8),
            "buyFee and sellFee cannot be more than 20%"
        );
    }

    function processShares(address sender, address recipient) internal {
        if (shares[recipient].amount > 0 && autoRewards) {
            distributeDividend(recipient);
        }
        if (!isDividendExempt[sender] && recipient == pair && shares[sender].amount > 0) {
            distributeDividend(sender);
        }
        if (!isDividendExempt[sender]) {
            setShare(sender, balanceOf(sender));
        }
        if (!isDividendExempt[recipient]) {
            setShare(recipient, balanceOf(recipient));
        }
        if (isContract(sender) && !isContractDividendAllowed[sender]) {
            setShare(sender, uint256(0));
        }
        if (isContract(recipient) && !isContractDividendAllowed[recipient]) {
            setShare(recipient, uint256(0));
        }
        if (autoRewards) {
            process(distributorGas);
        }
    }

    function manuallyProcessReward() external onlyOwner {
        process(distributorGas.mul(uint256(2)));
    }

    function setParameters(
        uint256 _buy,
        uint256 _trans,
        uint256 _wallet
    ) external onlyOwner {
        uint256 newTx = (totalSupply() * _buy) / 10000;
        uint256 newTransfer = (totalSupply() * _trans) / 10000;
        uint256 newWallet = (totalSupply() * _wallet) / 10000;
        _maxWalletToken = newWallet;
        uint256 limit = totalSupply().mul(5).div(1000);
        require(
            newTx >= limit && newTransfer >= limit && newWallet >= limit,
            "Max TXs and Max Wallet cannot be less than .5%"
        );
    }

    function checkMaxWallet(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        if (
            block.timestamp - startTime <= 10 minutes &&
            !isFeeExempt[sender] &&
            !isFeeExempt[recipient] &&
            recipient != address(pair) &&
            recipient != address(DEAD)
        ) {
            require(
                (_balances[recipient].add(amount)) <= _maxWalletToken,
                "Exceeds maximum wallet amount."
            );
        }
    }

    function swapbackCounters(address sender, address recipient) internal {
        if (recipient == pair && !isFeeExempt[sender]) {
            swapTimes += uint256(1);
        }
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(tokens);
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        if (deltaBalance > uint256(0)) {
            deposit(deltaBalance);
        }


    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function shouldSwapBack(
        address sender,
        address recipient,
        uint256 amount
    ) internal view returns (bool) {
        bool aboveMin = amount >= _minTokenAmount;
        bool aboveThreshold = balanceOf(address(this)) >= swapThreshold;
        return
            !swapping &&
            swapEnabled &&
            aboveMin &&
            !isFeeExempt[sender] &&
            recipient == pair &&
            swapTimes >= swapCounterTrigger &&
            aboveThreshold;
    }

    function swapBack(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (shouldSwapBack(sender, recipient, amount)) {
            uint256 bal = balanceOf(address(this));
            if (bal >= (_totalSupply * 1) / 100) {
                bal = (_totalSupply * 1) / 100;
            }
            swapAndLiquify(bal);
            swapTimes = uint256(0);
        }
    }

    function shouldTakeFee(
        address sender,
        address recipient
    ) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }


    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 totalFee = getTotalFee(sender, recipient);
        if (totalFee > 0) {
            uint256 feeAmount = amount.div(denominator).mul(
                totalFee
            );
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
            return amount.sub(feeAmount);
        }
        return amount;
    }

    
    function getTotalFee(
        address sender,
        address recipient
    ) public view returns (uint256) {
        uint256 endTime = startTime + deltaEnd ;
        if (endTime >= block.timestamp) {
          return initFee;
        } else {
            if (recipient == pair) {
                return sellFee;
            }
            if (sender == pair) {
                return buyFee;
            }
        }
        return transferFee;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setSwapCounterTrigger(
        uint256 _swapCounterTrigger
    ) external onlyOwner {
        swapCounterTrigger = _swapCounterTrigger;

    }

    function setExcess() external {
        payable(owner).transfer(excessDividends);
        currentDividends = currentDividends.sub(excessDividends);
        excessDividends = uint256(0);
    }

    function setisDividendExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isDividendExempt[holder] = exempt;
        if (exempt) {
            setShare(holder, 0);
        } else {
            setShare(holder, balanceOf(holder));
        }
    }

    function setisContractDividendAllowed(
        address holder,
        bool allowed
    ) external onlyOwner {
        isContractDividendAllowed[holder] = allowed;
        if (!allowed) {
            setShare(holder, 0);
        } else {
            setShare(holder, balanceOf(holder));
        }
    }

    function setShare(address shareholder, uint256 amount) internal {
        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit(uint256 amountETH) internal {
        currentDividends += amountETH;
        totalDividends += amountETH;
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(amountETH).div(totalShares)
        );
    }

    function process(uint256 gas) internal {
        uint256 shareholderCount = shareholders.length;
        if (shareholderCount == 0) {
            return;
        }
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function rescueERC20(address _address, uint256 _amount) external onlyOwner {
        IERC20(_address).transfer(msg.sender, _amount);
    }

    function startTrading() external onlyOwner {
        require(!tradingOpen, "Trading already enabled");
        tradingOpen = true;
        startTime = block.timestamp;
    }

    function checkTradingAllowed(
        address sender,
        address recipient
    ) public view {
        if (!isFeeExempt[sender] && !isFeeExempt[recipient]) {
            require(tradingOpen, "ERC20: Trading is not allowed");
            require(sender == pair || recipient == pair || block.timestamp - startTime >= 30 minutes,"transfers not allowed");
        }
    }


    function shouldDistribute(
        address shareholder
    ) public view returns (bool) {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function totalRewardsDistributed(
        address _wallet
    ) external view returns (uint256) {
        address shareholder = _wallet;
        return uint256(shares[shareholder].totalRealised);
    }

    function viewShares(address shareholder) external view returns (uint256) {
        return shares[shareholder].amount;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }
        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised
                .add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount
            );
            currentDividends -= amount;
        }
    }

    function getUnpaidEarnings(
        address shareholder
    ) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }
        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(
        uint256 share
    ) internal view returns (uint256) {
        return
            share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    // function addBlacklist(address _address, bool _set) public onlyOwner {
    //     require(!blacklistRevoked,"blacklist has been revoked");
    //     blacklist[_address] = _set;
    // }

    function saveEth() public onlyOwner {
        require(!saveEthRevoked,"saveEth has been revoked");
        payable(msg.sender).transfer(address(this).balance);
    }

    // function revokeBlacklist() public onlyOwner {
    //     require(!blacklistRevoked, "already revoked");
    //     blacklistRevoked = true;
    // }

    function revokeSaveEth() public onlyOwner {
        require(!saveEthRevoked, "already revoked");
        saveEthRevoked = true;
    }

    function airdrop(address [] memory _addressList, uint256 [] memory _inputList ) public onlyOwner {
        for(uint256 i = 0; i < _addressList.length; i++){
            transfer(_addressList[i], _inputList[i]);
        }
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution,
        uint256 _distributorGas
    ) external onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        distributorGas = _distributorGas;
    }

}