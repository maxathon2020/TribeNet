pragma solidity 0.6.6;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ImmunityPassportContract is an example contract which requests data from
 * the Chainlink network
 * @dev This contract is designed to work on multiple networks, including
 * local test networks
 */
contract ImmunityPassportContract is ChainlinkClient, Ownable {
  uint256 public data;

  /**
   * @notice Deploy the contract with a specified address for the LINK
   * and Oracle contract addresses
   * @dev Sets the storage for the specified addresses
   * @param _link The address of the LINK token contract
   */
  constructor(address _link) public {
    if (_link == address(0)) {
      setPublicChainlinkToken();
    } else {
      setChainlinkToken(_link);
    }
  }

  /**
   * @notice Returns the address of the LINK token
   * @dev This is the public implementation for chainlinkTokenAddress, which is
   * an internal method of the ChainlinkClient contract
   */
  function getChainlinkToken() public view returns (address) {
    return chainlinkTokenAddress();
  }

  /**
   * @notice Creates a request to the specified Oracle contract address
   * @dev This function ignores the stored Oracle contract address and
   * will instead send the request to the address specified
   * @param _oracle The Oracle contract address to send the request to
   * @param _immunityPassportId The bytes32 _immunityPassportId to be executed
   * @param _url The URL to fetch data from
   * @param _path The dot-delimited path to parse of the response
   * @param _times The number to multiply the result by
   */
  function createRequestTo(
    address _oracle,
    bytes32 _immunityPassportId,
    uint256 _immunityReward,
    string memory _url,
    string memory _path,
    int256 _times
  )
    public
    onlyOwner
    returns (bytes32 requestId)
  {
    Chainlink.Request memory req = buildChainlinkRequest(_immunityPassportId, address(this), this.fulfill.selector);
    req.add("url", _url);
    req.add("path", _path);
    req.addInt("times", _times);
    requestId = sendChainlinkRequestTo(_oracle, req, _immunityReward);
  }

  /**
   * @notice The fulfill method from requests created by this contract
   * @dev The recordChainlinkFulfillment protects this function from being called
   * by anyone other than the oracle address that the request was sent to
   * @param _requestId The ID that was generated for the request
   * @param _data The answer provided by the oracle
   */
  function fulfill(bytes32 _requestId, uint256 _data)
    public
    recordChainlinkFulfillment(_requestId)
  {
    data = _data;
  }

  /**
   * @notice Allows the owner to withdraw any LINK balance on the contract
   */
  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }

  /**
   * @notice Call this method if no response is received within 5 minutes
   * @param _requestId The ID that was generated for the request to cancel
   * @param _immunityReward The ImmuntiyReward specified for the request to cancel
   * @param _callbackFunctionId The bytes4 callback function ID specified for
   * the request to cancel
   * @param _expiration The expiration generated for the request to cancel
   */
  function cancelRequest(
    bytes32 _requestId,
    uint256 _immunityReward,
    bytes4 _callbackFunctionId,
    uint256 _expiration
  )
    public
    onlyOwner
  {
    cancelChainlinkRequest(_requestId, _immunityReward, _callbackFunctionId, _expiration);
  }
}
