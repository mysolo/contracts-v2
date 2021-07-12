import "contracts/interfaces/IMinter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterchefToken is IMinter, IERC20 {}
